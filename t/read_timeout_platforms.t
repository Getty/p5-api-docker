#!/usr/bin/env perl
use strict;
use warnings;

# read_timeout on the systems where SO_RCVTIMEO does not hold it, each played
# on this one with the value that system hands back.
#
#   GNU/Hurd       setsockopt(SO_RCVTIMEO) fails with ENOPROTOOPT, "Protocol
#                  not available" (perl 5.24.4 and 5.44.0)
#   armv6l Linux   setsockopt(SO_RCVTIMEO) fails with EINVAL (perl 5.44.0,
#                  glibc 2.42, 32-bit IV)
#   Haiku          setsockopt succeeds, and a read that runs out of time comes
#                  back after the time without EAGAIN: the transport took it
#                  for the end of the stream, so a timeout raised nothing and
#                  a cut-short response was reported as truncated (perl 5.42.2)
#
# All three are CPAN Testers reports against 0.006. The first two croaked
# "cannot set a read timeout" on every request that asked for one, in
# t/read_timeout.t and t/tls_read.t alike.
#
# The setsockopt failure is played by a CORE::GLOBAL override, installed
# before API::Docker is compiled so that its setsockopt call is the one
# overridden; it refuses SO_RCVTIMEO with $REFUSE and passes every other call
# through. Haiku is played with $^O and a socket whose expiry says ETIMEDOUT --
# the report does not name the errno, and any errno but EAGAIN gives the
# result it shows.

use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SO_RCVTIMEO );
use Errno qw( EAGAIN EWOULDBLOCK ENOPROTOOPT EINVAL ENOTSOCK ETIMEDOUT );

our $REFUSE;

BEGIN {
  *CORE::GLOBAL::setsockopt = sub (*$$$) {
    my ($fh, $level, $name, $value) = @_;
    if (defined $main::REFUSE && $level == SOL_SOCKET && $name == SO_RCVTIMEO) {
      $! = $main::REFUSE;
      return;
    }
    return CORE::setsockopt($fh, $level, $name, $value);
  };
}

use Test::More;
use IO::Handle;
use Time::HiRes qw( time );
use API::Docker;
use API::Docker::Error::Timeout;

{
  package Test::ReadTimeoutPlatforms::HaikuSock;
  our @ISA = ('IO::Handle');

  sub sysread {
    my $self = shift;
    my $n = $self->SUPER::sysread(@_);
    $! = Errno::ETIMEDOUT()
      if !defined $n && ($! == Errno::EAGAIN() || $! == Errno::EWOULDBLOCK());
    return $n;
  }
}

{
  package Test::ReadTimeoutPlatforms::Canned;
  use Moo;
  extends 'API::Docker';

  has canned => (is => 'ro', default => sub { '' });
  has peer   => (is => 'rw');

  sub _build__socket {
    my ($self) = @_;
    socketpair(my $ours, my $theirs, Socket::AF_UNIX(), Socket::SOCK_STREAM(),
      Socket::PF_UNSPEC()) or die "socketpair: $!";
    syswrite $theirs, $self->canned;
    $self->peer($theirs);
    return $ours;
  }
}

my $ENDPOINT = 'GET /v1.41/probe';

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

sub ctx_for { return { endpoint => $ENDPOINT, timeout => $_[0] } }

sub pair {
  socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or plan skip_all => "socketpair unavailable: $!";
  return ($ours, $theirs);
}

# A silent peer, a read that has to give up, and the same handle afterwards:
# what t/read_timeout.t asks of a real socket, asked again here.
sub held_on_time {
  my ($ours, $theirs, $timeout) = @_;

  my $t0 = time;
  eval { $client->_read_line($ours, ctx_for($timeout)) };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout', 'the expiry';
  cmp_ok $elapsed, '>=', $timeout * 0.75,
    'it waited for the timeout (' . sprintf('%.2fs', $elapsed) . ')';
  cmp_ok $elapsed, '<', 5, 'and gave up rather than hanging';

  syswrite $theirs, "still here\n";
  is $client->_read_line($ours, ctx_for($timeout)), "still here\n",
    'the handle still reads after an expiry';

  close $theirs;
  my $out = eval { $client->_read_line($ours, ctx_for($timeout)) };
  ok !$@, 'the peer closing is the end, not a timeout' or diag "raised: $@";
  is $out, undef, 'which is undef';
}

for my $case (
  [ ENOPROTOOPT, 'GNU/Hurd: the socket has no SO_RCVTIMEO (ENOPROTOOPT)' ],
  [ EINVAL,      'armv6l Linux: the socket refuses the struct timeval (EINVAL)' ],
) {
  my ($errno, $name) = @$case;

  subtest $name => sub {
    local $REFUSE = $errno;
    my ($ours, $theirs) = pair();

    my $armed = eval { $client->_apply_read_timeout($ours, 0.2); 1 };
    ok $armed, 'the request goes ahead instead of croaking'
      or do { diag "raised: $@"; return };

    held_on_time($ours, $theirs, 0.2);
    close $ours;
  };
}

subtest 'a socket that refuses the option, end to end through _request' => sub {
  local $REFUSE = ENOPROTOOPT;

  # Content-Length promises 40 bytes, 14 arrive, and the peer stays open and
  # silent. The socket _request opens is the one that refused the option, so
  # this is the path a real request takes from the refusal to the expiry.
  my $c = Test::ReadTimeoutPlatforms::Canned->new(
    host         => 'unix:///nonexistent.sock',
    api_version  => '1.41',
    canned       => "HTTP/1.1 200 OK\r\nContent-Length: 40\r\n\r\nhalf a body!!!",
    read_timeout => 0.2,
  );

  my $t0 = time;
  eval { $c->get('/probe') };
  my $err     = $@;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  is ref $err && $err->partial, 'half a body!!!', 'with the bytes that arrived';
  cmp_ok $elapsed, '<', 5, 'after the timeout, not after a hang ('
    . sprintf('%.2fs', $elapsed) . ')';
};

subtest 'any other refusal still croaks' => sub {
  # Only the two answers that say "this socket takes no such option" are
  # covered by waiting with select. Anything else -- here a handle that is
  # not a socket -- is still refused, with the reason.
  local $REFUSE = ENOTSOCK;
  my ($ours, $theirs) = pair();
  my $reason = do { local $! = ENOTSOCK; "$!" };
  eval { $client->_apply_read_timeout($ours, 0.2) };
  like $@, qr/cannot set a read timeout of 0\.2s on this socket: \Q$reason\E/,
    'croaks, naming the reason';
  close $ours;
  close $theirs;
};

subtest 'Haiku: the expiry is caught by waiting, not by EAGAIN' => sub {
  local $^O = 'haiku';
  my ($ours, $theirs) = pair();

  # The socket answers a read that ran out of time with ETIMEDOUT rather than
  # EAGAIN, standing in for what Haiku's does. Reading that as a timeout would
  # need the option armed and its errno trusted; the transport does neither.
  my $sock = IO::Handle->new_from_fd(fileno($ours), 'r+')
    or die "new_from_fd: $!";
  bless $sock, 'Test::ReadTimeoutPlatforms::HaikuSock';

  my $armed = eval { $client->_apply_read_timeout($sock, 0.2); 1 };
  ok $armed, 'arming raises nothing' or do { diag "raised: $@"; return };
  my $opt = getsockopt($sock, SOL_SOCKET, SO_RCVTIMEO);
  ok !(defined $opt && grep { $_ } unpack('l!l!', $opt)),
    'and leaves SO_RCVTIMEO unset';

  held_on_time($sock, $theirs, 0.2);
  close $sock;
  close $ours;
};

done_testing;
