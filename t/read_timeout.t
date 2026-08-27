use strict;
use warnings;
use Test::More;
use Socket;
use Errno;
use Time::HiRes qw( time );
use API::Docker;
use API::Docker::Error::Timeout;

# The read timeout of API::Docker::Role::HTTP (karr #59), in two tiers.
#
# Tier one -- everything down to "the real socket" below -- is the loop logic,
# which is where the risk is. SO_RCVTIMEO does not poison the handle and does
# not end the stream: a read that ran out of time comes back looking exactly
# like a read that reached the end of the response, and errno is the only
# thing that tells them apart. Every `last unless $n` in the readers would
# otherwise take a timeout for the end of the body and hand back a truncated
# response as a whole one -- turning the hang this option removes into silent
# data loss, which is worse than the hang. So each read site is driven twice,
# once for each meaning of the same short read, and the two have to come out
# differently. A tied handle can produce both exactly, with no socket and no
# waiting.
#
# Tier two is the one assertion a tied handle cannot make: that the setsockopt
# is really in force on a real socket. That one costs about a fifth of a
# second and needs a socketpair, no daemon and no network.
#
# Nothing here reaches a Docker daemon, so there is no is_live()/can_write()
# gating: it is unconditionally safe with no engine installed.

# ---------------------------------------------------------------------------
# A tied handle scripted with what each read is to do, so both meanings of a
# short read can be produced on demand:
#
#   { line  => "text\n" }               a whole line
#   { line  => "half",  timeout => 1 }  the half a line an expired readline
#                                       hands back, with EAGAIN in errno
#   { line  => undef,   timeout => 1 }  an expired readline with nothing at all
#   { line  => undef }                  the clean end of the response
#   { bytes => "abc" }                  three bytes
#   { bytes => "ab", timeout => 1 }     a short read that ran out of time
#   { bytes => '',   timeout => 1 }     an expired read with nothing at all
#   { bytes => '' }                     the clean end of the response
#
# Running off the end of the script is the clean end, so a scenario only has
# to script as far as the site under test. Every one of these shapes was
# measured on a real socketpair with SO_RCVTIMEO set before being written
# down here -- including the two that matter most: an interrupted readline
# returns the part of the line it has, and a clean end leaves errno untouched
# while an expiry sets EAGAIN.
package Test::ReadTimeout::Handle;

sub TIEHANDLE {
  my ($class, $script) = @_;
  return bless { script => $script, i => 0 }, $class;
}

sub _next {
  my ($self) = @_;
  return $self->{script}[ $self->{i}++ ] || {};
}

sub READLINE {
  my ($self) = @_;
  my $act = $self->_next;
  # Set last and read first: errno is only meaningful straight after the
  # operation that failed, which is exactly the discipline the code under
  # test has to keep. With keep_errno it is left exactly as the caller left
  # it, which is how a stale value gets in front of the check.
  $! = $act->{timeout} ? Errno::EAGAIN() : 0 unless $act->{keep_errno};
  return $act->{line};
}

sub READ {
  my $self = $_[0];
  my $act  = $self->_next;
  my $data = defined $act->{bytes} ? $act->{bytes} : '';
  $_[1] = $data;
  $! = $act->{timeout} ? Errno::EAGAIN() : 0 unless $act->{keep_errno};
  # read() answers a pure failure with undef and a partial delivery with the
  # count it managed; both are short, and both are what an expiry can look
  # like.
  return undef if $act->{timeout} && !length $data;
  return length $data;
}

sub CLOSE { 1 }

package main;

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

my $ENDPOINT = 'GET /v1.41/probe';

sub scripted {
  my (@script) = @_;
  no warnings "once";
  my $glob = \do { local *HANDLE };
  tie *$glob, 'Test::ReadTimeout::Handle', \@script;
  return $glob;
}

# A context with the clock running, and one without. The second is what every
# call made before this option existed passes, and it must leave every read
# site behaving exactly as it did.
sub ctx      { return { endpoint => $ENDPOINT, timeout => 2 } }
sub ctx_off  { return { endpoint => $ENDPOINT } }

