use strict;
use warnings;
use Test::More;
use Socket;
use API::Docker;
use API::Docker::Error::Truncated;

# A daemon that hangs up in the middle of a response (karr #64).
#
# The readers used to end their loops on "the stream is over" and hand back
# what they had as though the response were complete. Nothing compared the
# body against what the response had announced, so all four shapes below came
# back as ordinary values -- and a short body satisfies every return shape
# this role promises: ndjson gives a shorter ArrayRef, raw gives fewer bytes,
# the default gives whatever the truncated bytes parse as. A half tarball that
# looks whole is the case this file exists for.
#
# Every scenario here runs over a real AF_UNIX socketpair whose peer writes
# the bytes and then shuts its writing end down. No daemon, no network, no
# timeout: the close is the only event, which is what makes this a test of the
# structural check rather than of the read timeout next door in
# t/read_timeout.t. Nothing waits, so the whole file runs in milliseconds.
#
# What is deliberately NOT truncation is asserted just as hard, at the bottom:
# a body delimited by nothing but the close announces no end, so there an EOF
# is the end. Getting that wrong would break attach, logs(follow) and
# exec/start, which is every raw-stream endpoint there is.

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

# The peer writes and then half-closes: we see the end of the response, and a
# request written afterwards still lands rather than raising SIGPIPE. Both
# ends are handed back so the caller can close them when it is done.
sub pair_with {
  my ($bytes) = @_;
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";
  syswrite $theirs, $bytes;
  shutdown $theirs, 1;
  return ($ours, $theirs);
}

# Drive a reader over such a pair and report which of the two happened.
sub over_pair {
  my ($bytes, $drive) = @_;
  my ($ours, $theirs) = pair_with($bytes);
  my @out = eval { $drive->($ours) };
  my $err = $@;
  close $ours;
  close $theirs;
  return ($err, \@out);
}

# A handle that hands over at most $step bytes per sysread, for the two
# assertions a socketpair cannot make. Everything written to a socketpair
# before it is read is already in the kernel's buffer, so one sysread takes
# the lot and a chunk is always complete by the time the callback sees any of
# it -- which is exactly the state the `stopped` guard is about not being in.
{
  package Test::Truncated::Stepped;

  sub TIEHANDLE {
    my ($class, $data, $step) = @_;
    return bless { data => $data, pos => 0, step => $step }, $class;
  }

  sub READ {
    my $self = $_[0];
    my $left = length($self->{data}) - $self->{pos};
    return 0 unless $left;
    my $n = $self->{step} < $left ? $self->{step} : $left;
    $n = $_[2] if defined $_[2] && $_[2] < $n;
    $_[1] = substr($self->{data}, $self->{pos}, $n);
    $self->{pos} += $n;
    return $n;
  }

  sub CLOSE { 1 }
}

sub stepped {
  my ($data, $step) = @_;
  no warnings 'once';
  my $glob = \do { local *HANDLE };
  tie *$glob, 'Test::Truncated::Stepped', $data, $step;
  return $glob;
}

sub truncated_ok {
  my ($err, %want) = @_;

  isa_ok $err, 'API::Docker::Error::Truncated' or return;
  is $err->phase, $want{phase}, 'phase: ' . $want{phase};
  is $err->partial, $want{partial}, 'the bytes that did arrive';
  is $err->expected, $want{expected}, 'the count the response announced';
  is $err->received, $want{received}, 'and how many of them came';
  like "$err", $want{message}, 'the message says what was cut short';
  return;
}

# ---------------------------------------------------------------------------
# The four shapes, measured exactly as karr #64 measured them
# ---------------------------------------------------------------------------
subtest 'Content-Length announces 11, 9 bytes arrive' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\nhello wor",
    sub { $client->_read_response($_[0], 'GET', {}) });

  truncated_ok $err,
    phase   => 'content-length',
    partial => 'hello wor',
    expected => 11,
    received => 9,
    message  => qr/the body stopped 2 bytes short of the 11 it announced; 9 bytes arrived/;
};

