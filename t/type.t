use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use API::Docker::Type::HostConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::Port;
use API::Docker::Type::Resources;

# The generated type model: API::Docker::Type's DSL, the attribute registry
# it writes, and serialisation in both directions.
#
# Nothing here opens a socket or reaches a daemon, in either mode -- these
# are pure objects. The values come from spec/v1.51.yaml, which is Docker's
# published swagger checked in verbatim; maint/spec-drift-check.pl is what
# proves a class still matches it, and this file is what proves the three
# invariants the model must never break.

my $json = JSON::MaybeXS->new(canonical => 1);

# ---------------------------------------------------------------------------
# INVARIANT 1: the keys of an additionalProperties field are the caller's
# data and are NEVER translated. Getting this wrong silently rewrites what
# the user typed, and a label is the sort of thing a deployment is keyed on.
# ---------------------------------------------------------------------------

subtest 'caller-data keys survive in both directions' => sub {
  my %labels = (
    'com.example.Some-Label' => 'yes',
    'org.opencontainers.image.source' => 'https://example.invalid/x',
    'UPPER_and_lower'        => '1',
    'a.b.c.d'                => '2',
  );
  my $mount = API::Docker::Type::Mount->from_data({
    Target        => '/data',
    VolumeOptions => { Labels => { %labels } },
  });
  is_deeply($mount->volume_options->labels, { %labels },
    'label keys reach the object exactly as they were written');
  is_deeply($mount->TO_JSON->{VolumeOptions}{Labels}, { %labels },
    'and come back out of TO_JSON unchanged');

  my $hc = API::Docker::Type::HostConfig->from_data({
    Sysctls      => { 'net.ipv4.ip_forward' => '1' },
    StorageOpt   => { size => '120G' },
    Tmpfs        => { '/run' => 'rw,noexec,nosuid,size=65536k' },
    Annotations  => { 'com.example.Some-Label' => 'x' },
    PortBindings => {
      '80/tcp'   => [ { HostIp => '0.0.0.0', HostPort => '8080' } ],
      '53/udp'   => [ { HostIp => '0.0.0.0', HostPort => '53' } ],
      '2377/tcp' => undef,
    },
  });
  my $out = $hc->TO_JSON;
  is_deeply([ sort keys %{ $out->{Sysctls} } ], ['net.ipv4.ip_forward'],
    'a dotted sysctl name is not touched');
  is_deeply([ sort keys %{ $out->{StorageOpt} } ], ['size'],
    'a storage driver option name is not touched');
  is_deeply([ sort keys %{ $out->{Tmpfs} } ], ['/run'],
    'a tmpfs mount path is not touched');
  is_deeply([ sort keys %{ $out->{Annotations} } ], ['com.example.Some-Label'],
    'an annotation name is not touched');
  is_deeply([ sort keys %{ $out->{PortBindings} } ], [ '2377/tcp', '53/udp', '80/tcp' ],
    'port keys keep their <port>/<protocol> form');
  is($out->{PortBindings}{'80/tcp'}[0]{HostPort}, '8080',
    'the values of a caller-keyed hash are still typed and inflated');
  ok(!exists $out->{PortBindings}{port_bindings}
       && !exists $out->{PortBindings}{'80_tcp'},
    'nothing invented a snake_case spelling of a caller key');
};

# ---------------------------------------------------------------------------
# INVARIANT 2: a field the model has never heard of goes through unchanged.
# A caller whose engine is newer than spec/v1.51.yaml must still reach the
# daemon; dropping what we do not recognise would cost this distribution the
# property that a newer engine works on day one.
# ---------------------------------------------------------------------------

subtest 'an unknown field goes in and comes out unchanged' => sub {
  my %newer = (
    FieldFromANewerEngine => 'scalar',
    NestedNewThing        => { a => [ 1, 2, { b => 'c' } ] },
    lowercase_new_thing   => 42,
  );
  my $hc = API::Docker::Type::HostConfig->from_data({ Privileged => JSON->true, %newer });
  is_deeply($hc->unknown_fields, { %newer },
    'everything unrecognised is kept verbatim, under its own name');
  my $out = $hc->TO_JSON;
  is_deeply({ map { ($_ => $out->{$_}) } keys %newer }, { %newer },
    'and is written back out byte for byte');
  is($out->{Privileged}, JSON->true, 'the fields we do know still translate');

  my $round = API::Docker::Type::HostConfig->from_data($out);
  is($json->encode($round->TO_JSON), $json->encode($out),
    'a second pass through the model changes nothing');

  my $unknown_only = API::Docker::Type::Mount->from_data({ Whatever => 1 });
  is_deeply($unknown_only->TO_JSON, { Whatever => 1 },
    'a class that recognises nothing still forwards everything');
};

# ---------------------------------------------------------------------------
# INVARIANT 3: `since` is documentation. Nothing checks it, warns about it
# or drops a field because of it -- we are not the authority on what an
# engine can do (karr k79, decision 2).
# ---------------------------------------------------------------------------

