use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

subtest 'list networks' => sub {
  my $docker = test_docker(
    'GET /networks' => load_fixture('networks_list'),
  );

  my $networks = $docker->networks->list;

  is(ref $networks, 'ARRAY', 'returns array');
  if (@$networks) {
    isa_ok($networks->[0], 'API::Docker::Type::Network');
    ok($networks->[0]->name, 'has name');
  }

  unless (is_live()) {
    is(scalar @$networks, 2, 'two networks');

    my $first = $networks->[0];
    is($first->name, 'bridge', 'network name');
    is($first->driver, 'bridge', 'network driver');
    is($first->scope, 'local', 'network scope');
    ok(!$first->internal, 'not internal');
    is($first->ipam->config->[0]->subnet, '172.17.0.0/16',
      'and IPAM is inflated into its own generated classes rather than '
      . 'staying the raw HashRef the old entity kept');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'network lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /networks/create' => sub {
      my ($method, $path, %opts) = @_;
      is($opts{body}{Name}, 'test-net', 'network name in body') unless is_live();
      return { Id => 'mock-net-123', Warning => '' };
    },
    'GET /networks/mock-net-123'             => {
      Name   => 'test-net',
      Id     => 'mock-net-123',
      Driver => 'bridge',
      Scope  => 'local',
      Labels => {},
    },
    'POST /networks/mock-net-123/connect'    => undef,
    'POST /networks/mock-net-123/disconnect' => undef,
    'DELETE /networks/mock-net-123'          => undef,
  );

  my $name = 'api-docker-test-net-' . $$;
  my $result = $docker->networks->create(
    Name   => is_live() ? $name : 'test-net',
    Driver => 'bridge',
  );
  ok($result->{Id}, 'created network has Id');
  my $id = is_live() ? $result->{Id} : 'mock-net-123';

  register_cleanup(sub { eval { $docker->networks->remove($id) } }) if is_live();

  my $network = $docker->networks->inspect($id);
  isa_ok($network, 'API::Docker::Type::Network');
  ok($network->name, 'has name');

  unless (is_live()) {
    $docker->networks->connect($id, Container => 'abc123');
    pass('connect completed');

    $docker->networks->disconnect($id, Container => 'abc123');
    pass('disconnect completed');
  }

  $docker->networks->remove($id);
  pass('network removed');
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'network ID required' => sub {
  my $docker = test_docker();

  eval { $docker->networks->inspect(undef) };
  like($@, qr/Network ID required/, 'croak on missing ID for inspect');

  eval { $docker->networks->remove(undef) };
  like($@, qr/Network ID required/, 'croak on missing ID for remove');
};

subtest 'connect requires container' => sub {
  my $docker = test_docker();

  eval { $docker->networks->connect('net1') };
  like($@, qr/Container required/, 'croak on missing container for connect');
};

done_testing;
