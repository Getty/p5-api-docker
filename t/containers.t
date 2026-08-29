use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker::Role::Entity::Container;

check_live_access();

# --- Read Tests (always run) ---

# containers_list/container_inspect are still hand-rolled, not captured: at
# recapture time (karr k101) no container existed on either engine reachable
# from this machine, and creating one only to capture it was out of bounds
# for that task. See the header of t/type_fixture_passthrough.t.
subtest 'list containers' => sub {
  my $docker = test_docker(
    'GET /containers/json' => load_fixture('containers_list'),
  );

  my $containers = $docker->containers->list(all => 1);

  is(ref $containers, 'ARRAY', 'returns array');
  if (@$containers) {
    isa_ok($containers->[0], 'API::Docker::Type::ContainerSummary');
    ok($containers->[0]->id, 'has an id');
  }

  unless (is_live()) {
    is(scalar @$containers, 2, 'two containers');

    my $first = $containers->[0];
    is($first->id, 'abc123def456', 'container id');
    is_deeply($first->names, ['/my-container'], 'container names');
    is($first->image, 'nginx:latest', 'container image');
    is($first->state, 'running', 'container state');
    ok($first->is_running, 'is_running returns true for running container');

    my $second = $containers->[1];
    is($second->id, 'def789ghi012', 'second container id');
    is($second->state, 'exited', 'second container state');
    ok(!$second->is_running, 'is_running returns false for exited container');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'container lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /containers/create'         => { Id => 'mock123', Warnings => [] },
    'POST /containers/mock123/start'  => undef,
    'GET /containers/mock123/json'    => load_fixture('container_inspect'),
    'GET /containers/mock123/top'     => {
      Titles    => ['UID', 'PID', 'PPID', 'C', 'STIME', 'TTY', 'TIME', 'CMD'],
      Processes => [
        ['root', '12345', '1', '0', '08:00', '?', '00:00:00', 'sleep'],
      ],
    },
    'GET /containers/mock123/stats'   => {
      cpu_stats    => { cpu_usage => { total_usage => 1000 } },
      memory_stats => { usage => 50000000 },
    },
    'POST /containers/mock123/pause'   => undef,
    'POST /containers/mock123/unpause' => undef,
    'POST /containers/mock123/stop'    => undef,
    'DELETE /containers/mock123'       => undef,
  );

  if (is_live()) {
    # containers->create does not auto-pull; alpine:3 (the tag the rest of
    # the suite standardises on) is not guaranteed to be cached on a fresh
    # checkout. Pull it explicitly rather than relying on another test
    # file -- or an earlier manual run -- having already done so: prove's
    # file order is not a contract this test should depend on.
    $docker->images->pull(fromImage => 'alpine', tag => '3');
  }

  my $name = 'api-docker-test-' . $$;
  my $created = $docker->containers->create(
    name  => $name,
    Image => 'alpine:3',
    Cmd   => ['sleep', '10'],
  );
  ok($created->{Id}, 'created container has Id');
  my $id = is_live() ? $created->{Id} : 'mock123';

  # Safety net for a die before the remove below; on the happy path the
  # container is already gone, and that must not warn.
  register_cleanup(sub {
    eval { $docker->containers->remove($id, force => 1) };
    die $@ if $@ && $@ !~ /\(404\)/;
  }) if is_live();

  is($docker->containers->start($id), 1,
    'container started -- 204, a state change that happened');

  my $container = $docker->containers->inspect($id);
  isa_ok($container, 'API::Docker::Type::ContainerInspectResponse');
  ok($container->is_running, 'container is running');

  my $top = $docker->containers->top($id);
  is(ref $top->{Processes}, 'ARRAY', 'top has processes');

  my $stats = $docker->containers->stats($id);
  ok($stats->{cpu_stats}, 'has cpu_stats');
  ok($stats->{memory_stats}, 'has memory_stats');

  is($docker->containers->pause($id), 1, 'container paused');
  is($docker->containers->unpause($id), 1, 'container unpaused');

  is($docker->containers->stop($id, timeout => 3), 1, 'container stopped');

  $docker->containers->remove($id);
  pass('container removed');
};

# --- 304 Not Modified (fixture-only, no daemon) ---

# karr k16: the engine answers a state change with 204 and a no-op state
# change with 304 Not Modified. Both carry an empty body, so both used to come
# back as undef and "started it" could not be told from "it was
# already running".
#
# Fixture-only on purpose: reaching a real 304 means driving a real container
# into the target state first, which is what the write tests above are for.
# The 1/0 mapping over the real transport is covered without a daemon in
# t/role_http.t; what this proves is that the mapping survives the whole
# containers->start call, route table included.
subtest 'a state change reports whether it changed anything' => sub {
  plan skip_all => 'fixture-only: a live 304 needs a container already in the '
    . 'target state (see t/role_http.t for the transport-level check)'
    if is_live();

  my $docker = test_docker(
    'POST /containers/running/start' => mock_response(status => 304),
    'POST /containers/running/stop'  => mock_response(status => 204),
    'POST /containers/exited/start'  => mock_response(status => 204),
    'POST /containers/exited/stop'   => mock_response(status => 304),
  );

  is $docker->containers->start('exited'), 1,
    'start on a stopped container: 204, so it changed something';
  is $docker->containers->start('running'), 0,
    'start on a running one: 304, so it did not -- and this is the value that '
    . 'used to be undef, indistinguishable from the 204 above';

  is $docker->containers->stop('running'), 1, 'stop on a running container: 204';
  is $docker->containers->stop('exited'), 0, 'stop on a stopped one: 304';

  ok !$docker->containers->start('running'),
    'the no-op stays false, so a caller testing truth is unaffected by the '
    . 'change from undef to 0';

  # The entity forwards the value rather than swallowing it.
  my $container = API::Docker::Type::ContainerSummary->new(
    client => $docker,
    Id     => 'running',
  );
  is $container->start, 0, '$container->start reports the 304 too';
  is $container->stop, 1, 'and $container->stop the 204';
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'container ID required' => sub {
  my $docker = test_docker();

  eval { $docker->containers->inspect(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for inspect');

  eval { $docker->containers->start(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for start');

  eval { $docker->containers->stop(undef) };
  like($@, qr/Container ID required/, 'croak on missing ID for stop');
};

done_testing;
