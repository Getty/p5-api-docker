use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use API::Docker::Type::ContainerInspectResponse;
use API::Docker::Type::ContainerSummary;
use API::Docker::Type::ImageSummary;
use API::Docker::Type::Network;
use API::Docker::Type::Secret;
use API::Docker::Type::SystemInfo;
use API::Docker::Type::SystemVersion;
use API::Docker::Type::VolumeListResponse;

# karr k81: every fixture under t/fixtures/*.json is captured output from a
# real daemon (skill api-docker-core), not hand-rolled -- so feeding each one
# through the generated class its endpoint returns measures the type model's
# passthrough invariant against reality rather than against a test its own
# author wrote. TO_JSON of the inflated object must carry every key the
# fixture had: nothing dropped, nothing renamed.
#
# It asserts fixture content, so it opts out of live mode the way every
# content-asserting test in this suite does (skill api-docker-core): none of
# it calls test_docker(), so it never reaches the route table load_fixture()
# reads the JSON straight off disk either way -- but the point under test is
# the shape of these specific captured files, not of whatever a live daemon
# on this machine happens to hold right now.
#
# Inflated through from_data, which is the entry point a daemon response goes
# through: it reads the swagger's wire names and nothing else, so a fixture
# key the model has not heard of keeps its own spelling rather than being
# read as the Perl name of one it has (karr k85).
plan skip_all => 'asserts captured fixture content, not live daemon state'
  if is_live();

# Fixture basename => [ generated class, sub that turns the decoded fixture
# into the list of objects to inflate ]. containers_list/networks_list/
# images_list/secrets_list are bare arrays in the swagger; volumes_list is
# the one wrapper (VolumeListResponse, holding Volumes + Warnings), and
# inflating the wrapper itself exercises the nested Volume objects too.
my @CASES = (
  [ container_inspect => 'API::Docker::Type::ContainerInspectResponse',
    sub { $_[0] } ],
  [ containers_list => 'API::Docker::Type::ContainerSummary',
    sub { @{ $_[0] } } ],
  [ networks_list => 'API::Docker::Type::Network',
    sub { @{ $_[0] } } ],
  [ volumes_list => 'API::Docker::Type::VolumeListResponse',
    sub { $_[0] } ],
  [ system_info => 'API::Docker::Type::SystemInfo',
    sub { $_[0] } ],
  [ system_version => 'API::Docker::Type::SystemVersion',
    sub { $_[0] } ],
  [ images_list => 'API::Docker::Type::ImageSummary',
    sub { @{ $_[0] } } ],
  [ secrets_list => 'API::Docker::Type::Secret',
    sub { @{ $_[0] } } ],
);

for my $case (@CASES) {
  my ($fixture, $class, $items_of) = @$case;
  my $data  = load_fixture($fixture);
  my @items = $items_of->($data);
  cmp_ok scalar(@items), '>=', 1,
    "$fixture: at least one object to round-trip"
    or next;

  for my $i (0 .. $#items) {
    my $item = $items[$i];
    my $obj  = $class->from_data($item);
    my $out  = $obj->TO_JSON;
    my @missing = grep { !exists $out->{$_} } keys %$item;
    is_deeply \@missing, [],
      "$fixture\[$i\]: $class round-trips every key the daemon sent";
  }
}

subtest 'the VirtualSize regression this ticket exists to pin down' => sub {
  # Measured 2026-08-28 (karr k81): VirtualSize is in spec/v1.41.yaml, gone
  # from spec/v1.44.yaml onward -- Docker removed it from the swagger -- and
  # the engine that produced this fixture still sends it. The model forwards
  # it verbatim instead of dropping it; this is the specific case the loop
  # above proves in general but that "tidying" the model by discarding
  # unrecognised fields would break first, so it gets its own assertion
  # rather than staying implicit in the round-trip check.
  my $data = load_fixture('images_list');
  ok scalar(@$data), 'images_list fixture has objects to check'
    or return;

  for my $item (@$data) {
    my $obj = API::Docker::Type::ImageSummary->from_data($item);
    ok exists $obj->unknown_fields->{VirtualSize},
      "$item->{Id}: VirtualSize is not in the model, so it is filed as unknown "
      . 'rather than silently discarded';
    is $obj->TO_JSON->{VirtualSize}, $item->{VirtualSize},
      "$item->{Id}: and reaches TO_JSON unchanged";
  }
};

done_testing;
