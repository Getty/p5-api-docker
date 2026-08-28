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
# karr k93: at every depth, and with one named exception. The comparison used
# to be `keys %$item` -- the top level of each object only -- which is why the
# two nulls the fixtures actually contain sat unexamined below it. A known
# field an engine sent as an explicit null is read as unset and loses its key,
# because the daemon cannot tell an explicit null from an absent field in
# either direction (measured, see API::Docker::Role::Type/"A null on a known
# field is read as unset"). That is correct behaviour, so this test names it
# and asserts it rather than exempting it quietly.
#
# It asserts fixture content, so it opts out of live mode the way every
# content-asserting test in this suite does (skill api-docker-core): none of
# it calls test_docker(), so it never reaches the route table load_fixture()
# reads the JSON straight off disk either way -- but the point under test is
# the shape of these specific captured files, not of whatever a live daemon
# happens to hold right now.
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

# The whole list of keys the round trip is allowed to lose, written out here
# rather than derived from what the run happens to produce -- a set the test
# computes from the model is a set the test cannot be wrong about. Both are
# a known field the engine sent as null: Network's IPAM.Options and
# SecretSpec's Labels. The assertion at the end is is_deeply against this,
# so a third one appearing is red, and so is one of these two ceasing to
# drop -- which is what changing the null rule would look like.
my @EXPECTED_NULL_DROPS = (
  'networks_list[0]/IPAM/Options',
  'secrets_list[1]/Spec/Labels',
);

# --- the comparison ---------------------------------------------------------
#
# Walks the fixture and TO_JSON's output together and reports every fixture
# key that has no counterpart in the output. "Governance" travels down with
# the walk: at each node it says which generated class -- if any -- owns the
# keys of the hash sitting there, because the null exemption applies to a
# field that class KNOWS and to nothing else. Three shapes, taken from the
# registry's own type descriptors:
#
#   object  keys are the fields of a generated class
#   map     keys are the caller's data (the additionalProperties shape), so
#           no key of it is ever a known field, and the values are governed
#           by the inner descriptor
#   array   every element is governed by the inner descriptor
#
# undef governance is a subtree the model does not model -- the value of an
# unknown field, or of a map of scalars. Nothing there is a known field, so
# nothing there may be lost, which is the asymmetry under test.

my %WIRE_INDEX;

sub wire_index {
  my ($class) = @_;
  return $WIRE_INDEX{$class} ||= do {
    my $reg = $class->docker_attributes;
    +{ map { ($reg->{$_}{wire} => $_) } keys %$reg };
  };
}

sub gov_of_descriptor {
  my ($d) = @_;
  return undef unless $d;
  return { kind => 'object', class => $d->{class} } if $d->{kind} eq 'object';
  return { kind => 'array', inner => gov_of_descriptor($d->{inner}) }
    if $d->{kind} eq 'array';
  return { kind => 'map', inner => gov_of_descriptor($d->{inner}) }
    if $d->{kind} eq 'hash';
  return undef;
}

sub gov_of_field {
  my ($gov, $key) = @_;
  return $gov->{inner} if $gov && $gov->{kind} eq 'map';
  return undef unless $gov && $gov->{kind} eq 'object';
  my $attr = wire_index($gov->{class})->{$key};
  return undef unless defined $attr;
  return gov_of_descriptor($gov->{class}->docker_attributes->{$attr}{type});
}

# Returns two lists: keys that went missing, and keys that went missing under
# the null rule. The second is returned rather than swallowed so the caller
# has to say out loud which drops it expects.
sub compare {
  my ($data, $out, $gov, $path, $lost, $nulled) = @_;
  if (ref $data eq 'HASH') {
    unless (ref $out eq 'HASH') {
      push @$lost, "$path (an object came back as " . (ref($out) || 'a plain value') . ')';
      return;
    }
    my $known = $gov && $gov->{kind} eq 'object' ? wire_index($gov->{class}) : {};
    for my $key (sort keys %$data) {
      unless (exists $out->{$key}) {
        # The one exemption, and only where the model really does know the
        # field: a null under a caller's own key, or under a name the model
        # never heard of, has no zero value we could read it as and must
        # survive like any other value.
        if (!defined $data->{$key} && $known->{$key}) {
          push @$nulled, "$path/$key";
          next;
        }
        push @$lost, "$path/$key";
        next;
      }
      compare($data->{$key}, $out->{$key}, gov_of_field($gov, $key),
        "$path/$key", $lost, $nulled);
    }
    return;
  }
  if (ref $data eq 'ARRAY') {
    unless (ref $out eq 'ARRAY') {
      push @$lost, "$path (an array came back as " . (ref($out) || 'a plain value') . ')';
      return;
    }
    my $inner = $gov && $gov->{kind} eq 'array' ? $gov->{inner} : undef;
    compare($data->[$_], $out->[$_], $inner, $path . '[' . $_ . ']', $lost, $nulled)
      for 0 .. $#$data;
    return;
  }
  return;
}

