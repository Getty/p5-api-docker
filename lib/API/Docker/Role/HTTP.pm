package API::Docker::Role::HTTP;
# ABSTRACT: HTTP transport role for Docker Engine API
our $VERSION = '0.004';
use Moo::Role;
use IO::Socket::UNIX;
use IO::Socket::INET;
use JSON::MaybeXS qw( encode_json decode_json );
use Path::Tiny;
use Carp qw( croak shortmess );
use Log::Any qw( $log );
use API::Docker::Error::Stream;
use namespace::clean;

=head1 SYNOPSIS

    package MyDockerClient;
    use Moo;

    has host         => (is => 'ro', required => 1);
    has api_version  => (is => 'ro');
    has tls          => (is => 'ro', default => 0);
    has cert_path    => (is => 'ro');
    has tls_insecure => (is => 'ro', default => 0);

    with 'API::Docker::Role::HTTP';

    # Now use get, post, put, delete_request, head methods
    my $data = $self->get('/containers/json');

=head1 DESCRIPTION

This role provides HTTP transport for the Docker Engine API. It implements
HTTP/1.1 communication over Unix sockets and TCP sockets without depending on
heavy HTTP client libraries like LWP.

Features:

=over

=item * Unix socket transport (C<unix://...>)

=item * TCP socket transport (C<tcp://host:port>), in the clear or over TLS
with client certificates (L</"TLS on a tcp:// connection">)

=item * HTTP/1.1 chunked transfer encoding

=item * Automatic JSON encoding/decoding

=item * Newline-delimited JSON event streams (C<< ndjson => 1 >>), including
the failures the engine reports inside an HTTP 200 body

=item * Demultiplexing of the Docker stream format (L</stream_frames>)

=item * Incremental delivery of a response through a per-request callback, so
the endpoints that never close are usable at all (L</"Streaming a response as
it arrives">)

=item * Request/response logging via L<Log::Any>

=item * Automatic connection management

=back

Consuming classes must provide C<host>, C<api_version>, C<tls>, C<cert_path>
and C<tls_insecure> attributes. The last three are read only by the C<tcp://>
branch of the socket builder, and only when TLS is asked for, but the contract
is stated once rather than probed for at connect time.

A C<unix://> connection is a local socket with no wire to protect and is never
encrypted; it ignores all three attributes, and L<API::Docker> refuses the
combination at construction rather than letting a request for an encrypted
transport be answered with an unencrypted one. A C<tcp://> connection is
B<plaintext unless C<< tls => 1 >>>, which is the whole of the difference --
see L</"TLS on a tcp:// connection">.

=head2 TLS on a tcp:// connection

C<< tls => 1 >> replaces the L<IO::Socket::INET> connection with an
L<IO::Socket::SSL> one and changes nothing else: the same request writer, the
same reader, the same everything above the socket.

    my $docker = API::Docker->new(
      host      => 'tcp://dockerhost:2376',
      tls       => 1,
      cert_path => '/home/me/.docker',
    );

=head3 What the certificates are, and where

C<cert_path> names a directory in the layout the C<docker> CLI writes, and
each of the three files is used if it is there:

=over

=item * F<ca.pem> - the trust anchor the daemon's certificate is checked
against

=item * F<cert.pem> and F<key.pem> - this client's certificate and private
key, sent when the daemon asks the client to identify itself

=back

The two halves of the client certificate go together: one of them present
without the other is a croak, because a key with no certificate proves nothing
and a certificate with no key cannot be used. A directory holding only
F<ca.pem> is fine -- that is a daemon this client verifies but does not
authenticate to. A C<cert_path> that names nothing is a croak: it is read only
once TLS was asked for, and at that point a path pointing nowhere means the
caller believes certificates are in use that are not.

C<cert_path> defaults from C<DOCKER_CERT_PATH>, so on a machine that also runs
the C<docker> CLI it arrives set. Without C<< tls => 1 >> nothing reads it, so
that costs nothing; with it, pass C<< cert_path => undef >> to use the system
trust store instead of the CLI's private one.

=head3 TLS with no certificates at all

It means B<encrypt and verify against the system trust store>, not an error.

C<tls> asks for a connection that is encrypted and whose far end is
authenticated. It does not ask to authenticate this client, which is what the
files on disk are for, and treating the absence of a client certificate as a
missing precondition would conflate the two. The deployment with no
certificate files is real, and is the one this role's documentation used to
recommend before there was any TLS here: a terminator -- nginx, stunnel,
Traefik -- in front of the daemon, holding a publicly trusted certificate.
There is nothing for a C<cert_path> to point at in that setup.

It is also the safe reading rather than the lax one: verification stays on
either way, so the mode reached by configuring nothing is the verifying mode.
A stock C<dockerd --tlsverify> uses a private CA that the system store does
not have, and such a connection fails with a verification error naming exactly
that -- which is the intended outcome, not a silent downgrade. Point
C<cert_path> at the directory holding its F<ca.pem> and it verifies.

=head3 Turning verification off

C<< tls_insecure => 1 >>, and the name is the whole of the warning. It sets
C<SSL_VERIFY_NONE> and switches the hostname check off, which leaves a
connection that is encrypted against a passive listener and against nothing
else: whoever answers chooses the certificate, so anyone able to redirect the
connection reads and rewrites everything on it -- registry credentials,
image contents, the commands containers are started with.

It exists for a self-signed daemon certificate whose CA is genuinely not to
hand. The better answer to that is nearly always F<ca.pem>: a self-signed
certificate is its own CA and can be used as the anchor directly.

=head3 The dependency

L<IO::Socket::SSL> is a B<recommended>, not a required, dependency, and it is
loaded at the moment the first TLS connection is opened. It brings in
L<Net::SSLeay>, which is XS compiled against libssl, and the C<unix://>
transport -- local Docker, rootless Podman, the default -- never needs any of
it; requiring it would make this client unbuildable on a machine with no
OpenSSL headers for the sake of a transport it is not using. Without it,
C<< tls => 1 >> croaks naming the module and how to install it, at the same
point every other connection failure is reported.

=cut

requires 'host';
requires 'api_version';
requires 'tls';
requires 'cert_path';
requires 'tls_insecure';

# Docker stream frame types, indexed by the first byte of the frame header.
my @STREAM_TYPE = qw( stdin stdout stderr );

# A field name is an RFC 9110 token and nothing else. Anything outside this
# set -- CR, LF, a space, a colon -- is rejected rather than stripped; see
# _assert_header_name.
my $HEADER_NAME = qr/\A[0-9A-Za-z!#\$%&'*+.^_`|~-]+\z/;

# The three units a response can be cut into, one option each. A request picks
# one of them, or none and gets the buffered path; see _stream_handler.
my @STREAM_OPTION = qw( on_event on_frame on_chunk );

# What a response body has to start with to be worth handing to decode_json.
# An object or an array is not the whole of JSON: the engine answers several
# endpoints with a bare JSON scalar, and a `null` used to come back as the
# four-character string 'null'. See _request.
my $JSON_BODY = qr/\A\s*(?:[\[\{"]|-?[0-9]|true|false|null)/;

# How much of a body is asked for per read() on the incremental path. Only an
# upper bound: read() returns whatever has arrived, which on a live feed is
# usually one event.
my $READ_SIZE = 64 * 1024;

has _socket => (
  is      => 'lazy',
  clearer => '_clear_socket',
);

sub _build__socket {
  my ($self) = @_;
  my $host = $self->host;

  if ($host =~ m{^unix://(.+)$}) {
    my $path = $1;
    $log->debugf("Connecting to Unix socket: %s", $path);
    my $sock = IO::Socket::UNIX->new(
      Peer => $path,
      Type => SOCK_STREAM,
    );
    croak "Cannot connect to Unix socket $path: $!" unless $sock;
    return $sock;
  }
  elsif ($host =~ m{^tcp://([^:]+):(\d+)$}) {
    my ($addr, $port) = ($1, $2);

    unless ($self->tls) {
      $log->debugf("Connecting to TCP %s:%s", $addr, $port);
      my $sock = IO::Socket::INET->new(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto    => 'tcp',
      );
      croak "Cannot connect to $addr:$port: $!" unless $sock;
      return $sock;
    }

    # Built before the connection is opened: a cert_path that names nothing,
    # or half a client certificate, is a configuration mistake and the caller
    # should hear about it as one rather than as a handshake failure.
    my %ssl = $self->_ssl_options($addr);

    $log->debugf("Connecting to TCP %s:%s over TLS (verification %s)",
      $addr, $port, $self->tls_insecure ? 'off' : 'on');
    my $sock = IO::Socket::SSL->new(
      PeerAddr => $addr,
      PeerPort => $port,
      Proto    => 'tcp',
      %ssl,
    );
    unless ($sock) {
      # $SSL_ERROR carries the handshake failure -- an untrusted certificate,
      # a name that does not match -- and $! the plain connect failure. Both
      # are named because either can be the one that happened. The pragma is
      # for the package variable of a module that is not loaded at compile
      # time, which perl would otherwise report as a probable typo.
      no warnings 'once';
      croak 'Cannot connect to ' . $addr . ':' . $port . ' over TLS: '
        . ($IO::Socket::SSL::SSL_ERROR || $! || 'unknown error');
    }
    return $sock;
  }
  else {
    croak "Unsupported host format: $host (expected unix:// or tcp://)";
  }
}

# Loaded here rather than with the other modules at the top of the file.
# IO::Socket::SSL pulls in Net::SSLeay, which is XS compiled against libssl,
# and the unix:// transport -- local Docker, rootless Podman, the default and
# the only one most installations use -- never needs a byte of it. A hard
# dependency would make this client unbuildable on a machine with no OpenSSL
# headers for the sake of a transport it is not using, so it is a recommended
# one and this is the point where its absence becomes an error.
sub _load_ssl {
  my ($self) = @_;

  return 1 if eval { require IO::Socket::SSL; 1 };
  my $why = $@ || 'unknown error';
  $why =~ s/\s+\z//;
  croak __PACKAGE__ . ': tls => 1 needs IO::Socket::SSL, which failed to '
    . 'load (' . $why . '). It is a recommended rather than a required '
    . 'dependency because the unix:// transport never uses it -- install it '
    . 'with `cpanm IO::Socket::SSL` (or `cpanm --with-recommends '
    . 'API::Docker`)';
}

# The IO::Socket::SSL arguments for this client, as a plain hash, so the
# policy can be read off without opening a connection.
sub _ssl_options {
  my ($self, $addr) = @_;

  $self->_load_ssl;

  # SNI, sent whether or not the certificate is checked: a terminator serving
  # several names needs it to pick the right one, and that is true of an
  # unverified connection too.
  my %ssl = ( SSL_hostname => $addr );

  if ($self->tls_insecure) {
    # Everything below is off deliberately, and the attribute that got us here
    # says so in its name. Encryption without verification stops a passive
    # listener and nothing else: whoever answers the connection chooses the
    # certificate, so anyone able to redirect it reads and rewrites the
    # traffic -- credentials, image contents, container commands.
    $ssl{SSL_verify_mode}     = IO::Socket::SSL::SSL_VERIFY_NONE();
    $ssl{SSL_verifycn_scheme} = undef;
  }
  else {
    $ssl{SSL_verify_mode}     = IO::Socket::SSL::SSL_VERIFY_PEER();
    # The name is checked against the certificate as well as the chain: a
    # valid certificate for some other host is not this host.
    $ssl{SSL_verifycn_scheme} = 'http';
    $ssl{SSL_verifycn_name}   = $addr;
  }

  return (%ssl, $self->_ssl_certificates);
}

# cert.pem, key.pem and ca.pem in one directory -- the layout the docker CLI
# writes and the one cert_path has always pointed at, whether or not anything
# read it.
sub _ssl_certificates {
  my ($self) = @_;

  my $dir = $self->cert_path;
  return () unless defined $dir && length $dir;

  # cert_path defaults from DOCKER_CERT_PATH, so it can arrive from a machine's
  # environment rather than from this caller -- but it is only looked at once
  # TLS was asked for, and at that point a path naming nothing is a mistake
  # worth stopping on rather than quietly connecting without the certificates
  # the caller believes are in use.
  my $path = path($dir);
  croak __PACKAGE__ . ": cert_path $dir is not a directory. TLS expects the "
    . 'layout the docker CLI writes -- ca.pem, cert.pem and key.pem in one '
    . 'directory -- and this names nothing that could hold it'
    unless $path->is_dir;

  my %ssl;

  # No ca.pem is not an error: verifying a daemon behind a terminator with a
  # publicly trusted certificate needs no private trust anchor, and the
  # default store is then the right one. See L</"TLS on a tcp:// connection">.
  my $ca = $path->child('ca.pem');
  $ssl{SSL_ca_file} = "$ca" if $ca->exists;

  my $cert = $path->child('cert.pem');
  my $key  = $path->child('key.pem');
  my @half = grep { !$_->[1]->exists }
    ( [ 'cert.pem', $cert ], [ 'key.pem', $key ] );

  # One of the two is never a mode, only ever an accident: a key with no
  # certificate proves nothing and a certificate with no key cannot be used.
  croak __PACKAGE__ . ': cert_path ' . $dir . ' has ' . $half[0][0]
    . ' missing while the other half of the client certificate is there. '
    . 'Both cert.pem and key.pem are needed, or neither'
    if @half == 1;

  if (!@half) {
    $ssl{SSL_cert_file} = "$cert";
    $ssl{SSL_key_file}  = "$key";
  }

  return %ssl;
}

sub _reconnect {
  my ($self) = @_;
  $self->_clear_socket;
  return $self->_socket;
}

sub _request {
  my ($self, $method, $path, %opts) = @_;

  # Checked while the request is assembled, like a header name: a caller that
  # passes something else gets told before anything reaches the daemon,
  # instead of after the round trip when the metadata fails to arrive.
  croak __PACKAGE__ . '->_request response option must be a HashRef'
    if exists $opts{response} && ref $opts{response} ne 'HASH';

  # Checked here for the same reason, and one at a time: the three units are
  # three shapes the engine's streaming endpoints have, not three views of one
  # stream, so a request asking for two of them has no answer.
  my @streaming = grep { exists $opts{$_} } @STREAM_OPTION;
  croak __PACKAGE__ . '->_request takes one of ' . join(', ', @STREAM_OPTION)
    . ', not ' . join(' and ', @streaming) if @streaming > 1;
  croak __PACKAGE__ . '->_request ' . $streaming[0] . ' option must be a CodeRef'
    if @streaming && ref $opts{$streaming[0]} ne 'CODE';

  my $version = $self->api_version;
  my $url_path = defined $version ? "/v$version$path" : $path;

  # Kept before the query string is appended: it names the request in an
  # error message, and the query string is where /build carries buildargs,
  # which can hold credentials and have no business in an exception.
  my $endpoint = $method . ' ' . $url_path;

  # Definedness, not truth. A raw_body of '' (an empty tar) or of the string
  # '0' is a body the caller asked to send, and testing it for truth dropped
  # both: they fell through to the body branch, and the request then went out
  # with no Content-Length, no Content-Type and no payload at all. Whether
  # there is a body is therefore tracked separately from what it says.
  my $body_content;
  my $content_type = 'application/json';
  if (defined $opts{raw_body}) {
    $body_content = $opts{raw_body};
    $content_type = $opts{content_type} // 'application/x-tar';
  }
  elsif ($opts{body}) {
    $body_content = encode_json($opts{body});
  }

  if ($opts{params}) {
    my @pairs;
    for my $k (sort keys %{$opts{params}}) {
      my $v = $opts{params}{$k};
      next unless defined $v;
      # An ArrayRef is one parameter given more than once, not one value:
      # `names => ['a', 'b']` is `names=a&names=b`. That spelling is the only
      # one GET /images/get accepts -- the comma-joined form is read as a
      # single image reference and answered with 500 -- and Go's r.Form[k] is
      # a list for every parameter, so it is the general shape rather than
      # that endpoint's quirk. Element order is the caller's and is kept;
      # only the keys are sorted.
      for my $item (ref $v eq 'ARRAY' ? @$v : ($v)) {
        next unless defined $item;
        push @pairs, _uri_encode($k) . '='
          . _uri_encode(ref $item eq 'HASH' ? encode_json($item) : $item);
      }
    }
    $url_path .= '?' . join('&', @pairs) if @pairs;
  }

  $log->debugf("%s %s", $method, $url_path);

  my $request = "$method $url_path HTTP/1.1\r\n";
  $request .= "Host: localhost\r\n";
  $request .= "Connection: close\r\n";
  $request .= "User-Agent: API-Docker\r\n";

  if (defined $body_content) {
    $request .= "Content-Type: $content_type\r\n";
    $request .= "Content-Length: " . length($body_content) . "\r\n";
  }

  if ($opts{headers}) {
    for my $h (sort keys %{$opts{headers}}) {
      # The name is validated before the value is even looked at: a name that
      # cannot go on the wire is a caller bug whether or not the header ends
      # up being sent.
      $self->_assert_header_name($h);
      my $v = $opts{headers}{$h};
      next unless defined $v;
      $v =~ s/[\r\n]//g;
      $request .= "$h: $v\r\n";
    }
  }

  $request .= "\r\n";
  $request .= $body_content if defined $body_content;

  my $handler = @streaming
    ? $self->_stream_handler($endpoint, $streaming[0], $opts{$streaming[0]},
        $opts{croak_on_error} // 1)
    : undef;

  my $sock = $self->_reconnect;
  print $sock $request;

  # Reading can croak, and now does so from further in than it used to: an
  # on_event stream raises Error::Stream at the event that reports the
  # failure, and an on_frame stream refuses a header that is not one. Without
  # the eval those exceptions leave the socket open until the next request
  # replaces it, so it is closed on the way out either way and the exception
  # re-raised unchanged.
  my $response;
  my $ok  = eval { $response = $handler
    ? $self->_read_streaming_response($sock, $method, $handler)
    : $self->_read_response($sock, $method); 1 };
  my $err = $@;
  close $sock;
  $self->_clear_socket;
  die $err unless $ok;

  my ($status_code, $status_text, $headers, $body, $summary) = @$response;

  $log->debugf("Response: %s %s", $status_code, $status_text);

  # The status line and the response headers are metadata the return value
  # cannot carry: it is the decoded body and nothing else, so 204 and 304 are
  # both undef and a header holding the payload -- HEAD
  # /containers/{id}/archive answers with an empty body and
  # X-Docker-Container-Path-Stat -- is unreachable. They go into a hash the
  # caller supplies, so no existing caller's return shape changes. Filled
  # before the croak below, so an eval'ing caller can still read the status.
  if (my $out = $opts{response}) {
    %$out = (
      status  => $status_code,
      reason  => $status_text,
      headers => $headers,
    );
  }

  if ($status_code >= 400) {
    my $error_msg = $body;
    if ($body && $body =~ /^\s*[\{\[]/) {
      eval {
        my $data = decode_json($body);
        # Docker answers with {"message":...}. Podman answers a failed push
        # with the stream shape instead -- {"errorDetail":{"message":...},
        # "error":...} and no message key at all -- so without these two
        # fallbacks the whole JSON object became the croak text (karr #13).
        my $detail = ref $data->{errorDetail} eq 'HASH'
          ? $data->{errorDetail}{message} : undef;
        $error_msg = $data->{message} // $detail // $data->{error} // $body;
      };
    }
    croak "Docker API error ($status_code): $error_msg";
  }

  # A streamed request has handed every unit to the callback already and kept
  # none of them, so there is no body left to decode and return. What the
  # caller cannot know otherwise is how the stream ended, and that is what
  # comes back instead.
  return $summary if $summary;

  # Zero bytes is a different answer in each shape a request can ask for, so
  # the two options that promise one are answered before the empty-body check
  # rather than after it. `raw` promises the response bytes and a body of no
  # bytes is '', which a caller can take length() of; `ndjson` promises an
  # ArrayRef of events even for a stream carrying a single object, so a stream
  # that carried none is []. Returning undef for both broke each promise
  # exactly where the engine legitimately says nothing.
  $body = '' unless defined $body;

  # The framed endpoints (logs, attach, exec/start) carry arbitrary bytes
  # that must not be mistaken for JSON -- a TTY container printing a JSON
  # line would otherwise come back decoded.
  return $body if $opts{raw};

  # Streaming endpoints (/build, /images/create, /images/*/push) always
  # return an ArrayRef of events, even when the stream carried exactly one
  # object.  See _decode_stream.
  if ($opts{ndjson}) {
    my $events = $self->_decode_stream($body);
    # A failed build, pull or push is HTTP 200 with the failure buried in the
    # stream, so the status line above cannot catch it.  Opt out for a stream
    # whose objects are engine data rather than the outcome of one operation.
    $self->_assert_no_stream_error($endpoint, $events)
      if $opts{croak_on_error} // 1;
    return $events;
  }

  # Nothing was asked of the body's shape and there is no body, so there is
  # nothing to hand back. 204 says so in the status line and is taken at its
  # word even if bytes follow it.
  return undef if $status_code == 204 || $body eq '';

  # A body that is JSON is decoded, whichever JSON value it is. The guard was
  # `{` or `[` alone, which returned a body that is a bare JSON scalar as its
  # own bytes: `null` came back as the four-character string 'null'. The
  # engine sends exactly that where a Go nil slice or pointer is the whole
  # response -- GET /plugins/privileges for a plugin that demands nothing,
  # GET /containers/{id}/changes for a container that changed nothing -- and
  # the string is neither the ArrayRef those endpoints document nor anything
  # a caller can iterate.
  #
  # The eval decides, not the pattern: a plain-text body that happens to
  # start with one of these characters fails to decode and is returned as
  # itself. So must the eval's success, not its result -- decode_json('null')
  # is a successful decode to undef.
  if ($body =~ $JSON_BODY) {
    my $decoded;
    return $decoded if eval { $decoded = decode_json($body); 1 };
  }

  return $body;
}

sub _decode_stream {
  my ($self, $body) = @_;

  # Newline-delimited JSON: one object per line.  A literal newline cannot
  # occur inside a JSON string, so splitting on lines is safe.
  my @events;
  for my $line (split /\r?\n/, $body) {
    next unless $line =~ /\S/;
    my $event = eval { decode_json($line) };
    push @events, $event if defined $event;
  }

  # Fall back to the whole body for a stream that is not newline-framed
  # (a single pretty-printed object), so nothing is silently dropped.
  unless (@events) {
    my $event = eval { decode_json($body) };
    push @events, $event if defined $event;
  }

  return \@events;
}

sub _assert_no_stream_error {
  my ($self, $endpoint, $events) = @_;

  for my $event (@$events) {
    next unless ref $event eq 'HASH';
    my $detail = $event->{errorDetail};
    next unless defined $detail;

    # errorDetail is a HashRef carrying the message. The engine sends a flat
    # `error` next to it with the same text; that is the fallback, not the
    # trigger -- the trigger is errorDetail, and nothing else.
    my $reason = ref $detail eq 'HASH' ? $detail->{message} : undef;
    $reason = $event->{error}   unless defined $reason && length $reason;
    $reason = 'no message given' unless defined $reason && length $reason;
    # Engine messages end in a newline, and Carp appends no location to a
    # message that already does.
    $reason =~ s/\s+\z//;

    # Carp hands a reference straight back rather than decorating it, so this
    # croak is a die with an object -- hence the location captured by hand,
    # which names the same frame a croak of a plain string would have named.
    # The object goes into a variable first: `croak CLASS->new(...)` is
    # indirect object syntax and parses as CLASS->croak(new(...)).
    my $error = API::Docker::Error::Stream->new(
      message  => 'Docker API stream error (' . $endpoint . '): ' . $reason,
      events   => $events,
      location => shortmess(''),
    );
    croak $error;
  }

  return;
}

sub _assert_header_name {
  my ($self, $name) = @_;

  return if defined $name && $name =~ $HEADER_NAME;

  my $display = defined $name ? $name : '';
  $display =~ s/([^\x20-\x7E])/sprintf('\\x%02X', ord $1)/ge;
  croak __PACKAGE__ . '->_request invalid header name "' . $display . '": a '
    . 'header name must be an RFC 9110 token (letters, digits and '
    . '!#$%&\'*+-.^_`|~). A name is rejected rather than sanitised: unlike a '
    . 'value, there is no benign way for one to carry CR, LF, a space or a '
    . 'colon, and rewriting it would send a header the caller never wrote';
}

sub _read_response {
  my ($self, $sock, $method) = @_;

  my $head = $self->_read_head($sock);
  return [ @$head, $self->_read_body($sock, $head->[2], $method) ];
}

sub _read_head {
  my ($self, $sock) = @_;

  my $status_line = <$sock>;
  croak "No response from Docker daemon" unless defined $status_line;
  $status_line =~ s/\r?\n$//;

  my ($proto, $status_code, $status_text) = split /\s+/, $status_line, 3;

  my %headers;
  while (my $line = <$sock>) {
    $line =~ s/\r?\n$//;
    last if $line eq '';
    if ($line =~ /^([^:]+):\s*(.*)$/) {
      $headers{lc $1} = $2;
    }
  }

  return [$status_code, $status_text, \%headers];
}

sub _read_body {
  my ($self, $sock, $headers, $method) = @_;

  # A HEAD response repeats the header fields the equivalent GET would send --
  # Content-Length and Transfer-Encoding included -- and then sends no body at
  # all. Every branch below would wait for bytes that never arrive: until the
  # daemon closes the connection at best, and forever if it does not. So the
  # body is not read for HEAD, whatever the headers promise.
  return '' if defined $method && uc($method) eq 'HEAD';

  if ($headers->{'transfer-encoding'} && $headers->{'transfer-encoding'} eq 'chunked') {
    return $self->_read_chunked($sock);
  }

  if (defined $headers->{'content-length'}) {
    my $len = $headers->{'content-length'};
    return '' unless $len > 0;
    my $body = '';
    my $read = 0;
    while ($read < $len) {
      my $buf;
      my $n = read($sock, $buf, $len - $read);
      last unless $n;
      $body .= $buf;
      $read += $n;
    }
    return $body;
  }

  local $/;
  return <$sock> // '';
}

# The incremental sibling of _read_response. Same [status, reason, headers,
# body] shape, plus a fifth element: the summary of what the callback was
# handed. The body it returns is empty -- that is the point, nothing is kept --
# except on the two paths that fall back to reading whole, which return undef
# as the summary instead so _request treats them exactly as before.
sub _read_streaming_response {
  my ($self, $sock, $method, $handler) = @_;

  my ($status_code, $status_text, $headers) = @{ $self->_read_head($sock) };

  # Neither of these is a stream. A >= 400 body is a short JSON object naming
  # the failure and _request has to croak with it, so it is read whole and the
  # callback never sees it; a HEAD response has no body at all.
  if ($status_code >= 400 || (defined $method && uc($method) eq 'HEAD')) {
    return [$status_code, $status_text, $headers,
      $self->_read_body($sock, $headers, $method), undef];
  }

  my $feed = $handler->{feed};
  my $more = 1;

  if ($headers->{'transfer-encoding'} && $headers->{'transfer-encoding'} eq 'chunked') {
    while ($more) {
      my $chunk_header = <$sock>;
      last unless defined $chunk_header;
      $chunk_header =~ s/\r?\n$//;
      my $chunk_size = hex($chunk_header);
      last if $chunk_size == 0;

      my $read = 0;
      while ($read < $chunk_size) {
        my $buf;
        my $n = read($sock, $buf, $chunk_size - $read);
        last unless $n;
        $read += $n;
        # Fed per read() rather than per completed chunk. A chunk is the
        # daemon's framing, not the caller's -- the engine is free to send an
        # hour of log output as one chunk -- so waiting for the whole of one
        # would reintroduce exactly the buffering this path exists to avoid.
        $more = $feed->($buf);
        last unless $more;
      }
      last unless $more;

      # The CRLF that terminates the chunk data. Skipped when the caller
      # stopped mid-chunk: the socket is closed straight after, and the
      # remaining bytes of that chunk are still unread in front of it.
      <$sock>;
    }
  }
  elsif (defined $headers->{'content-length'}) {
    my $len  = $headers->{'content-length'};
    my $read = 0;
    while ($more && $read < $len) {
      my $want = $len - $read;
      $want = $READ_SIZE if $want > $READ_SIZE;
      my $buf;
      my $n = read($sock, $buf, $want);
      last unless $n;
      $read += $n;
      $more = $feed->($buf);
    }
  }
  else {
    while ($more) {
      my $buf;
      my $n = read($sock, $buf, $READ_SIZE);
      last unless $n;
      $more = $feed->($buf);
    }
  }

  # Only a stream the daemon ended has a tail worth flushing, or a leftover
  # worth complaining about. One the caller stopped has bytes in the carry
  # buffer by construction, and treating those as truncation would turn every
  # early stop into an error.
  $handler->{finish}->() unless $handler->{stopped}->();

  return [$status_code, $status_text, $headers, '', $handler->{summary}->()];
}

# One unit per call, and the unit is whichever of the three the caller asked
# for. The engine's streaming endpoints do not share one: /events and the
# build/pull/push progress streams are newline-delimited JSON, logs and
# exec/start are 8-byte-framed, and an image export is bytes with no structure
# above them at all. Forcing one unit on all three would mean handing two of
# them back undecoded and calling it streaming.
#
# The three decoders differ only in how they cut the byte stream up; the carry
# buffer, the delivery and the stop handling below are common to all of them.
sub _stream_handler {
  my ($self, $endpoint, $option, $cb, $croak_on_error) = @_;

  my $carry     = '';
  my $delivered = 0;
  my $stopped   = 0;

  # Stopping is an explicit call, not a return value, and the callback's
  # return value is deliberately never looked at. Every truthiness convention
  # has a silent failure mode here: `push @got, $_[0]` returns a count and
  # `$last = $event->{status}` returns whatever the engine said -- and a
  # container event's status is literally 'stop'. Both would end the stream by
  # accident and hand back a truncated one with no diagnostic. A closure the
  # caller has to invoke cannot be produced by accident.
  my $stop = sub { $stopped = 1; return };

  my $deliver = sub {
    my ($unit) = @_;
    $delivered++;
    $cb->($unit, $stop);
    return !$stopped;
  };

  my ($feed, $finish);

  if ($option eq 'on_chunk') {
    # No carry: the bytes as they arrive are the unit, so there is no boundary
    # to reassemble across.
    $feed = sub {
      my ($bytes) = @_;
      return 1 unless defined $bytes && length $bytes;
      return $deliver->($bytes);
    };
    $finish = sub { return };
  }
  elsif ($option eq 'on_event') {
    my $emit_line = sub {
      my ($line) = @_;
      $line =~ s/\r\z//;
      return 1 unless $line =~ /\S/;
      my $event = eval { decode_json($line) };
      return 1 unless defined $event;
      # Checked per event rather than over the finished list, so a failed
      # build croaks at the event that reports it instead of when the daemon
      # eventually closes. The Error::Stream then carries that one event: a
      # callback stream keeps no history, having been given all of it already.
      $self->_assert_no_stream_error($endpoint, [$event]) if $croak_on_error;
      return $deliver->($event);
    };
    $feed = sub {
      my ($bytes) = @_;
      $carry .= $bytes;
      # A JSON string cannot contain a literal newline, so a newline in the
      # buffer always ends an event -- and everything after the last one is
      # an event still arriving, which stays in the carry for the next read.
      while ((my $idx = index($carry, "\n")) >= 0) {
        my $line = substr($carry, 0, $idx, '');
        substr($carry, 0, 1, '');
        return 0 unless $emit_line->($line);
      }
      return 1;
    };
    $finish = sub {
      # A last event with no trailing newline is a complete event, not a
      # truncated one: the daemon closing is what ended it.
      return unless length $carry;
      my $line = $carry;
      $carry = '';
      $emit_line->($line);
      return;
    };
  }
  else {
    $feed = sub {
      my ($bytes) = @_;
      $carry .= $bytes;
      while (length($carry) >= 8) {
        my ($type, $pad1, $pad2, $pad3, $size) = unpack 'C4 N', substr($carry, 0, 8);
        croak __PACKAGE__ . '->_request on_frame: not a framed stream (header '
          . 'byte 0 is ' . $type . ', bytes 1-3 are ' . $pad1 . '/' . $pad2
          . '/' . $pad3 . '). A callback stream cannot sniff its own framing '
          . 'the way the buffered path does -- that needs the whole body, '
          . 'which is what is not being kept. Declare an unframed stream with '
          . 'tty => 1'
          if $type > $#STREAM_TYPE || $pad1 || $pad2 || $pad3;
        # The header is complete but the payload is not yet: leave the whole
        # frame in the carry and wait for the rest of it. This is the case a
        # per-chunk reader gets wrong -- an 8-byte header can be split across
        # two chunks just as easily as a payload can.
        last if length($carry) < 8 + $size;
        my $frame = {
          stream => $STREAM_TYPE[$type],
          data   => substr($carry, 8, $size),
        };
        substr($carry, 0, 8 + $size, '');
        return 0 unless $deliver->($frame);
      }
      return 1;
    };
    $finish = sub {
      return unless length $carry;
      croak __PACKAGE__ . '->_request on_frame: the daemon closed mid-frame, '
        . 'leaving ' . length($carry) . ' bytes that do not complete one';
    };
  }

  return {
    feed    => $feed,
    finish  => $finish,
    stopped => sub { $stopped },
    summary => sub { { delivered => $delivered, stopped => $stopped ? 1 : 0 } },
  };
}

sub _read_chunked {
  my ($self, $sock) = @_;
  my $body = '';

  while (1) {
    my $chunk_header = <$sock>;
    last unless defined $chunk_header;
    $chunk_header =~ s/\r?\n$//;
    my $chunk_size = hex($chunk_header);
    last if $chunk_size == 0;

    my $chunk = '';
    my $read = 0;
    while ($read < $chunk_size) {
      my $buf;
      my $n = read($sock, $buf, $chunk_size - $read);
      last unless $n;
      $chunk .= $buf;
      $read += $n;
    }
    $body .= $chunk;

    # Read trailing \r\n after chunk data
    <$sock>;
  }

  return $body;
}

sub _uri_encode {
  my ($str) = @_;
  $str =~ s/([^A-Za-z0-9\-_.~:\/])/sprintf("%%%02X", ord($1))/ge;
  return $str;
}

sub get {
  my ($self, $path, %opts) = @_;
  return $self->_request('GET', $path, %opts);
}

=method get

    my $data = $client->get($path, %opts);

Perform HTTP GET request. Returns decoded JSON or raw response body.

Options:

=over

=item * C<params> - HashRef of query parameters; a HashRef value is JSON-encoded

=item * C<headers> - HashRef of extra HTTP headers, e.g.
C<< { 'X-Registry-Auth' => $b64 } >>

=item * C<ndjson> - Parse the body as newline-delimited JSON and always
return an ArrayRef of events, even for a stream carrying a single object.
Named for the format rather than C<stream>, which is already a query
parameter of C</events> and C</containers/{id}/stats>. An C<errorDetail>
event in such a stream croaks; see L</"Failure inside a 200 response">

=item * C<croak_on_error> - Default true, and only consulted with
C<< ndjson => 1 >>. Set it false for a stream whose objects are engine data
rather than the outcome of one operation -- C</events> is the only such
endpoint here

=item * C<raw> - Never decode the body; return the response bytes verbatim

=item * C<response> - HashRef the status line and the response headers are
written into; see L</"Reading the status line and the response headers">

=item * C<on_event>, C<on_frame>, C<on_chunk> - CodeRef called with each unit
of the response as it arrives, instead of the body being buffered and
returned. At most one of the three; see L</"Streaming a response as it
arrives">

=item * C<headers> names are validated, not sanitised; see
L</"Header names are rejected, header values are stripped">

=back

=head2 Streaming a response as it arrives

Without one of these options a request is read whole, then parsed. That is
right for a request/response endpoint and wrong for every endpoint whose point
is that it keeps going: C<< logs(follow => 1) >>, C</events> with no C<until>
and C</containers/{id}/stats> with no C<< stream => 0 >> never return, because
the daemon never closes and there is nothing else to wait for.

Pass a callback and the body is handed over piece by piece instead:

    my $summary = $client->get('/events',
      croak_on_error => 0,
      on_event       => sub {
        my ($event, $stop) = @_;
        print $event->{status}, "\n";
        $stop->() if $event->{status} eq 'destroy';
      },
    );

    $summary;   # { delivered => 7, stopped => 1 }

=head3 One unit per call, and three units to choose from

The engine's streaming endpoints do not share a natural unit, so there is an
option per unit and a request picks one:

=over

=item * C<on_event> - one decoded HashRef per newline-delimited JSON object.
For C</events> and the C</build>, C</images/create>, C</images/*/push>
progress streams

=item * C<on_frame> - one C<< { stream => ..., data => ... } >> HashRef per
demultiplexed frame of the Docker stream format. For
C<< /containers/{id}/logs >> and C<< /exec/{id}/start >>; normally reached
through L</stream_frames> rather than directly

=item * C<on_chunk> - the response bytes as they arrive, undecoded and
unbuffered. For an image export, and for anything with no structure this role
knows about

=back

Passing two of them croaks before the request is sent: they are three shapes
different endpoints have, not three views of one stream.

=head3 Saying stop

The callback is called as C<< $cb->($unit, $stop) >> and its return value is
ignored. To end the stream it calls C<< $stop->() >>; C<_request> checks after
the callback returns, delivers nothing further, and comes back.

An explicit closure rather than a return value, because every truthiness
convention has a silent failure mode here. C<< sub { push @got, $_[0] } >>
returns a count and C<< sub { $last = $event->{status} } >> returns whatever
the engine said -- and a container event's C<status> is literally C<stop>.
Under either polarity one of those ends the stream by accident and hands back
a truncated one with nothing to show for it. A closure the caller has to
invoke cannot be produced by accident.

=head3 What comes back

A streamed request returns a summary HashRef, not the body:

    { delivered => 7, stopped => 1 }

C<delivered> is how many units went to the callback; C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated
along the way -- an unbounded feed must not cost memory in proportion to how
long it runs, and the caller has been handed every unit already. What it could
not otherwise know is how the stream ended, and that is what the summary says.

Only a complete unit is buffered while it is still arriving: the current
ndjson line or the current frame. A line, and equally an 8-byte frame header,
can be split across two chunks or two reads, so partial ones are carried
forward rather than decoded early.

=head3 What is not streamed

A response with status >= 400 is read whole and croaked with as always: it is
a short JSON object naming a failure, not a stream, and the callback never
sees it. C<response> is still filled. A C<HEAD> response has no body, so a
callback on one is never called and C<undef> comes back as usual.

With C<on_event>, C<croak_on_error> works as it does for C<ndjson> -- except
that the check runs per event, so a failed build croaks at the event that
reports it instead of when the daemon eventually closes. The
L<API::Docker::Error::Stream> then carries that one event in C<< ->events >>
rather than the whole stream: the callback was handed the rest as it arrived,
and none of it was kept.

C<on_frame> requires the stream to be framed. The buffered path decides
framing by walking the whole body (see L</"Detecting a framed stream">), which
is exactly what a streamed one does not have, so an unframed stream has to
declare itself with C<< tty => 1 >> to L</stream_frames> and an undeclared one
that turns out not to be framed croaks. A stream the daemon cuts off mid-frame
croaks too -- there is no whole body left to fall back to raw with. Neither
applies after a C<< $stop->() >>, which leaves a partial unit in the buffer by
construction.

=head2 Reading the status line and the response headers

The return value is the decoded body and nothing else, which leaves two things
the engine said unreachable: the status code, and the response headers. Pass a
HashRef as C<response> to get them:

    my %res;
    my $data = $client->post("/containers/$id/start", undef,
      response => \%res);

    $res{status};             # 204
    $res{reason};             # 'No Content'
    $res{headers}{'api-version'};   # header names are lowercased

The hash is overwritten on every call and filled B<before> the C<< >= 400 >>
croak, so a caller that wraps the request in C<eval> can still read the status
of a failed one. The return value is unaffected, so passing C<response> never
changes what a method hands back.

Two things need it. The engine answers a state change that did nothing with
B<304 Not Modified> -- starting a running container, stopping a stopped one --
which carries no body, exactly like the 204 of a change that did happen; see
L<API::Docker::API::Containers/start>. And C<< HEAD /containers/{id}/archive >>
carries its whole payload in the C<X-Docker-Container-Path-Stat> header, with
no body to return at all.

=head2 Failure inside a 200 response

C</build>, C</images/create> (pull) and C</images/{name}/push> report a failed
operation as an C<errorDetail> object B<inside> a stream the daemon already
answered with HTTP 200. The status line is committed before the operation is
attempted, so the C<< >= 400 >> check above cannot see it, and a client that
trusts the status hands a broken build back as a success.

So an C<< ndjson => 1 >> request scans the decoded events and croaks with an
L<API::Docker::Error::Stream> the moment one carries C<errorDetail>. That
object stringifies to the reason plus Carp's usual location suffix, so
C<eval>-and-inspect-C<$@> code cannot tell it from the plain croak it
replaces; C<< $err->events >> carries the complete event list, so the progress
output that led up to the failure is not lost with the return value.

The trigger is the C<errorDetail> key alone. The flat C<error> key the engine
sends beside it holds the same text and is used only as a fallback message,
never as the trigger on its own.

C<< croak_on_error => 0 >> turns the scan off for a stream that is a feed
rather than an operation. The check is on by default, and opting out is per
endpoint, because the set of operation-shaped streaming endpoints is
open-ended while the feed-shaped ones are C</events> and nothing else: a new
endpoint added without a thought about this gets the loud behaviour, not the
silent one.

=head2 Header names are rejected, header values are stripped

A CR or LF in a header B<value> is stripped and the value is flattened onto
its own line. A header B<name> that is not an RFC 9110 token is refused with
a croak instead.

The asymmetry is deliberate. A value can pick up a stray newline honestly --
C<MIME::Base64::encode_base64> wraps its output by default, and a token pasted
out of a file brings its line ending along -- and flattening it preserves what
the caller meant. A name is a literal the programmer wrote; there is no benign
way for one to contain CR, LF, a space or a colon, and quietly rewriting
C<< "X-Foo\r\nX-Bar" >> into C<X-FooX-Bar> would put a header on the wire
under a name nobody asked for. Validating against the token grammar also
catches the separators that would corrupt the request without injecting
anything.

=cut

sub post {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('POST', $path, %opts);
}

=method post

    my $data = $client->post($path, $body, %opts);

Perform HTTP POST request. C<$body> is automatically JSON-encoded if provided.

Options: C<params>, C<headers>, C<ndjson>, C<croak_on_error>, C<raw>,
C<response> and the C<on_event>/C<on_frame>/C<on_chunk> callbacks as for
L</get>, plus C<raw_body> and C<content_type> for sending a non-JSON payload
such as a build context tarball.

=cut

sub put {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('PUT', $path, %opts);
}

=method put

    my $data = $client->put($path, $body, %opts);

Perform HTTP PUT request. C<$body> is automatically JSON-encoded if provided.

Options: C<params>, C<headers>, C<ndjson>, C<croak_on_error>, C<raw>,
C<response> and the C<on_event>/C<on_frame>/C<on_chunk> callbacks as for
L</get>, plus C<raw_body> and C<content_type> for sending a non-JSON payload
-- C<< containers->put_archive >> uses both to send a tar stream.

=cut

sub delete_request {
  my ($self, $path, %opts) = @_;
  return $self->_request('DELETE', $path, %opts);
}

=method delete_request

    my $data = $client->delete_request($path, %opts);

Perform HTTP DELETE request.

Options: C<params> (hashref of query parameters).

=cut

sub head {
  my ($self, $path, %opts) = @_;
  return $self->_request('HEAD', $path, %opts);
}

=method head

    my %res;
    $client->head("/containers/$id/archive",
      params   => { path => '/etc/hostname' },
      response => \%res,
    );
    my $stat = decode_json(decode_base64($res{headers}{'x-docker-container-path-stat'}));

Perform HTTP HEAD request. Always returns C<undef>: a HEAD response has no
body by definition, so everything it says is in the status line and the
headers, and C<response> is the only way to reach them.

The body is not read even when the response announces one. A HEAD response
repeats the header fields the equivalent GET would send, C<Content-Length>
among them, and then sends nothing -- reading it would block on bytes that
never arrive. Measured against Podman 5.4.2 (API 1.41),
C<< HEAD /containers/{id}/archive >> in fact announces no length at all, only
C<X-Docker-Container-Path-Stat> -- but an engine that does announce one is not
waited on either.

Options: C<params>, C<headers> and C<response> as for L</get>.

=cut

sub stream_frames {
  my ($self, $method, $path, %opts) = @_;

  my $tty = delete $opts{tty};

  if (my $cb = delete $opts{on_frame}) {
    # tty is a declaration here, not the hint it is on the buffered path. The
    # sniff below needs the whole body to decide, and the whole body is what a
    # callback stream does not have; so an unframed stream has to say so, and
    # anything not declared is required to be framed.
    return $self->_request($method, $path, %opts,
      $tty
        ? ( on_chunk => sub { $cb->({ stream => 'raw', data => $_[0] }, $_[1]) } )
        : ( on_frame => $cb ),
    );
  }

  my $body = $self->_request($method, $path, %opts, raw => 1);

  return [] unless defined $body && length $body;

  my $frames = $tty ? undef : $self->_demux_frames($body);

  return $frames if $frames;
  return [ { stream => 'raw', data => $body } ];
}

=method stream_frames

    my $frames = $client->stream_frames('GET', "/containers/$id/logs", %opts);

Perform a request against one of the engine's framed endpoints
(C<< /containers/{id}/logs >>, C<< /exec/{id}/start >>) and return an ArrayRef
of frames:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

C<stream> is C<stdout>, C<stderr> or C<stdin> for a multiplexed stream, and
C<raw> for an unframed one. It is always a plain string, so callers never need
a defined-check. Joining the payloads gives the plain text:

    my $text = join '', map { $_->{data} } @$frames;

The response body is never JSON-decoded, so a container printing JSON lines is
returned verbatim.

Options are those of C<_request> (C<params>, C<body>, C<headers>), plus:

=over

=item * C<tty> - Skip demultiplexing and return the body as a single C<raw>
frame. Set it when the container or exec instance was created with a TTY and
its output is binary; see L</"Detecting a framed stream"> for why.

=item * C<on_frame> - CodeRef called with each frame as it arrives instead of
the whole ArrayRef being returned at the end; see below.

=back

=head2 Following a framed stream

With C<on_frame> the frames are handed over as they arrive and the return
value is the summary HashRef described in L</"Streaming a response as it
arrives">, not an ArrayRef:

    my $summary = $client->stream_frames('GET', "/containers/$id/logs",
      params   => { follow => 1, stdout => 1, stderr => 1 },
      on_frame => sub {
        my ($frame, $stop) = @_;
        print $frame->{data};
        $stop->() if $frame->{data} =~ /listening on/;
      },
    );

This is the only way to use C<< follow => 1 >> at all: without it the request
does not return until the container exits.

The frame shape is the same either way, C<tty> included -- a TTY stream
arrives as a series of C<< { stream => 'raw', ... } >> frames rather than the
single one the buffered path builds, so a caller still never branches on it.

C<tty> is a declaration here rather than the hint it is on the buffered path.
Deciding framing from the bytes needs the whole body, which is precisely what
is not being kept; so an unframed stream must say so, and one that does not
and is not framed croaks instead of inventing frames from its payload.

=head2 Detecting a framed stream

A container created without a TTY produces the Docker stream format -- an
8-byte header per frame (byte 0 the stream type, bytes 4-7 a big-endian uint32
payload length) followed by that many payload bytes. With a TTY there is no
header and the payload is raw pty output.

The engine is supposed to distinguish the two with the response C<Content-Type>
(C<application/vnd.docker.multiplexed-stream> against
C<application/vnd.docker.raw-stream>), but that signal is not dependable.
Measured against Podman 5.4.2 (API 1.41): C<< GET /containers/{id}/logs >>
sends no C<Content-Type> at all, for either kind of container, and
C<< POST /exec/{id}/start >> sends C<application/vnd.docker.raw-stream> for
both -- including the non-TTY exec whose body is in fact multiplexed. Trusting
the header would therefore hand frame headers to the caller on that engine.

The framing is decided from the bytes instead. The body is walked as frames:
each header must have a stream type of 0, 1 or 2, three zero bytes after it,
and a payload length that leaves at least that many bytes in the buffer. The
body is treated as framed only when the walk consumes it exactly and yields at
least one frame; anything else is returned as a single C<raw> frame.

This can be fooled in one direction only. Raw TTY output is misread as framed
if it begins with a byte no greater than C<0x02>, followed by three NUL bytes
and a length that happens to chain exactly to the end of the body. Text output
cannot do that -- a printable character is C<0x20> or above -- so it takes
binary output from a TTY-allocated container. Pass C<< tty => 1 >> for that
case. The reverse mistake cannot happen silently: a genuine frame stream is
only ever reported as raw when its final frame is truncated, which needs the
daemon to close the connection mid-frame.

=cut

sub _demux_frames {
  my ($self, $body) = @_;

  my $len = length $body;
  my $pos = 0;
  my @frames;

  while ($pos < $len) {
    return undef if $len - $pos < 8;
    my ($type, $pad1, $pad2, $pad3, $size) = unpack 'C4 N', substr($body, $pos, 8);
    return undef if $type > $#STREAM_TYPE;
    return undef if $pad1 || $pad2 || $pad3;
    return undef if $len - $pos - 8 < $size;
    push @frames, {
      stream => $STREAM_TYPE[$type],
      data   => substr($body, $pos + 8, $size),
    };
    $pos += 8 + $size;
  }

  return undef unless @frames;
  return \@frames;
}

=seealso

=over

=item * L<API::Docker> - Main client using this role

=item * L<API::Docker::Error::Stream> - Raised for a failure reported inside
a 200 event stream

=back

=cut

1;