subtest 'a chunk announces 11 (b), 5 bytes arrive' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nb\r\nhello",
    sub { $client->_read_response($_[0], 'GET', {}) });

  truncated_ok $err,
    phase    => 'chunk-data',
    partial  => 'hello',
    expected => 11,
    received => 5,
    message  => qr/a chunk stopped 6 bytes short of the 11 it announced/;
};

subtest 'a complete chunk with no terminating zero chunk' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n",
    sub { $client->_read_response($_[0], 'GET', {}) });

  truncated_ok $err,
    phase    => 'chunk-header',
    partial  => 'hello',
    expected => undef,
    received => undef,
    message  => qr/no terminating zero chunk/;
};

subtest 'a chunk header cut in half' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n1",
    sub { $client->_read_response($_[0], 'GET', {}) });

  truncated_ok $err,
    phase    => 'chunk-header',
    partial  => 'hello',
    expected => undef,
    received => undef,
    message  => qr/inside a chunk header, after 1 byte of one/;
};

subtest 'a chunk whose data arrived but whose CRLF did not' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello",
    sub { $client->_read_response($_[0], 'GET', {}) });

  truncated_ok $err,
    phase    => 'chunk-terminator',
    partial  => 'hello',
    expected => undef,
    received => undef,
    message  => qr/before the CRLF that terminates a chunk/;
};

# ---------------------------------------------------------------------------
# End to end through _request, which is where the return shapes are
# ---------------------------------------------------------------------------
{
  package Test::Truncated::Client;
  use Moo;
  extends 'API::Docker';

  # The real _request against a real socket whose peer has already written the
  # whole (short) response and half-closed. Nothing here waits.
  has canned => (is => 'rw', default => sub { '' });
  has peer   => (is => 'rw');

  sub _build__socket {
    my ($self) = @_;
    socketpair(my $ours, my $theirs, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
      Socket::PF_UNSPEC()) or die "socketpair: $!";
    syswrite $theirs, $self->canned;
    shutdown $theirs, 1;
    $self->peer($theirs);
    return $ours;
  }
}

sub client_for {
  my ($canned) = @_;
  return Test::Truncated::Client->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => $canned,
  );
}