# Run $code and report whether it raised a timeout, so the two meanings of one
# short read can be asserted side by side.
sub timed_out {
  my ($code) = @_;
  my @out = eval { $code->() };
  my $err = $@;
  return (undef, $err) if $err && ref $err
    && $err->isa('API::Docker::Error::Timeout');
  return (\@out, undef) unless $err;
  return (undef, undef, $err);
}

# Reading an attribute off whatever was raised, so a mutation that stops
# raising one fails the assertion it belongs to instead of dying and taking
# the rest of the file with it -- a red test has to stay readable.
sub attr {
  my ($err, $name) = @_;
  return ref $err && $err->can($name) ? $err->$name : undef;
}

# The pair of assertions every read site gets: with EAGAIN it croaks, without
# it the site behaves as it always has. A test that only made the first half
# would pass just as well against a transport that croaked on every end of
# response.
sub site_ok {
  my ($name, $make_handle, $drive, $eof_check) = @_;

  subtest $name => sub {
    my ($out, $err, $other) = timed_out(
      sub { $drive->($make_handle->(1), ctx()) });
    ok !$other, 'the expiry raised nothing but a timeout'
      or diag "raised instead: $other";
    ok $err, 'ran out of time -> API::Docker::Error::Timeout';
    is $err && attr($err, "timeout"), 2, 'the error names the timeout that expired'
      if $err;
    is $err && attr($err, "endpoint"), $ENDPOINT, 'and the request it belongs to'
      if $err;

    my ($eof_out, $eof_err, $eof_other) = timed_out(
      sub { $drive->($make_handle->(0), ctx()) });
    ok !$eof_err, 'the same short read at the end of the response does not';
    $eof_check->($eof_out, $eof_other) if $eof_check;

    # And with no timeout armed, the EAGAIN case is not a timeout either --
    # the option is what turns the check on, not the errno.
    my ($off_out, $off_err, $off_other) = timed_out(
      sub { $drive->($make_handle->(1), ctx_off()) });
    ok !$off_err, 'with no read_timeout set, EAGAIN is not consulted at all';
  };
}

my $HEAD_OK = { line => "HTTP/1.1 200 OK\r\n" };
my $BLANK   = { line => "\r\n" };

# ---------------------------------------------------------------------------
# _read_head -- the status line and the header block
# ---------------------------------------------------------------------------
site_ok '_read_head: the status line never arrives',
  sub { scripted({ line => undef, timeout => $_[0] }) },
  sub { $client->_read_head($_[0], $_[1]) },
  sub {
    my ($out, $other) = @_;
    like $other, qr/No response from Docker daemon/,
      'a daemon that closed without answering still says so, and says '
      . 'something else than a timeout';
  };

site_ok '_read_head: half a status line',
  sub { scripted({ line => 'HTTP/1.1 20', timeout => $_[0] }) },
  sub { $client->_read_head($_[0], $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0][0], '20',
      'an unterminated final line is still parsed when it is the end of the '
      . 'response -- which is why the terminator alone cannot decide this';
  };

site_ok '_read_head: the header block stops halfway',
  sub {
    scripted($HEAD_OK, { line => "Content-Type: application/json\r\n" },
      { line => 'X-Half', timeout => $_[0] });
  },
  sub { $client->_read_head($_[0], $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0][2]{'content-type'}, 'application/json',
      'the headers that did arrive are kept';
  };

# ---------------------------------------------------------------------------
# _read_body -- the three shapes a buffered body comes in
# ---------------------------------------------------------------------------
site_ok '_read_body: a content-length body stops short',
  sub {
    scripted({ bytes => 'hello ' }, { bytes => 'wor', timeout => $_[0] });
  },
  sub {
    $client->_read_body($_[0], { 'content-length' => 11 }, 'GET', $_[1]);
  },
  sub {
    my ($out) = @_;
    is $out->[0], 'hello wor',
      'a truncated body is returned as though whole when the response really '
      . 'ended -- the exact silent loss the errno check prevents';
  };

site_ok '_read_body: a close-delimited body stops short',
  sub { scripted({ line => 'partial frames', timeout => $_[0] }) },
  sub { $client->_read_body($_[0], {}, 'GET', $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0], 'partial frames', 'the bytes are the body at a real close';
  };