subtest 'since is inert at runtime' => sub {
  my $reg = API::Docker::Type::Mount->docker_attributes;
  is($reg->{image_options}{since}, '1.51',
    'the registry records which spec first carried the field');
  is($reg->{target}{since}, undef,
    'a field already in the oldest spec we hold carries no since');

  my $warned = '';
  local $SIG{__WARN__} = sub { $warned .= $_[0] };
  my $mount = API::Docker::Type::Mount->from_data({
    Target       => '/data',
    ImageOptions => { Subpath => 'dir/sub' },
  });
  is($warned, '', 'setting a field newer than any engine we know warns about nothing');
  is($mount->image_options->subpath, 'dir/sub', 'and the value is kept');
  is_deeply($mount->TO_JSON->{ImageOptions}, { Subpath => 'dir/sub' },
    'and it goes to the daemon; the engine decides, not us');

  my $bind = API::Docker::Type::Mount::BindOptions->new(create_mountpoint => 1);
  is_deeply($bind->TO_JSON, { CreateMountpoint => JSON->true },
    'a 1.44 field on a 1.41 engine is still sent -- Podman serves fields its '
      . 'announced version does not promise, and refuses ones it does');
};

# ---------------------------------------------------------------------------
# The wire name is derived from the Perl name, and the spec's spelling wins
# ---------------------------------------------------------------------------

subtest 'wire names' => sub {
  my $reg = API::Docker::Type::Resources->docker_attributes;
  is($reg->{cpu_shares}{wire},  'CpuShares',  'port_bindings-style derivation');
  is($reg->{nano_cpus}{wire},   'NanoCpus',   'derivation covers most fields');
  is($reg->{oom_kill_disable}{wire}, 'OomKillDisable', 'and multi-word ones');
  is($reg->{kernel_memory_tcp}{wire}, 'KernelMemoryTCP',
    'a spelling the derivation cannot reach is declared explicitly');
  is($reg->{io_maximum_iops}{wire}, 'IOMaximumIOps', 'likewise IOMaximumIOps');
  is($reg->{blkio_device_read_iops}{wire}, 'BlkioDeviceReadIOps',
    'likewise BlkioDeviceReadIOps');
  is(API::Docker::Type::Port->docker_attributes->{ip}{wire}, 'IP',
    'and a two-letter all-caps name');
  is(API::Docker::Type::HostConfig->docker_attributes->{uts_mode}{wire}, 'UTSMode',
    'and UTSMode');

  my $r = API::Docker::Type::Resources->new(
    kernel_memory_tcp => 1024, io_maximum_iops => 7);
  is_deeply($r->TO_JSON, { KernelMemoryTCP => 1024, IOMaximumIOps => 7 },
    'the explicit spelling is what goes on the wire');
  my $back = API::Docker::Type::Resources->from_data({ KernelMemoryTCP => 1024 });
  is($back->kernel_memory_tcp, 1024, 'and what is read back off it');
  is_deeply($back->unknown_fields, {},
    'a wire name the registry knows is never mistaken for an unknown field');
};

# ---------------------------------------------------------------------------
# Booleans: Docker tells an absent flag apart from a false one
# ---------------------------------------------------------------------------

subtest 'booleans' => sub {
  for my $false (JSON->false, \0, 'false', 'FALSE', 0, '') {
    my $m = API::Docker::Type::Mount->new(read_only => $false);
    is($m->TO_JSON->{ReadOnly}, JSON->false,
      'false-ish value ' . (ref $false ? ref $false : "'$false'") . ' serialises to JSON false');
  }
  for my $true (JSON->true, \1, 'true', 1, 'yes') {
    my $m = API::Docker::Type::Mount->new(read_only => $true);
    is($m->TO_JSON->{ReadOnly}, JSON->true,
      'true-ish value ' . (ref $true ? ref $true : "'$true'") . ' serialises to JSON true');
  }
  my $unset = API::Docker::Type::Mount->new(target => '/x');
  ok(!exists $unset->TO_JSON->{ReadOnly},
    'a Bool that was never set is absent, not false');
  my $explicit = API::Docker::Type::Mount->new(target => '/x', read_only => 0);
  ok(exists $explicit->TO_JSON->{ReadOnly},
    'a Bool explicitly set to false is present and false');
  is($json->encode($explicit->TO_JSON), '{"ReadOnly":false,"Target":"/x"}',
    'and encodes as JSON false, never as 1 or the empty string');
  like(
    do { local $@; eval { API::Docker::Type::Mount->new(read_only => [1]) }; $@ },
    qr/Bool wants a scalar/,
    'something that cannot mean true or false croaks instead of being guessed at');
};

# ---------------------------------------------------------------------------
# Nesting, arrays of objects, and the allOf inheritance
# ---------------------------------------------------------------------------

