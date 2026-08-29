use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# --- Read Tests (always run) ---

# volumes_list is still hand-rolled, not captured: at recapture time (karr
# k101) no volume existed on either engine reachable from this machine, and
# creating one only to capture it was out of bounds for that task. See the
# header of t/type_fixture_passthrough.t.
subtest 'list volumes' => sub {
  my $docker = test_docker(
    'GET /volumes' => load_fixture('volumes_list'),
  );

  my $volumes = $docker->volumes->list;

  is(ref $volumes, 'ARRAY', 'returns array');
  if (@$volumes) {
    isa_ok($volumes->[0], 'API::Docker::Type::Volume');
    ok($volumes->[0]->name, 'has name');
  }

  unless (is_live()) {
    is(scalar @$volumes, 2, 'two volumes');

    my $first = $volumes->[0];
    is($first->name, 'my-data', 'volume name');
    is($first->driver, 'local', 'volume driver');
    is($first->scope, 'local', 'volume scope');
    is_deeply($first->labels, { project => 'test' }, 'volume labels');
    like($first->mountpoint, qr{/var/lib/docker/volumes/my-data}, 'mountpoint');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'volume lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /volumes/create' => sub {
      my ($method, $path, %opts) = @_;
      is($opts{body}{Name}, 'test-vol', 'volume name in body') unless is_live();
      return {
        Name       => 'test-vol',
        Driver     => 'local',
        Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
        CreatedAt  => '2025-01-15T12:00:00Z',
        Labels     => {},
        Scope      => 'local',
        Options    => {},
      };
    },
    'GET /volumes/test-vol' => {
      Name       => 'test-vol',
      Driver     => 'local',
      Mountpoint => '/var/lib/docker/volumes/test-vol/_data',
      CreatedAt  => '2025-01-10T08:00:00Z',
      Labels     => {},
      Scope      => 'local',
      Options    => {},
    },
    'DELETE /volumes/test-vol' => undef,
  );

  my $name = is_live() ? 'api-docker-test-vol-' . $$ : 'test-vol';
  my $volume = $docker->volumes->create(Name => $name);
  isa_ok($volume, 'API::Docker::Type::Volume');
  ok($volume->name, 'created volume has a name');

  register_cleanup(sub { eval { $docker->volumes->remove($name, force => 1) } }) if is_live();

  my $inspected = $docker->volumes->inspect($name);
  isa_ok($inspected, 'API::Docker::Type::Volume');
  is($inspected->driver, 'local', 'volume driver is local');

  $docker->volumes->remove($name);
  pass('volume removed');
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'volume name required' => sub {
  my $docker = test_docker();

  eval { $docker->volumes->inspect(undef) };
  like($@, qr/Volume name required/, 'croak on missing name for inspect');

  eval { $docker->volumes->remove(undef) };
  like($@, qr/Volume name required/, 'croak on missing name for remove');
};

done_testing;
