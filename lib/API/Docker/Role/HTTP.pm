package API::Docker::Role::HTTP;
# ABSTRACT: HTTP transport role for Docker Engine API
our $VERSION = '0.003';
use Moo::Role;
use IO::Socket::UNIX;
use IO::Socket::INET;
use JSON::MaybeXS qw( encode_json decode_json );
use Carp qw( croak );
use Log::Any qw( $log );
use namespace::clean;

=head1 SYNOPSIS

    package MyDockerClient;
    use Moo;

    has host => (is => 'ro', required => 1);
    has api_version => (is => 'ro');

    with 'API::Docker::Role::HTTP';

    # Now use get, post, put, delete_request methods
    my $data = $self->get('/containers/json');

=head1 DESCRIPTION

This role provides HTTP transport for the Docker Engine API. It implements
HTTP/1.1 communication over Unix sockets and TCP sockets without depending on
heavy HTTP client libraries like LWP.

Features:

=over

=item * Unix socket transport (C<unix://...>)

=item * TCP socket transport (C<tcp://host:port>)

=item * HTTP/1.1 chunked transfer encoding

=item * Automatic JSON encoding/decoding

=item * Newline-delimited JSON event streams (C<< ndjson => 1 >>)

=item * Demultiplexing of the Docker stream format (L</stream_frames>)

=item * Request/response logging via L<Log::Any>

=item * Automatic connection management

=back

Consuming classes must provide C<host> and C<api_version> attributes.

=cut

requires 'host';
requires 'api_version';

# Docker stream frame types, indexed by the first byte of the frame header.
my @STREAM_TYPE = qw( stdin stdout stderr );

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
    $log->debugf("Connecting to TCP %s:%s", $addr, $port);
    my $sock = IO::Socket::INET->new(
      PeerAddr => $addr,
      PeerPort => $port,
      Proto    => 'tcp',
    );
    croak "Cannot connect to $addr:$port: $!" unless $sock;
    return $sock;
  }
  else {
    croak "Unsupported host format: $host (expected unix:// or tcp://)";
  }
}

sub _reconnect {
  my ($self) = @_;
  $self->_clear_socket;
  return $self->_socket;
}

sub _request {
  my ($self, $method, $path, %opts) = @_;

  my $version = $self->api_version;
  my $url_path = defined $version ? "/v$version$path" : $path;

  my $body_content = '';
  my $content_type = 'application/json';
  if ($opts{raw_body}) {
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
      if (ref $v eq 'HASH') {
        $v = encode_json($v);
      }
      push @pairs, _uri_encode($k) . '=' . _uri_encode($v);
    }
    $url_path .= '?' . join('&', @pairs) if @pairs;
  }

  $log->debugf("%s %s", $method, $url_path);

  my $request = "$method $url_path HTTP/1.1\r\n";
  $request .= "Host: localhost\r\n";
  $request .= "Connection: close\r\n";
  $request .= "User-Agent: API-Docker\r\n";

  if ($body_content) {
    $request .= "Content-Type: $content_type\r\n";
    $request .= "Content-Length: " . length($body_content) . "\r\n";
  }

  if ($opts{headers}) {
    for my $h (sort keys %{$opts{headers}}) {
      my $v = $opts{headers}{$h};
      next unless defined $v;
      $v =~ s/[\r\n]//g;
      $request .= "$h: $v\r\n";
    }
  }

  $request .= "\r\n";
  $request .= $body_content if $body_content;

  my $sock = $self->_reconnect;
  print $sock $request;

  my $response = $self->_read_response($sock);
  close $sock;
  $self->_clear_socket;

  my ($status_code, $status_text, $headers, $body) = @$response;

  $log->debugf("Response: %s %s", $status_code, $status_text);

  if ($status_code >= 400) {
    my $error_msg = $body;
    if ($body && $body =~ /^\s*[\{\[]/) {
      eval {
        my $data = decode_json($body);
        $error_msg = $data->{message} // $body;
      };
    }
    croak "Docker API error ($status_code): $error_msg";
  }

  if ($status_code == 204 || !defined($body) || $body eq '') {
    return undef;
  }

  # The framed endpoints (logs, attach, exec/start) carry arbitrary bytes
  # that must not be mistaken for JSON -- a TTY container printing a JSON
  # line would otherwise come back decoded.
  return $body if $opts{raw};

  # Streaming endpoints (/build, /images/create, /images/*/push) always
  # return an ArrayRef of events, even when the stream carried exactly one
  # object.  See _decode_stream.
  return $self->_decode_stream($body) if $opts{ndjson};

  if ($body =~ /^\s*[\{\[]/) {
    my $result = eval { decode_json($body) };
    return $result if defined $result;
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

sub _read_response {
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

  my $body = '';
  if ($headers{'transfer-encoding'} && $headers{'transfer-encoding'} eq 'chunked') {
    $body = $self->_read_chunked($sock);
  }
  elsif (defined $headers{'content-length'}) {
    my $len = $headers{'content-length'};
    if ($len > 0) {
      my $read = 0;
      while ($read < $len) {
        my $buf;
        my $n = read($sock, $buf, $len - $read);
        last unless $n;
        $body .= $buf;
        $read += $n;
      }
    }
  }
  else {
    local $/;
    $body = <$sock> // '';
  }

  return [$status_code, $status_text, \%headers, $body];
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
parameter of C</events> and C</containers/{id}/stats>

=item * C<raw> - Never decode the body; return the response bytes verbatim

=back

=cut

sub post {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('POST', $path, %opts);
}

=method post

    my $data = $client->post($path, $body, %opts);

Perform HTTP POST request. C<$body> is automatically JSON-encoded if provided.

Options: C<params>, C<headers>, C<ndjson> and C<raw> as for L</get>, plus
C<raw_body> and C<content_type> for sending a non-JSON payload such as a build
context tarball.

=cut

sub put {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('PUT', $path, %opts);
}

=method put

    my $data = $client->put($path, $body, %opts);

Perform HTTP PUT request. C<$body> is automatically JSON-encoded if provided.

Options: C<params> (hashref of query parameters).

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

sub stream_frames {
  my ($self, $method, $path, %opts) = @_;

  my $tty = delete $opts{tty};
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

=back

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

=back

=cut

1;