subtest 'nested objects and arrays' => sub {
  my $hc = API::Docker::Type::HostConfig->from_data({
    RestartPolicy       => { Name => 'on-failure', MaximumRetryCount => 3 },
    LogConfig           => { Type => 'json-file', Config => { 'max-size' => '10m' } },
    Mounts              => [ { Target => '/data', Type => 'volume' } ],
    Ulimits             => [ { Name => 'nofile', Soft => 1024, Hard => 2048 } ],
    BlkioDeviceReadIOps => [ { Path => '/dev/sda', Rate => 100 } ],
    Devices             => [ { PathOnHost => '/dev/x', PathInContainer => '/dev/x' } ],
    ConsoleSize         => [ 80, 64 ],
  });
  isa_ok($hc->restart_policy, 'API::Docker::Type::RestartPolicy');
  isa_ok($hc->log_config,     'API::Docker::Type::HostConfig::LogConfig');
  isa_ok($hc->mounts->[0],    'API::Docker::Type::Mount');
  isa_ok($hc->ulimits->[0],   'API::Docker::Type::Resources::Ulimit');
  isa_ok($hc->blkio_device_read_iops->[0], 'API::Docker::Type::ThrottleDevice');
  isa_ok($hc->devices->[0],   'API::Docker::Type::DeviceMapping');
  is($hc->ulimits->[0]->soft, 1024, 'an inline array element inflates');
  is_deeply($hc->console_size, [ 80, 64 ], 'an array of scalars stays an array of scalars');

  my $mount = API::Docker::Type::Mount->from_data({
    TmpfsOptions => { Options => [ ['noexec'], [ 'size', '64m' ] ] },
  });
  is_deeply($mount->tmpfs_options->options, [ ['noexec'], [ 'size', '64m' ] ],
    'an array of arrays of strings survives');

  my $built = API::Docker::Type::HostConfig->new(
    restart_policy => API::Docker::Type::RestartPolicy->new(name => 'always'),
  );
  is_deeply($built->TO_JSON, { RestartPolicy => { Name => 'always' } },
    'an object built by hand serialises the same way an inflated one does');
};

subtest 'allOf becomes inheritance' => sub {
  ok(API::Docker::Type::HostConfig->isa('API::Docker::Type::Resources'),
    'HostConfig is a Resources, because the swagger says allOf [ $ref Resources, ... ]');
  my $order = API::Docker::Type::HostConfig->docker_attribute_order;
  is(scalar @$order, 70, 'HostConfig carries 31 inherited plus 39 of its own');
  is($order->[0], 'cpu_shares', 'the inherited fields come first, as the allOf lists them');
  is($order->[31], 'binds', 'and the class own fields follow in spec order');
  my $hc = API::Docker::Type::HostConfig->from_data({ CpuShares => 512, Binds => ['/a:/b'] });
  is($hc->cpu_shares, 512, 'an inherited field inflates on the child');
  is_deeply($hc->TO_JSON, { CpuShares => 512, Binds => ['/a:/b'] },
    'and serialises flat, the way it sits on the wire');
  is(scalar @{ API::Docker::Type::Resources->docker_attribute_order }, 31,
    'the parent is unaffected by the child');
};

# ---------------------------------------------------------------------------
# Both spellings, and what the DSL refuses
# ---------------------------------------------------------------------------

subtest 'constructor accepts both spellings' => sub {
  my $a = API::Docker::Type::Port->new(private_port => 80, type => 'tcp');
  my $b = API::Docker::Type::Port->from_data({ PrivatePort => 80, Type => 'tcp' });
  is($json->encode($a->TO_JSON), $json->encode($b->TO_JSON),
    'a Perl name and a wire name reach the same attribute');
  is_deeply($a->unknown_fields, {}, 'and neither is filed as unknown');
  like(
    do { local $@; eval { API::Docker::Type::Port->from_data([]) }; $@ },
    qr/needs a HashRef/, 'from_data refuses anything but a hashref');
};

subtest 'the registry is what the drift checker reads' => sub {
  my $reg = API::Docker::Type::HostConfig->docker_attributes;
  is(API::Docker::Type::describe_type($reg->{port_bindings}{type}),
    'hash<array<object<API::Docker::Type::PortBinding>>>',
    'a PortMap is a hash of arrays of typed objects');
  is(API::Docker::Type::describe_type($reg->{binds}{type}), 'array<str>',
    'and Binds an array of strings');
  is(API::Docker::Type::describe_type($reg->{privileged}{type}), 'bool');
  is(API::Docker::Type::describe_type($reg->{log_config}{type}),
    'object<API::Docker::Type::HostConfig::LogConfig>',
    'an inline schema is a class named after the definition declaring it');
  is($reg->{port_bindings}{required}, 0, 'required is recorded');
  is(API::Docker::Type::Port->docker_attributes->{private_port}{required}, 1,
    'including where the spec sets it');
  is_deeply(API::Docker::Type::Mount->docker_attributes->{type}{enum},
    [qw( bind cluster image npipe tmpfs volume )],
    'and an enumeration, for the POD to state');
};

done_testing;
