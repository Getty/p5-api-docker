use strict;
use warnings;
use Test::More;
use API::Docker;

# Every public resource method that reaches the daemon forwards read_timeout
# and connect_timeout (karr #70 for the first fourteen, karr #72 for the rest).
#
# Both options are resolved in _request and nowhere else, so a resource method
# either puts them into the option list it builds or drops them on the floor.
# Dropping them is silent: %opts is a plain hash and a key nothing reads is not
# an error, so `networks->list(read_timeout => 5)` used to return normally
# having ignored the bound entirely. That is what this asserts, at the seam the
# value has to cross.
#
# The pre-flight requests are in the table too -- the running check attach
# makes, the privileges fetch install and upgrade make under
# accept_privileges => 1 -- named by the endpoint they issue rather than by the
# method, because a caller who set a bound and then hangs in a request they
# never wrote has been told something untrue.
#
# Nothing here reaches a daemon and nothing here opens a socket: _request is
# replaced outright, which takes API::Docker's version-negotiation `around`
# with it, so the paths arrive unprefixed. The negotiation is asserted
# separately at the bottom, where that `around` has to stay in place.

package Test::TimeoutForward::Probe;
use Moo;
extends 'API::Docker';

has calls => (is => 'ro', default => sub { [] });

sub _request {
  my ($self, $method, $path, %opts) = @_;
  push @{ $self->calls }, { method => $method, path => $path, opts => \%opts };

  # Shaped only so the method under test can finish. What it does with the
  # answer is asserted elsewhere; the option list it built is what matters
  # here. The container inspect is attach()'s running-check pre-flight.
  return { State => { Running => 1 } } if $path =~ m{^/containers/[^/]+/json$};
  return { Volumes => [] }             if $path eq '/volumes';
  return []
    if $path =~ m{^/(?:containers/json|images/json|networks|secrets|configs|plugins)$};
  return [] if $path =~ m{/stats$};
  # The inspects, which wrap what comes back in an entity object.
  return {} if $path =~ m{/json$};
  return {} if $path =~ m{^/(?:networks|volumes|secrets|configs)/[^/]+$};
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

# _request is left alone here so that API::Docker's `around` still runs and
# still triggers the negotiation; only the negotiation itself is intercepted.
package Test::TimeoutForward::NegotiateProbe;
use Moo;
extends 'API::Docker';

has negotiations => (is => 'ro', default => sub { [] });

sub negotiate_version {
  my ($self, %opts) = @_;
  push @{ $self->negotiations }, \%opts;
  # What the real one does on success, so the request that triggered it can
  # go on and only one negotiation is recorded per client.
  $self->_set_api_version('1.41');
  $self->_version_negotiated(1);
  return;
}

sub _build__socket { die "no socket here\n" }

package main;

# id, the call, and the endpoint whose option list carries the answer -- named
# rather than taken as "the last call", because several of these reach the
# daemon twice and only one of the two is the request being asserted.
my @cases = (
  # -- containers ----------------------------------------------------------
  [ 'containers->list', 'GET /containers/json',
    sub { $_[0]->containers->list(@_[1 .. $#_]) } ],
  [ 'containers->inspect', 'GET /containers/c1/json',
    sub { $_[0]->containers->inspect('c1', @_[1 .. $#_]) } ],
  [ 'containers->start', 'POST /containers/c1/start',
    sub { $_[0]->containers->start('c1', @_[1 .. $#_]) } ],
  [ 'containers->stop', 'POST /containers/c1/stop',
    sub { $_[0]->containers->stop('c1', @_[1 .. $#_]) } ],
  [ 'containers->restart', 'POST /containers/c1/restart',
    sub { $_[0]->containers->restart('c1', @_[1 .. $#_]) } ],
  [ 'containers->kill', 'POST /containers/c1/kill',
    sub { $_[0]->containers->kill('c1', @_[1 .. $#_]) } ],
  [ 'containers->remove', 'DELETE /containers/c1',
    sub { $_[0]->containers->remove('c1', @_[1 .. $#_]) } ],
  [ 'containers->logs', 'GET /containers/c1/logs',
    sub { $_[0]->containers->logs('c1', @_[1 .. $#_]) } ],
  [ 'containers->attach', 'POST /containers/c1/attach',
    sub { $_[0]->containers->attach('c1', @_[1 .. $#_]) } ],
  [ 'containers->attach pre-flight', 'GET /containers/c1/json',
    sub { $_[0]->containers->attach('c1', @_[1 .. $#_]) } ],
  [ 'containers->top', 'GET /containers/c1/top',
    sub { $_[0]->containers->top('c1', @_[1 .. $#_]) } ],
  [ 'containers->stats', 'GET /containers/c1/stats',
    sub { $_[0]->containers->stats('c1', @_[1 .. $#_]) } ],
  [ 'containers->changes', 'GET /containers/c1/changes',
    sub { $_[0]->containers->changes('c1', @_[1 .. $#_]) } ],
  [ 'containers->export', 'GET /containers/c1/export',
    sub { $_[0]->containers->export('c1', @_[1 .. $#_]) } ],
  [ 'containers->resize', 'POST /containers/c1/resize',
    sub { $_[0]->containers->resize('c1', @_[1 .. $#_]) } ],
  [ 'containers->wait', 'POST /containers/c1/wait',
    sub { $_[0]->containers->wait('c1', @_[1 .. $#_]) } ],
  [ 'containers->pause', 'POST /containers/c1/pause',
    sub { $_[0]->containers->pause('c1', @_[1 .. $#_]) } ],
  [ 'containers->unpause', 'POST /containers/c1/unpause',
    sub { $_[0]->containers->unpause('c1', @_[1 .. $#_]) } ],
  [ 'containers->rename', 'POST /containers/c1/rename',
    sub { $_[0]->containers->rename('c1', 'c2', @_[1 .. $#_]) } ],
  [ 'containers->get_archive', 'GET /containers/c1/archive',
    sub { $_[0]->containers->get_archive('c1', path => '/etc', @_[1 .. $#_]) } ],
  [ 'containers->put_archive', 'PUT /containers/c1/archive',
    sub { $_[0]->containers->put_archive('c1', 'tar', path => '/etc',
      @_[1 .. $#_]) } ],
  [ 'containers->stat_archive', 'HEAD /containers/c1/archive',
    sub { $_[0]->containers->stat_archive('c1', path => '/etc', @_[1 .. $#_]) } ],
  [ 'containers->prune', 'POST /containers/prune',
    sub { $_[0]->containers->prune(@_[1 .. $#_]) } ],

  # -- images --------------------------------------------------------------
  [ 'images->list', 'GET /images/json',
    sub { $_[0]->images->list(@_[1 .. $#_]) } ],
  [ 'images->build', 'POST /build',
    sub { $_[0]->images->build(context => 'tar', @_[1 .. $#_]) } ],
  [ 'images->pull', 'POST /images/create',
    sub { $_[0]->images->pull(fromImage => 'alpine', @_[1 .. $#_]) } ],
  [ 'images->inspect', 'GET /images/alpine/json',
    sub { $_[0]->images->inspect('alpine', @_[1 .. $#_]) } ],
  [ 'images->history', 'GET /images/alpine/history',
    sub { $_[0]->images->history('alpine', @_[1 .. $#_]) } ],
  [ 'images->push', 'POST /images/alpine/push',
    sub { $_[0]->images->push('alpine', @_[1 .. $#_]) } ],
  [ 'images->tag', 'POST /images/alpine/tag',
    sub { $_[0]->images->tag('alpine', repo => 'r', @_[1 .. $#_]) } ],
  [ 'images->remove', 'DELETE /images/alpine',
    sub { $_[0]->images->remove('alpine', @_[1 .. $#_]) } ],
  [ 'images->search', 'GET /images/search',
    sub { $_[0]->images->search('alpine', @_[1 .. $#_]) } ],
  [ 'images->prune', 'POST /images/prune',
    sub { $_[0]->images->prune(@_[1 .. $#_]) } ],
  [ 'images->get', 'GET /images/alpine/get',
    sub { $_[0]->images->get('alpine', @_[1 .. $#_]) } ],
  [ 'images->get_all', 'GET /images/get',
    sub { $_[0]->images->get_all(['alpine'], @_[1 .. $#_]) } ],
  [ 'images->load', 'POST /images/load',
    sub { $_[0]->images->load('tar', @_[1 .. $#_]) } ],
  [ 'images->commit', 'POST /commit',
    sub { $_[0]->images->commit(container => 'c1', @_[1 .. $#_]) } ],
  [ 'images->build_prune', 'POST /build/prune',
    sub { $_[0]->images->build_prune(@_[1 .. $#_]) } ],

  # -- networks ------------------------------------------------------------
  [ 'networks->list', 'GET /networks',
    sub { $_[0]->networks->list(@_[1 .. $#_]) } ],
  [ 'networks->inspect', 'GET /networks/n1',
    sub { $_[0]->networks->inspect('n1', @_[1 .. $#_]) } ],
  [ 'networks->remove', 'DELETE /networks/n1',
    sub { $_[0]->networks->remove('n1', @_[1 .. $#_]) } ],
  [ 'networks->prune', 'POST /networks/prune',
    sub { $_[0]->networks->prune(@_[1 .. $#_]) } ],

  # -- volumes -------------------------------------------------------------
  [ 'volumes->list', 'GET /volumes',
    sub { $_[0]->volumes->list(@_[1 .. $#_]) } ],
  [ 'volumes->inspect', 'GET /volumes/v1',
    sub { $_[0]->volumes->inspect('v1', @_[1 .. $#_]) } ],
  [ 'volumes->remove', 'DELETE /volumes/v1',
    sub { $_[0]->volumes->remove('v1', @_[1 .. $#_]) } ],
  [ 'volumes->prune', 'POST /volumes/prune',
    sub { $_[0]->volumes->prune(@_[1 .. $#_]) } ],

  # -- secrets -------------------------------------------------------------
  [ 'secrets->list', 'GET /secrets',
    sub { $_[0]->secrets->list(@_[1 .. $#_]) } ],
  [ 'secrets->inspect', 'GET /secrets/s1',
    sub { $_[0]->secrets->inspect('s1', @_[1 .. $#_]) } ],
  [ 'secrets->remove', 'DELETE /secrets/s1',
    sub { $_[0]->secrets->remove('s1', @_[1 .. $#_]) } ],

  # -- configs -------------------------------------------------------------
  [ 'configs->list', 'GET /configs',
    sub { $_[0]->configs->list(@_[1 .. $#_]) } ],
  [ 'configs->inspect', 'GET /configs/cf1',
    sub { $_[0]->configs->inspect('cf1', @_[1 .. $#_]) } ],
  [ 'configs->remove', 'DELETE /configs/cf1',
    sub { $_[0]->configs->remove('cf1', @_[1 .. $#_]) } ],

  # -- exec ----------------------------------------------------------------
  [ 'exec->start', 'POST /exec/e1/start',
    sub { $_[0]->exec->start('e1', @_[1 .. $#_]) } ],
  [ 'exec->resize', 'POST /exec/e1/resize',
    sub { $_[0]->exec->resize('e1', h => 40, w => 120, @_[1 .. $#_]) } ],
  [ 'exec->inspect', 'GET /exec/e1/json',
    sub { $_[0]->exec->inspect('e1', @_[1 .. $#_]) } ],

  # -- system --------------------------------------------------------------
  [ 'system->info', 'GET /info',
    sub { $_[0]->system->info(@_[1 .. $#_]) } ],
  [ 'system->version', 'GET /version',
    sub { $_[0]->system->version(@_[1 .. $#_]) } ],
  [ 'system->ping', 'GET /_ping',
    sub { $_[0]->system->ping(@_[1 .. $#_]) } ],
  [ 'system->events', 'GET /events',
    sub { $_[0]->system->events(@_[1 .. $#_]) } ],
  [ 'system->df', 'GET /system/df',
    sub { $_[0]->system->df(@_[1 .. $#_]) } ],
  [ 'system->auth', 'POST /auth',
    sub { $_[0]->system->auth(username => 'u', password => 'p',
      @_[1 .. $#_]) } ],

  # -- plugins -------------------------------------------------------------
  [ 'plugins->list', 'GET /plugins',
    sub { $_[0]->plugins->list(@_[1 .. $#_]) } ],
  [ 'plugins->privileges', 'GET /plugins/privileges',
    sub { $_[0]->plugins->privileges('p', @_[1 .. $#_]) } ],
  [ 'plugins->install', 'POST /plugins/pull',
    sub { $_[0]->plugins->install('p', privileges => [], @_[1 .. $#_]) } ],
  [ 'plugins->install privileges pre-flight', 'GET /plugins/privileges',
    sub { $_[0]->plugins->install('p', accept_privileges => 1,
      @_[1 .. $#_]) } ],
  [ 'plugins->inspect', 'GET /plugins/p/json',
    sub { $_[0]->plugins->inspect('p', @_[1 .. $#_]) } ],
  [ 'plugins->remove', 'DELETE /plugins/p',
    sub { $_[0]->plugins->remove('p', @_[1 .. $#_]) } ],
  [ 'plugins->enable', 'POST /plugins/p/enable',
    sub { $_[0]->plugins->enable('p', @_[1 .. $#_]) } ],
  [ 'plugins->disable', 'POST /plugins/p/disable',
    sub { $_[0]->plugins->disable('p', @_[1 .. $#_]) } ],
  [ 'plugins->upgrade', 'POST /plugins/p/upgrade',
    sub { $_[0]->plugins->upgrade('p', privileges => [], @_[1 .. $#_]) } ],
  [ 'plugins->upgrade privileges pre-flight', 'GET /plugins/privileges',
    sub { $_[0]->plugins->upgrade('p', accept_privileges => 1,
      @_[1 .. $#_]) } ],
  [ 'plugins->push', 'POST /plugins/p/push',
    sub { $_[0]->plugins->push('p', @_[1 .. $#_]) } ],
  [ 'plugins->configure', 'POST /plugins/p/set',
    sub { $_[0]->plugins->configure('p', ['A=1'], @_[1 .. $#_]) } ],

  # -- distribution --------------------------------------------------------
  [ 'distribution->inspect', 'GET /distribution/alpine/json',
    sub { $_[0]->distribution->inspect('alpine', @_[1 .. $#_]) } ],
  [ 'distribution->exists', 'GET /distribution/alpine/json',
    sub { $_[0]->distribution->exists('alpine', @_[1 .. $#_]) } ],
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
# Version negotiation is the pre-flight nobody writes: it happens once, before
# the first request of a client with no api_version, and a bound that does not
# reach it leaves that first request unbounded in the one place the caller
# cannot see (karr #72). Two halves, because the `around` and the method are
# separately capable of dropping it.
subtest 'the negotiation inherits the triggering request bounds' => sub {
  for my $args ([ read_timeout => 3, connect_timeout => 7 ],
                [ read_timeout => 0, connect_timeout => 0 ],
                []) {
    my $probe = Test::TimeoutForward::NegotiateProbe->new(
      host => 'unix:///nonexistent-api-docker-72.sock');

    eval { $probe->containers->list(@$args) };

    is_deeply $probe->negotiations, [ { @$args } ],
      'containers->list(' . join(', ', @$args) . ') negotiates with the same';
  }
};

subtest 'negotiate_version puts them on the /version request' => sub {
  for my $args ([ read_timeout => 3, connect_timeout => 7 ],
                [ read_timeout => 0, connect_timeout => 0 ],
                []) {
    my $probe = Test::TimeoutForward::Probe->new(
      host => 'unix:///nonexistent-api-docker-72.sock');

    $probe->negotiate_version(@$args);

    my ($call) = grep { $_->{path} eq '/version' } @{ $probe->calls };
    is_deeply
      $call
        ? { map { exists $call->{opts}{$_} ? ($_ => $call->{opts}{$_}) : () }
              qw( read_timeout connect_timeout ) }
        : 'never requested /version',
      { @$args },
      'negotiate_version(' . join(', ', @$args) . ') forwards what it was given';
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
  eval { $probe->networks->list(connect_timeout => 4) };
  eval { $probe->volumes->inspect('v1', connect_timeout => 6) };

  is_deeply \@seen, [7, 2, undef, undef, 4, 6],
    'the option resolved per request, an explicit 0 turning the bound off, '
    . 'and nothing armed when it was not passed';
};

done_testing;