my @NULLED;

for my $case (@CASES) {
  my ($fixture, $class, $items_of) = @$case;
  my $data  = load_fixture($fixture);
  my @items = $items_of->($data);
  cmp_ok scalar(@items), '>=', 1,
    "$fixture: at least one object to round-trip"
    or next;

  for my $i (0 .. $#items) {
    my $item = $items[$i];
    my $out  = $class->from_data($item)->TO_JSON;
    my (@lost, @nulled);
    compare($item, $out, { kind => 'object', class => $class },
      "$fixture\[$i\]", \@lost, \@nulled);
    is_deeply \@lost, [],
      "$fixture\[$i\]: $class round-trips every key the daemon sent, "
      . 'at every depth';
    push @NULLED, @nulled;
  }
}

is_deeply [ sort @NULLED ], [ sort @EXPECTED_NULL_DROPS ],
  'the only keys the fixtures lose are the two known fields the engine sent '
  . 'as an explicit null, and both of them do lose theirs';

subtest 'the null rule, stated rather than exempted' => sub {
  # The rule the loop above encodes, measured directly on one object so that
  # the three shapes sit side by side. Measured 2026-08-28 against Podman
  # 5.8.4 (API 1.44): POST /containers/create answers {}, {"Image":null} and
  # {"Image":""} with byte-identical errors, so the daemon cannot tell an
  # explicit null from an absent field -- collapsing the two costs no
  # meaning. What we cannot type, we cannot collapse (karr k93).
  my $n = API::Docker::Type::Network->from_data({
    Name    => 'n',
    Options => { 'com.docker.x' => undef },
    IPAM    => { Driver => 'default', Options => undef, FutureNested => undef },
  });
  my $out = $n->TO_JSON;

  ok !exists $out->{IPAM}{Options},
    'a known field sent as null is read as unset, and its key does not come back';
  is $n->ipam->options, undef, 'the attribute is simply unset';
  is_deeply $n->ipam->unknown_fields, { FutureNested => undef },
    'it is not filed as unknown either -- only the field we cannot type is';
  is_deeply $n->ipam->rejected_fields, {},
    'and not as rejected: a null is not a value that failed to fit';

  ok exists $out->{IPAM}{FutureNested},
    'a field the model does not know keeps its null: with no declared type '
    . 'there is no zero value to read it as';
  is $out->{IPAM}{FutureNested}, undef, 'and the null itself is what comes back';

  ok exists $out->{Options}{'com.docker.x'},
    "a null under a key the caller chose is that caller's value and stays";
  is $out->{Options}{'com.docker.x'}, undef, 'null and all';
};

subtest 'the deepened comparison sees what the flat one could not' => sub {
  # What this test could not do before k93, shown rather than asserted: a
  # nested key going missing for a reason the null rule does not cover. The
  # real fixture and its real TO_JSON output are used, and one nested key --
  # IPAM/Driver, a plain string, so nothing about it is a null -- is removed
  # from the output to stand in for a regression that dropped it.
  my $item = load_fixture('networks_list')->[0];
  my $out  = API::Docker::Type::Network->from_data($item)->TO_JSON;
  is $item->{IPAM}{Driver}, 'default',
    'the key about to be removed is a plain string, not a null';

  my %broken = %$out;
  $broken{IPAM} = { %{ $out->{IPAM} } };
  delete $broken{IPAM}{Driver};

  my (@lost, @nulled);
  compare($item, \%broken, { kind => 'object', class => 'API::Docker::Type::Network' },
    'networks_list[0]', \@lost, \@nulled);
  is_deeply \@lost, ['networks_list[0]/IPAM/Driver'],
    'the deepened comparison reports the lost nested key';
  is_deeply \@nulled, ['networks_list[0]/IPAM/Options'],
    'and still counts the nested null as the documented exemption, not as a loss';

  # The comparison this file used to make, on the same broken output.
  my @flat = grep { !exists $broken{$_} } keys %$item;
  is_deeply \@flat, [],
    'while comparing top-level keys only finds nothing at all -- which is '
    . 'why the two fixture nulls went unexamined for as long as they did';
};

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