site_ok '_read_chunked: the chunk header stops halfway',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => '1a', timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0], 'hello', 'the chunks that completed are kept';
  };

site_ok '_read_chunked: the chunk data stops short',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => "6\r\n" }, { bytes => ' wor', timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0], 'hello wor', 'a chunk cut off by a real close is kept';
  };

site_ok '_read_chunked: the CRLF after the chunk data never arrives',
  sub {
    scripted({ line => "5\r\n" }, { bytes => 'hello' },
      { line => undef, timeout => $_[0] });
  },
  sub { $client->_read_chunked($_[0], $_[1]) },
  sub {
    my ($out) = @_;
    is $out->[0], 'hello', 'the chunk itself is kept';
  };

# ---------------------------------------------------------------------------
# _read_streaming_response -- the same three shapes, one callback at a time
# ---------------------------------------------------------------------------
sub chunk_handler {
  my ($got) = @_;
  return $client->_stream_handler($ENDPOINT, 'on_chunk',
    sub { push @$got, $_[0] }, 1);
}

sub drive_stream {
  my ($got) = @_;
  return sub {
    my ($fh, $c) = @_;
    return $client->_read_streaming_response($fh, 'GET', chunk_handler($got), $c);
  };
}

{
  my @got;
  site_ok 'streaming, chunked: the chunk header stops halfway',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
        { line => '1a', timeout => $_[0] });
    },
    drive_stream(\@got),
    sub { is_deeply \@got, ['hello', 'hello'],
      'both runs delivered the completed chunk' };
}

{
  my @got;
  site_ok 'streaming, chunked: the chunk data stops short',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "6\r\n" }, { bytes => ' wor', timeout => $_[0] });
    },
    drive_stream(\@got),
    sub {
      is_deeply \@got, [' wor', ' wor'],
        'the bytes of the read that ran out of time are handed to the '
        . 'callback before the exception is raised, so both runs deliver the '
        . 'same units and only one of them also croaks';
    };
}

{
  my @got;
  site_ok 'streaming, chunked: the CRLF after the chunk data never arrives',
    sub {
      scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" }, $BLANK,
        { line => "5\r\n" }, { bytes => 'hello' },
        { line => undef, timeout => $_[0] });
    },
    drive_stream(\@got),
    sub { is_deeply \@got, ['hello', 'hello'], 'the chunk was delivered' };
}

{
  my @got;
  site_ok 'streaming, content-length: the body stops short',
    sub {
      scripted($HEAD_OK, { line => "Content-Length: 11\r\n" }, $BLANK,
        { bytes => 'hello ' }, { bytes => 'wor', timeout => $_[0] });
    },
    drive_stream(\@got),
    sub {
      is_deeply \@got, ['hello ', 'wor', 'hello ', 'wor'],
        'same on the content-length path: nothing that arrived is dropped '
        . 'because the rest of it did not';
    };
}

{
  my @got;
  site_ok 'streaming, close-delimited: the body stops short',
    sub {
      scripted($HEAD_OK, $BLANK,
        { bytes => 'frame one' }, { bytes => 'fra', timeout => $_[0] });
    },
    drive_stream(\@got),
    sub {
      is_deeply \@got, ['frame one', 'fra', 'frame one', 'fra'],
        'and on the raw-stream path, which is the one karr #52 hangs on and '
        . 'where it matters most: read() asks for 64K and fills, so the whole '
        . 'response is still unfed when the stall lands';
    };
}

