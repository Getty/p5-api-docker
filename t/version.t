use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# Captured 2026-08-28 (karr k101) against Docker Engine Community 29.7.2
# (API 1.55): GET /version, unversioned as the client itself sends it,
# unmodified.
subtest 'version info' => sub {
  my $docker = test_docker(
    'GET /version' => load_fixture('system_version'),
  );

  my $version = $docker->system->version;

  ok($version->{ApiVersion}, 'has ApiVersion');
  ok($version->{Version}, 'has Version');
  ok($version->{Os}, 'has Os');
  ok($version->{Arch}, 'has Arch');

  unless (is_live()) {
    is($version->{ApiVersion}, '1.55', 'ApiVersion correct');
    is($version->{Version}, '29.7.2', 'Version correct');
    is($version->{Os}, 'linux', 'Os correct');
    is($version->{Arch}, 'amd64', 'Arch correct');
    is($version->{GoVersion}, 'go1.26.5', 'GoVersion correct');
    is($version->{MinAPIVersion}, '1.40', 'MinAPIVersion correct');
  }
};

subtest 'explicit version skips negotiation' => sub {
  my $docker = API::Docker->new(api_version => '1.45');
  is($docker->api_version, '1.45', 'explicit version preserved');
};

subtest 'auto-negotiate version' => sub {
  if (is_live()) {
    my $docker = API::Docker->new(host => $ENV{API_DOCKER_TEST_HOST});
    $docker->negotiate_version;
    ok(defined $docker->api_version, 'api_version negotiated');
    like($docker->api_version, qr/^\d+\.\d+$/, 'version looks valid');
  } else {
    # Not a negotiation exercise in mock mode: _mock_docker pins
    # api_version at construction (see t/lib/Test/API/Docker/Mock.pm),
    # which is exactly what makes negotiate_version's own guard skip it, so
    # this route is never actually consulted for the client's api_version.
    # What this checks is that the mock's fixed default and the fixture's
    # real ApiVersion stay coordinated, deliberately, rather than agreeing
    # by coincidence the way '1.47' on both sides used to.
    my $docker = test_docker(
      'GET /version' => load_fixture('system_version'),
    );
    is($docker->api_version, '1.55',
      "mock client's fixed api_version matches the system_version fixture");
  }
};

done_testing;