sub sized {
  my ($body, %args) = @_;
  my $len = exists $args{announce} ? $args{announce} : length $body;
  return 'HTTP/1.1 ' . ($args{status} // '200 OK') . "\r\n"
    . 'Content-Type: ' . ($args{type} // 'application/json') . "\r\n"
    . 'Content-Length: ' . $len . "\r\n\r\n" . $body;
}

# The case the ticket calls the worst of them: raw promises the response bytes
# and a caller has no way to tell 700 of them from 2048.
subtest 'raw: half a tar is not a tar' => sub {
  my $tar = join('', map { chr($_ % 256) } 1 .. 2048);
  my $c = client_for(sized(substr($tar, 0, 700), announce => 2048,
    type => 'application/x-tar'));

  my $got = eval { $c->get('/images/get', raw => 1) };
  my $err = $@;
  close $c->peer;

  is $got, undef, 'nothing came back';
  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->endpoint, 'GET /v1.41/images/get',
    'the request is named, without a query string';
  is $err && $err->expected, 2048, 'the length the daemon announced';
  is $err && $err->received, 700, 'and what arrived';
  is $err && length($err->partial), 700,
    'the bytes are on the exception rather than returned as a whole tar';
  is $err && $err->partial, substr($tar, 0, 700), 'and they are the ones sent';
};

subtest 'ndjson: a short event stream is not a short list of events' => sub {
  my $body = qq({"status":"one"}\n{"status":"two"}\n{"status":"thr);
  my $c = client_for(sized($body, announce => length($body) + 20));

  my $got = eval { $c->get('/images/create', ndjson => 1) };
  my $err = $@;
  close $c->peer;

  is $got, undef, 'no ArrayRef came back';
  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->phase, 'content-length', 'the body fell short';
  like $err && "$err", qr/20 bytes short/, 'by the missing 20';
};

subtest 'the default path: a body that still parses as JSON' => sub {
  # The nastiest of the buffered cases, and the reason the check cannot be
  # "did it decode?": these bytes are valid JSON on their own, so a truncation
  # check that only asked whether the body parsed would pass this through as
  # a two-key object.
  my $whole = '{"Id":"abc","State":"running"} plus 20 more bytes';
  my $c = client_for(sized(substr($whole, 0, 29), announce => length $whole));

  my $got = eval { $c->get('/containers/abc/json') };
  my $err = $@;
  close $c->peer;

  is $got, undef, 'the JSON that parses is not handed back';
  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->received, 29, 'the bytes that arrived are counted';
};

subtest 'a complete response is unaffected' => sub {
  my $c = client_for(sized('{"Id":"abc"}'));
  my $got = eval { $c->get('/containers/abc/json') };
  is $@, '', 'nothing raised' or diag "raised: $@";
  is_deeply $got, { Id => 'abc' }, 'and the body comes back decoded';
  close $c->peer;
};

subtest 'a complete chunked response is unaffected' => sub {
  my $c = client_for("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
    . "6\r\n{\"Id\":\r\n" . "7\r\n\"abc\"}\r\n" . "0\r\n\r\n");
  my $got = eval { $c->get('/containers/abc/json') };
  is $@, '', 'nothing raised' or diag "raised: $@";
  is_deeply $got, { Id => 'abc' }, 'the chunks are reassembled and decoded';
  close $c->peer;
};

subtest 'a 204 and a zero-length body are not truncation' => sub {
  my $c = client_for("HTTP/1.1 204 No Content\r\n\r\n");
  my $got = eval { $c->post('/containers/abc/start') };
  is $@, '', '204 with no headers at all' or diag "raised: $@";
  is $got, undef, 'and undef comes back';
  close $c->peer;

  my $z = client_for("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
  my $zgot = eval { $z->get('/probe', raw => 1) };
  is $@, '', 'Content-Length: 0 with nothing after it'
    or diag "raised: $@";
  is $zgot, '', 'and the empty body comes back as the empty string';
  close $z->peer;
};

subtest 'HEAD is not truncation, whatever its Content-Length says' => sub {
  # A HEAD response repeats the headers the equivalent GET would send and
  # sends no body. Reading one is not attempted, so there is nothing to be
  # short of -- and the completeness check must not reintroduce the wait.
  my %res;
  my $c = client_for("HTTP/1.1 200 OK\r\nContent-Length: 13\r\n"
    . "X-Docker-Container-Path-Stat: e30=\r\n\r\n");
  my $got = eval { $c->head('/containers/abc/archive', response => \%res) };
  is $@, '', 'a 13-byte announcement with no body raises nothing'
    or diag "raised: $@";
  is $res{headers}{'x-docker-container-path-stat'}, 'e30=',
    'and the header carrying the payload is there';
  close $c->peer;
};

# ---------------------------------------------------------------------------
# The one shape where an EOF is the end
# ---------------------------------------------------------------------------
subtest 'a close-delimited body ends at the close, as it must' => sub {
  # attach, logs(follow), exec/start: neither Content-Length nor chunked, so
  # the response announces no end and the close is the only one there is.
  # Making this fatal would break every raw-stream endpoint in the
  # distribution.
  my $c = client_for("HTTP/1.1 200 OK\r\n"
    . "Content-Type: application/vnd.docker.raw-stream\r\n\r\n"
    . "\x01\x00\x00\x00\x00\x00\x00\x05hello");

  my $got = eval { $c->get('/containers/abc/attach', raw => 1) };
  is $@, '', 'nothing raised' or diag "raised: $@";
  is $got, "\x01\x00\x00\x00\x00\x00\x00\x05hello",
    'the bytes up to the close are the body';
  close $c->peer;
};

subtest 'a close-delimited body cut mid-frame is still not truncation' => sub {
  # Half a frame is a real problem, and it is not this one: nothing announced
  # eight bytes of header plus five of payload, so the transport has no
  # statement to compare it against. stream_frames says so at the framing
  # level; the transport must not guess at it.
  my $c = client_for("HTTP/1.1 200 OK\r\n\r\n\x01\x00\x00\x00\x00\x00\x00\x05he");
  my $got = eval { $c->get('/containers/abc/attach', raw => 1) };
  is $@, '', 'the transport raises nothing' or diag "raised: $@";
  is length($got), 10, 'and hands over the bytes it got';
  close $c->peer;
};

# ---------------------------------------------------------------------------
# Streaming: the caller already has the units, and still has to be told
# ---------------------------------------------------------------------------
subtest 'a chunked stream cut short croaks after delivering what arrived'
  => sub {
  my @got;
  my $c = client_for("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
    . qq(11\r\n{"status":"one"}\n\r\n)
    . qq(11\r\n{"status":"two"}\n\r\n)
    . "20\r\n{\"status\":\"thr");

  my $summary = eval {
    $c->get('/events', croak_on_error => 0,
      on_event => sub { push @got, $_[0] });
  };
  my $err = $@;
  close $c->peer;

  is $summary, undef, 'no summary came back';
  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->phase, 'chunk-data', 'the chunk fell short of its header';
  is_deeply [ map { $_->{status} } @got ], [qw( one two )],
    'both complete events reached the callback first';
  is_deeply $err && $err->summary, { delivered => 2, stopped => 0 },
    'and the summary says so, exactly as the return value would have';
  is $err && $err->partial, '',
    'no body: a streamed request keeps none by design';
  like $err && "$err", qr/2 units delivered/, 'the message says so too';
};

subtest 'a stream the callback stopped is never truncation' => sub {
  # The rest of the response is unread because the caller said so. Every
  # completeness check on the streaming path is guarded by that, and this is
  # the assertion that keeps it guarded: without it every early $stop->()
  # would come back as an exception.
  my @got;
  my $c = client_for("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
    . qq(11\r\n{"status":"one"}\n\r\n)
    . qq(11\r\n{"status":"two"}\n\r\n)
    . "20\r\n{\"status\":\"thr");

  my $summary = eval {
    $c->get('/events', croak_on_error => 0, on_event => sub {
      my ($event, $stop) = @_;
      push @got, $event;
      $stop->() if $event->{status} eq 'two';
    });
  };
  my $err = $@;
  close $c->peer;

  is $err, '', 'the truncated tail of the response raises nothing'
    or diag "raised: $err";
  is_deeply $summary, { delivered => 2, stopped => 1 },
    'the summary comes back and says the callback ended it';
  is_deeply [ map { $_->{status} } @got ], [qw( one two )], 'two events';
};

subtest 'a content-length stream cut short croaks too' => sub {
  my @got;
  my $c = client_for(sized(qq({"status":"one"}\n{"status":"tw),
    announce => 40));

  my $summary = eval {
    $c->get('/images/create', croak_on_error => 0,
      on_event => sub { push @got, $_[0] });
  };
  my $err = $@;
  close $c->peer;

  is $summary, undef, 'no summary';
  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->phase, 'content-length', 'the body fell short';
  is_deeply [ map { $_->{status} } @got ], ['one'],
    'the one complete event was delivered before the exception';
  is_deeply $err && $err->summary, { delivered => 1, stopped => 0 },
    'and is counted';
  like $err && "$err", qr/1 unit delivered/, 'singular, not "1 units"';
};

# The two assertions that hold the `$more &&` guard in place. Without them the
# guard can be dropped from both streaming checks and everything else here
# still passes: over a socketpair a chunk is complete in the buffer before the
# callback sees a byte of it, so a stop never leaves the reader short. It does
# on a live stream, which is the case these two script.
subtest 'a chunk the callback stopped inside is not truncation' => sub {
  my @got;
  my $fh = stepped("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
    . '14' . "\r\n" . ('x' x 20) . "\r\n0\r\n\r\n", 5);
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0]; $_[1]->() }, 0);

  my $res = eval {
    $client->_read_streaming_response($fh, 'GET', $handler, {}) };
  is $@, '', 'stopping inside a chunk raises nothing' or diag "raised: $@";
  is scalar @got, 1, 'one unit reached the callback';
  cmp_ok length($got[0]), '<', 20,
    'and it is less than the whole chunk, so the reader really did stop '
    . 'short of what the chunk header announced';
  is_deeply $res && $res->[4], { delivered => 1, stopped => 1 },
    'the summary says the callback ended it, not the daemon';
};

subtest 'a content-length body the callback stopped inside is not truncation'
  => sub {
  my @got;
  my $fh = stepped("HTTP/1.1 200 OK\r\nContent-Length: 20\r\n\r\n"
    . ('x' x 20), 5);
  my $handler = $client->_stream_handler('GET /v1.41/probe', 'on_chunk',
    sub { push @got, $_[0]; $_[1]->() }, 0);

  my $res = eval {
    $client->_read_streaming_response($fh, 'GET', $handler, {}) };
  is $@, '', 'stopping inside the body raises nothing' or diag "raised: $@";
  is scalar @got, 1, 'one unit reached the callback';
  cmp_ok length($got[0]), '<', 20, 'short of the announced length';
  is_deeply $res && $res->[4], { delivered => 1, stopped => 1 },
    'and the summary says who ended it';
};

subtest 'a close-delimited stream is not truncated by its close' => sub {
  my @got;
  my $c = client_for("HTTP/1.1 200 OK\r\n\r\n"
    . "\x01\x00\x00\x00\x00\x00\x00\x05hello");

  my $summary = eval {
    $c->get('/containers/abc/attach', on_frame => sub { push @got, $_[0] });
  };
  is $@, '', 'nothing raised' or diag "raised: $@";
  is_deeply $summary, { delivered => 1, stopped => 0 }, 'one frame delivered';
  is_deeply \@got, [{ stream => 'stdout', data => 'hello' }], 'and decoded';
  close $c->peer;
};

# ---------------------------------------------------------------------------
# What the exception is
# ---------------------------------------------------------------------------
subtest 'the exception behaves like the others' => sub {
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\nhello wor",
    sub { $client->_read_response($_[0], 'GET', { endpoint => 'GET /v1.41/x' }) });

  isa_ok $err, 'API::Docker::Error::Truncated';
  ok overload::Overloaded($err),
    'stringification is in place -- namespace::clean before use overload';
  unlike "$err", qr/=HASH\(0x/,
    'stringifies to the reason, not to a reference address';
  like "$err", qr{\QGET /v1.41/x\E}, 'the request is named in the string';
  like "$err", qr/ at \S+ line \d+/, "with Carp's own location suffix";
  ok !!$err, 'and it is true as an exception';
  is $err->as_string, "$err", 'as_string is what the overload returns';
};

subtest 'a reader driven with no context still names the phase' => sub {
  # t/role_http.t drives the readers directly with no request behind them, so
  # there is no endpoint to name. The message leaves it out rather than
  # interpolating an empty pair of parentheses.
  my ($err) = over_pair(
    "HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\nhello wor",
    sub { $client->_read_response($_[0], 'GET', {}) });

  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->endpoint, '', 'no endpoint';
  like $err && "$err", qr/\ADocker API response truncated: /,
    'and the message goes straight to the reason';
};

subtest 'nothing at all is said so rather than reported as zero bytes' => sub {
  my ($err) = over_pair("HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\n",
    sub { $client->_read_response($_[0], 'GET', {}) });

  isa_ok $err, 'API::Docker::Error::Truncated';
  is $err && $err->partial, '', 'partial is empty';
  is $err && $err->received, 0, 'and nothing was received';
  like $err && "$err", qr/nothing arrived at all/, 'the message says so';
};

subtest 'a >= 400 body that is itself cut short is reported as truncation'
  => sub {
  # The rule the read timeout already follows, applied to the same place: the
  # transport cannot tell a caller what the engine said when it did not finish
  # saying it. The price is that a 404 whose body the daemon cut off arrives
  # as this class rather than as API::Docker::Error::HTTP, so ->status is not
  # there -- which is the honest answer, the status line having been the only
  # complete part of a response that was not.
  my $c = client_for(sized('{"message":"no such contain',
    announce => 40, status => '404 Not Found'));

  my %res;
  my $got = eval { $c->get('/containers/abc/json', response => \%res) };
  my $err = $@;
  close $c->peer;

  is $got, undef, 'nothing came back';
  isa_ok $err, 'API::Docker::Error::Truncated';
  ok !$err->isa('API::Docker::Error::HTTP'),
    'and it is not the status error, which would have claimed a whole body';
  is $err && $err->partial, '{"message":"no such contain',
    'the part of the error body that did arrive is carried';
  is_deeply \%res, {},
    'the response out-parameter is untouched: _request never got that far';
};

done_testing;
