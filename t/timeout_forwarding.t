use strict;
use warnings;
use Test::More;
use API::Docker;

# Every resource method that forwards read_timeout forwards connect_timeout
# too (karr #70).
#
# Both options are resolved in _request and nowhere else, so a resource method
# either puts them into the option list it builds or drops them on the floor.
# Dropping them is silent: %opts is a plain hash and a key nothing reads is not
# an error, so `pull(fromImage => 'x', connect_timeout => 5)` used to return
# normally having ignored the bound entirely. That is what this asserts, at the
# seam the value has to cross.
#
# Nothing here reaches a daemon and nothing here opens a socket: _request is
# replaced outright, which takes API::Docker's version-negotiation `around`
# with it, so the paths arrive unprefixed.

package Test::TimeoutForward::Probe;
use Moo;
extends 'API::Docker';

has calls => (is => 'ro', default => sub { [] });

sub _request {
  my ($self, $method, $path, %opts) = @_;
  push @{ $self->calls }, { method => $method, path => $path, opts => \%opts };

  # Shaped only so the method under test can finish. What it does with the
  # answer is asserted elsewhere; the option list it built is what matters
  # here. The container inspect is attach()'s running-check preflight.
  return { State => { Running => 1 } } if $path =~ m{^/containers/[^/]+/json$};
  return [] if $path =~ m{/stats$};
  return '';
}

# Records what _build__socket was handed rather than connecting, the way
# t/connect_timeout.t does -- but reached through a resource method, which is
# the whole of what karr #70 was about.
package Test::TimeoutForward::ConnectProbe;
use Moo;
extends 'API::Docker';

has seen => (is => 'ro', required => 1);

sub _build__socket {
  my ($self) = @_;
  my $pending = $self->_pending_connect;
  push @{ $self->seen }, $pending ? $pending->{timeout} : 'no pending';
  die "no socket here\n";
}

package main;