# ---------------------------------------------------------------------------
# What the exception carries
# ---------------------------------------------------------------------------
subtest 'the bytes that did arrive come out with the exception' => sub {
  subtest 'a content-length body' => sub {
    my $fh = scripted({ bytes => 'hello ' }, { bytes => 'wor', timeout => 1 });
    eval { $client->_read_body($fh, { 'content-length' => 11 }, 'GET', ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), 'hello wor',
      'everything read so far, the bytes of the read that expired included';
    is attr($err, "summary"), undef, 'no summary: nothing was streamed';
  };

  subtest 'a chunked body keeps the chunk it stalled inside' => sub {
    my $fh = scripted({ line => "5\r\n" }, { bytes => 'hello' },
      { line => "\r\n" }, { line => "6\r\n" },
      { bytes => ' wor', timeout => 1 });
    eval { $client->_read_chunked($fh, ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), 'hello wor',
      'the completed chunk and the part of the one still arriving';
  };

  subtest 'a close-delimited body' => sub {
    my $fh = scripted({ line => 'partial frames', timeout => 1 });
    eval { $client->_read_body($fh, {}, 'GET', ctx()) };
    isa_ok $@, 'API::Docker::Error::Timeout';
    is attr($@, "partial"), 'partial frames', 'the bytes the slurp had collected';
  };

  subtest 'a streamed request carries the summary instead' => sub {
    my @got;
    my $fh = scripted($HEAD_OK, { line => "Transfer-Encoding: chunked\r\n" },
      $BLANK,
      { line => "5\r\n" }, { bytes => 'hello' }, { line => "\r\n" },
      { line => "5\r\n" }, { bytes => 'there' }, { line => "\r\n" },
      { line => undef, timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is_deeply attr($err, "summary"), { delivered => 2, stopped => 0 },
      'the units the callback did get, counted the way a clean end counts them';
    is attr($err, "partial"), '',
      'and no body: a streamed request keeps none by design';
    like attr($err, "message"), qr/2 units/, 'the message says so too';
  };

  subtest 'the units completed by the read that expired are delivered' => sub {
    # This is the shape karr #52 actually has: everything the daemon had to
    # say arrives in a single read and the socket then stays open and silent.
    # read() fills, so that one read is also the one that expires -- and if
    # its bytes went up with the exception instead of through the feed, a
    # caller with a callback would be handed nothing at all even though the
    # whole response had arrived. Measured against Podman 5.8.4 on an attach
    # to an exited container: two frames, 42 bytes, delivered 0 before this
    # and 2 after.
    my @got;
    my $fh = scripted($HEAD_OK, $BLANK,
      { bytes => 'frame one and two', timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is_deeply \@got, ['frame one and two'],
      'the callback got the bytes of the read that ran out of time';
    is_deeply attr($err, 'summary'), { delivered => 1, stopped => 0 },
      'and the summary counts them, so it says what happened rather than '
      . 'undercounting it';
  };

  subtest 'an error body on the way to a >= 400 croak is counted in bytes' => sub {
    # The summary is only armed past the status line, so a timeout while
    # reading the short JSON body of a failure is not reported as units that
    # nothing delivered.
    my @got;
    my $fh = scripted({ line => "HTTP/1.1 500 Internal Server Error\r\n" },
      { line => "Content-Length: 40\r\n" }, $BLANK,
      { bytes => '{"message":"bo', timeout => 1 });
    eval {
      $client->_read_streaming_response($fh, 'GET', chunk_handler(\@got), ctx());
    };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "summary"), undef, 'no summary for a body that was never a stream';
    is attr($err, "partial"), '{"message":"bo', 'the bytes of the error body';
  };

  subtest 'nothing at all is said so, not reported as zero bytes' => sub {
    my $fh = scripted($HEAD_OK, { line => "Content-Length: 11\r\n" }, $BLANK,
      { bytes => '', timeout => 1 });
    eval { $client->_read_response($fh, 'GET', ctx()) };
    my $err = $@;
    isa_ok $err, 'API::Docker::Error::Timeout';
    is attr($err, "partial"), '', 'partial is empty';
    like attr($err, "message"), qr/nothing arrived at all/, 'and the message says so';
  };
};

subtest 'the exception is still the string it replaces' => sub {
  my $fh = scripted({ line => undef, timeout => 1 });
  eval { $client->_read_head($fh, ctx()) };
  my $err = $@;
  isa_ok $err, 'API::Docker::Error::Timeout';
  ok overload::Overloaded($err),
    'stringification is in place -- namespace::clean before use overload';
  unlike "$err", qr/=HASH\(0x/,
    "stringifies to the reason, not to a reference address";
  like "$err", qr/\Q$ENDPOINT\E/, 'the request is named in the string';
  like "$err", qr/ at \S+ line \d+/, 'with Carp\'s own location suffix';
  ok !!$err, 'and it is true as an exception';
};

# ---------------------------------------------------------------------------
# A real socket: that the setsockopt is in force, and that _request arms it
# ---------------------------------------------------------------------------
subtest 'the real socket: SO_RCVTIMEO is actually set' => sub {
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";

  $client->_apply_read_timeout($ours, 0.2);

  # The peer is open and silent, so without the option in force this read
  # blocks forever and the test never finishes.
  my $t0 = time;
  eval { $client->_read_line($ours, ctx()) };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  cmp_ok $elapsed, '>=', 0.15,
    'it waited for the timeout rather than returning at once ('
    . sprintf('%.2fs', $elapsed) . ')';
  cmp_ok $elapsed, '<', 5, 'and gave up rather than hanging';

  # Not poisoned: the same handle keeps working afterwards, which is what
  # makes this an idle timeout per read rather than a dead connection.
  syswrite $theirs, "still here\n";
  is $client->_read_line($ours, ctx()), "still here\n",
    'and the handle still reads after an expiry';

  close $ours;
  close $theirs;
};

subtest 'a stale errno cannot be mistaken for this read timing out' => sub {
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";
  $client->_apply_read_timeout($ours, 5);

  syswrite $theirs, "a whole line\nand 12 bytes";
  close $theirs;   # the clean end of the response, with no waiting involved

  # errno is only meaningful straight after the operation that failed, and
  # nothing clears it on success -- so whatever the process did before this
  # request is still sitting in it. The read sites zero it immediately before
  # each read for exactly this reason: without that, every clean end of a
  # response that happened to follow an unrelated EAGAIN would be reported as
  # this request timing out, and the option would break working code.
  $! = Errno::EAGAIN();
  is $client->_read_line($ours, ctx()), "a whole line\n",
    'a complete line still arrives';

  $! = Errno::EAGAIN();
  my ($n, $buf) = $client->_read_bytes($ours, 4096, ctx());
  is $buf, 'and 12 bytes', 'a short read at the end of the response is not '
    . 'turned into a timeout by an errno left over from before it';

  $! = Errno::EAGAIN();
  my $out = eval { $client->_read_line($ours, ctx()) };
  ok !$@, 'nor is the end of the response itself' or diag "raised: $@";
  is $out, undef, 'which is simply undef, as it always was';

  close $ours;
};

subtest 'the read sites clear errno rather than trusting what they find'
  => sub {
  # The socketpair above cannot show this on its own: perl's read() happens to
  # zero errno itself on a socket, so removing the zeroing there changes
  # nothing. A handle that leaves errno alone is the only way to pin that the
  # check reads the errno of *this* read and not one from before it -- and
  # _read_bytes is a primitive, so its correctness must not rest on a perl
  # internal that is documented nowhere.
  my $fh = scripted({ bytes => 'twelve bytes', keep_errno => 1 });
  $! = Errno::EAGAIN();
  my ($n, $buf) = eval { $client->_read_bytes($fh, 4096, ctx()) };
  ok !$@, 'a short read is not a timeout because of an older EAGAIN'
    or diag "raised: $@";
  is $buf, 'twelve bytes', 'and the bytes come back';

  my $lh = scripted({ line => 'no terminator', keep_errno => 1 });
  $! = Errno::EAGAIN();
  my $line = eval { $client->_read_line($lh, ctx()) };
  ok !$@, 'nor is an unterminated final line' or diag "raised: $@";
  is $line, 'no terminator', 'which is returned as the line it is';
};

subtest 'a socket that cannot take a timeout is refused, not ignored' => sub {
  # A real, open handle that is simply not a socket -- so setsockopt fails
  # with ENOTSOCK rather than with "unopened", which is the shape a wrong
  # transport would actually have.
  open my $fh, '<', '/dev/null' or die $!;

  eval { $client->_apply_read_timeout($fh, 1) };
  like $@, qr/cannot set a read timeout/,
    'setsockopt failing croaks: a caller waiting on a bound that is not in '
    . 'force is the very failure this option exists to end';

  is $client->_apply_read_timeout($fh, undef), undef,
    'with no timeout asked for, nothing is attempted and nothing complains';
  close $fh;
};

# ---------------------------------------------------------------------------
# _request: which value ends up on the socket
# ---------------------------------------------------------------------------
{
  package Test::ReadTimeout::Recorder;
  use Moo;
  extends 'API::Docker';

  # A client whose socket is one end of a socketpair with the whole response
  # already in it, so the real _request runs against a real socket -- and
  # whose peer is held open and never written to again, so anything reading
  # past the response is a genuine wait.
  has canned => (is => 'rw', default => sub { '' });
  has peer   => (is => 'rw');
  has armed  => (is => 'rw', default => sub { [] });

  sub _build__socket {
    my ($self) = @_;
    socketpair(my $ours, my $theirs, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
      Socket::PF_UNSPEC()) or die "socketpair: $!";
    syswrite $theirs, $self->canned;
    $self->peer($theirs);
    return $ours;
  }

  around _apply_read_timeout => sub {
    my ($orig, $self, $sock, $timeout) = @_;
    push @{ $self->armed }, $timeout;
    return $self->$orig($sock, $timeout);
  };
}

sub recorder {
  my (%args) = @_;
  return Test::ReadTimeout::Recorder->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}",
    %args,
  );
}

subtest '_request: the per-call option and the client attribute' => sub {
  subtest 'neither set -- nothing is armed, which is the old behaviour' => sub {
    my $c = recorder();
    is_deeply $c->get('/probe'), {}, 'the request still works';
    is_deeply $c->armed, [undef], 'no timeout reached the socket';
  };

  subtest 'the attribute applies to every request' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe');
    $c->get('/probe');
    is_deeply $c->armed, [7, 7], 'both requests armed it';
  };

  subtest 'the option overrides the attribute' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => 1.5);
    is_deeply $c->armed, [1.5], 'the call wins';
  };

  subtest '0 turns a client default off for one call' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => 0);
    is_deeply $c->armed, [undef],
      'an explicit 0 is "wait as long as it takes", not "no opinion" -- '
      . 'which is why the option is resolved with exists rather than //';
  };

  subtest 'undef turns it off too' => sub {
    my $c = recorder(read_timeout => 7);
    $c->get('/probe', read_timeout => undef);
    is_deeply $c->armed, [undef], 'passing undef explicitly is the same as 0';
  };

  subtest 'a value that is not a timeout is refused before connecting' => sub {
    my $c = recorder();
    for my $bad (-1, 'soon', {}) {
      eval { $c->get('/probe', read_timeout => $bad) };
      like $@, qr/read_timeout must be a non-negative number/,
        'refused: ' . (ref $bad ? 'a reference' : $bad);
    }
    is_deeply $c->armed, [], 'and nothing was armed, so nothing was sent';
  };
};

subtest '_request: end to end on a real socket, with the response cut short'
  => sub {
  # Content-Length promises 40 bytes and 14 arrive; the peer stays open and
  # silent, which is karr #52's hang exactly.
  my $c = recorder(
    canned       => "HTTP/1.1 200 OK\r\nContent-Length: 40\r\n\r\nhalf a body!!!",
    read_timeout => 0.2,
  );

  my $t0 = time;
  eval { $c->get('/probe') };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  is attr($err, "partial"), 'half a body!!!',
    'the bytes that did arrive are on the exception rather than returned as '
    . 'though they were the whole body';
  is attr($err, "endpoint"), 'GET /v1.41/probe', 'the endpoint, without a query string';
  is attr($err, "timeout"), 0.2, 'the timeout that expired';
  cmp_ok $elapsed, '<', 5, 'it gave up instead of hanging';
  close $c->peer;
};

subtest '_request: a response that is complete is not affected by a timeout'
  => sub {
  my $c = recorder(read_timeout => 0.2);
  my $got = $c->get('/probe');
  is_deeply $got, {}, 'a whole body comes back as it always did';
  close $c->peer;
};

done_testing;