# id, the call, and the endpoint whose option list carries the answer -- named
# rather than taken as "the last call", because attach() reaches the daemon
# twice and only the second one is this method's own request.
my @cases = (
  [ 'images->build', 'POST /build',
    sub { $_[0]->images->build(context => 'tar', @_[1 .. $#_]) } ],
  [ 'images->pull', 'POST /images/create',
    sub { $_[0]->images->pull(fromImage => 'alpine', @_[1 .. $#_]) } ],
  [ 'images->push', 'POST /images/alpine/push',
    sub { $_[0]->images->push('alpine', @_[1 .. $#_]) } ],
  [ 'images->get', 'GET /images/alpine/get',
    sub { $_[0]->images->get('alpine', @_[1 .. $#_]) } ],
  [ 'images->get_all', 'GET /images/get',
    sub { $_[0]->images->get_all(['alpine'], @_[1 .. $#_]) } ],
  [ 'images->load', 'POST /images/load',
    sub { $_[0]->images->load('tar', @_[1 .. $#_]) } ],
  [ 'containers->logs', 'GET /containers/c1/logs',
    sub { $_[0]->containers->logs('c1', @_[1 .. $#_]) } ],
  [ 'containers->attach', 'POST /containers/c1/attach',
    sub { $_[0]->containers->attach('c1', @_[1 .. $#_]) } ],
  [ 'containers->stats', 'GET /containers/c1/stats',
    sub { $_[0]->containers->stats('c1', @_[1 .. $#_]) } ],
  [ 'exec->start', 'POST /exec/e1/start',
    sub { $_[0]->exec->start('e1', @_[1 .. $#_]) } ],
  [ 'plugins->install', 'POST /plugins/pull',
    sub { $_[0]->plugins->install('p', privileges => [], @_[1 .. $#_]) } ],
  [ 'plugins->upgrade', 'POST /plugins/p/upgrade',
    sub { $_[0]->plugins->upgrade('p', privileges => [], @_[1 .. $#_]) } ],
  [ 'plugins->push', 'POST /plugins/p/push',
    sub { $_[0]->plugins->push('p', @_[1 .. $#_]) } ],
  [ 'system->events', 'GET /events',
    sub { $_[0]->system->events(@_[1 .. $#_]) } ],
);

# The option list the named endpoint was requested with, or a string saying
# why there is none -- which is_deeply then reports instead of an empty hash.
sub opts_for {
  my ($case, @args) = @_;
  my (undef, $want, $code) = @$case;

  my $probe = Test::TimeoutForward::Probe->new(
    host => 'unix:///nonexistent-api-docker-70.sock', api_version => '1.41');

  eval { $code->($probe, @args); 1 }
    or return 'the call died before requesting anything: ' . $@;

  my @seen;
  for my $call (@{ $probe->calls }) {
    my $endpoint = $call->{method} . ' ' . $call->{path};
    push @seen, $endpoint;
    return $call->{opts} if $endpoint eq $want;
  }
  return "never requested $want (requested: " . join(', ', @seen) . ')';
}

# ---------------------------------------------------------------------------
subtest 'both bounds reach the request the method makes' => sub {
  for my $case (@cases) {
    my $opts = opts_for($case, read_timeout => 3, connect_timeout => 7);
    is_deeply
      ref $opts eq 'HASH'
        ? { map { exists $opts->{$_} ? ($_ => $opts->{$_}) : () }
              qw( read_timeout connect_timeout ) }
        : $opts,
      { read_timeout => 3, connect_timeout => 7 },
      $case->[0] . ' forwards both';
  }
};

# The subtlety `exists` buys, and the one a `? :` on truth would lose: 0 is
# "wait as long as it takes", which is how a client-wide default is turned off
# for one call. Forwarded on truth it would vanish here and the client
# attribute would win -- the opposite of what the caller asked for.
subtest 'an explicit 0 is forwarded, not read as "no opinion"' => sub {
  for my $case (@cases) {
    my $opts = opts_for($case, read_timeout => 0, connect_timeout => 0);
    is_deeply
      ref $opts eq 'HASH'
        ? { map { exists $opts->{$_} ? ($_ => $opts->{$_}) : () }
              qw( read_timeout connect_timeout ) }
        : $opts,
      { read_timeout => 0, connect_timeout => 0 },
      $case->[0] . ' forwards an explicit 0 for both';
  }
};

# The other half of `exists`: neither key is invented when the caller passed
# none, so a client carrying an attribute is not overridden with undef by
# every method that could have taken the option.
subtest 'neither is invented when the caller passed none' => sub {
  for my $case (@cases) {
    my $opts = opts_for($case);
    is_deeply
      ref $opts eq 'HASH'
        ? [ sort grep { exists $opts->{$_} } qw( read_timeout connect_timeout ) ]
        : $opts,
      [],
      $case->[0] . ' passes neither key on';
  }
};

# ---------------------------------------------------------------------------
# The forwarding above is only worth anything if the transport reads the
# option, so the other end of the wire is asserted too -- that a value handed
# to _request as an option reaches the socket constructor. t/connect_timeout.t
# proves what the socket then does with it.
subtest 'the transport picks the forwarded value up' => sub {
  my @seen;

  my $probe = Test::TimeoutForward::ConnectProbe->new(
    host        => 'unix:///nonexistent-api-docker-70.sock',
    api_version => '1.41',
    seen        => \@seen,
  );

  eval { $probe->images->pull(fromImage => 'alpine', connect_timeout => 7) };
  eval { $probe->system->events(connect_timeout => 2) };
  eval { $probe->containers->logs('c1', connect_timeout => 0) };
  eval { $probe->images->get('alpine') };

  is_deeply \@seen, [7, 2, undef, undef],
    'the option resolved per request, an explicit 0 turning the bound off, '
    . 'and nothing armed when it was not passed';
};

done_testing;
