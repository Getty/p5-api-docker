use strict;
use warnings;
use Test::More;
use MIME::Base64 qw( decode_base64 );
use lib 't/lib';
use Test::API::Docker::Mock;

check_live_access();

# Most of what this file asserts is the shape of the *outgoing* request --
# that Data leaves as base64 and that Version.Index leaves as the `version`
# query parameter. Neither is visible from a response, so those subtests are
# mock-only and say so rather than passing vacuously against a daemon.
my $REQUEST_SHAPE = 'asserts the outgoing request; only the mock can see it';

# The Engine API reference's shape for a config, kept inline instead of in
# t/fixtures/: the files there are captured from a real daemon, and no engine
# reachable from this repo serves /configs. Podman answers 404 with a
# plain-text "Not Found" to every path under it (measured, 5.4.2 / API 1.41)
# and there is no Docker on this machine, so a configs_list.json would be a
# hand-rolled file dressed up as a capture.
my $CONFIG = {
  ID        => 'ktnbjxoalbkvbvedmg1urrz8h',
  Version   => { Index => 11 },
  CreatedAt => '2016-11-05T01:20:17.327670065Z',
  UpdatedAt => '2016-11-05T01:20:17.327670065Z',
  Spec      => {
    Name   => 'server.conf',
    Labels => { 'com.example.some-label' => 'some-value' },
    Data   => 'bGlzdGVuIDgwODA7Cg==',
  },
};

# --- Read paths -------------------------------------------------------------

subtest 'secrets list' => sub {
  my $docker  = test_docker('GET /secrets' => load_fixture('secrets_list'));
  my $secrets = $docker->secrets->list;

  is(ref $secrets, 'ARRAY', 'list returns an ArrayRef');
  return if is_live();

  is(scalar @$secrets, 2, 'two secrets in the fixture');
  is(ref $secrets->[0], 'HASH',
    'entries are the daemon hashrefs -- there is no API::Docker::Secret to wrap them in');
  is($secrets->[0]{Spec}{Name}, 'db-password', 'first secret name');
  is($secrets->[0]{Version}{Index}, 1, 'carries the Version.Index that update needs');
  ok(!exists $secrets->[0]{Spec}{Data}, 'a secret never comes back with its value');
  is($secrets->[1]{Spec}{Labels}, undef,
    'Podman sends Labels: null for an empty label set, and it is passed through as undef');
};

subtest 'secrets list forwards filters as a HashRef' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $params;
  my $docker = test_docker('GET /secrets' => sub {
    my ($method, $path, %opts) = @_;
    $params = $opts{params};
    return [];
  });

  $docker->secrets->list(filters => { label => ['env=prod'] });

  is_deeply($params->{filters}, { label => ['env=prod'] },
    'filters reach the transport as a HashRef -- encoding them here would double-encode');
};

subtest 'secrets list without filters sends no filters parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $params;
  my $docker = test_docker('GET /secrets' => sub {
    my ($method, $path, %opts) = @_;
    $params = $opts{params};
    return [];
  });

  $docker->secrets->list;
  is_deeply($params, {}, 'no filters key invented');
};

subtest 'secrets inspect' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $docker = test_docker(
    'GET /secrets/db-password' => load_fixture('secrets_list')->[0],
  );

  my $secret = $docker->secrets->inspect('db-password');
  is($secret->{Spec}{Name}, 'db-password', 'inspect returns the daemon hashref');
  is($secret->{Version}{Index}, 1, 'with the Version.Index');
};

# --- create: the base64 contract --------------------------------------------

subtest 'secrets create encodes Data for the caller' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/create' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return { ID => 'abc123' };
  });

  my $created = $docker->secrets->create(
    Name   => 'db-password',
    Data   => "hunter2\n",
    Labels => { env => 'prod' },
  );

  is($created->{ID}, 'abc123', 'returns the daemon response unwrapped');
  is($body->{Name}, 'db-password', 'Name goes out untouched');
  is_deeply($body->{Labels}, { env => 'prod' }, 'Labels go out untouched');

  isnt($body->{Data}, "hunter2\n",
    'the raw bytes are not what goes on the wire -- the daemon would store garbage and answer 200');
  is($body->{Data}, 'aHVudGVyMgo=', 'Data is base64 of exactly what the caller passed');
  is(decode_base64($body->{Data}), "hunter2\n", 'and decodes back to it');
};

subtest 'secrets create uses the alphabet the engine accepts' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/create' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return { ID => 'abc123' };
  });

  # Measured: the engine takes +v/++w== for these four bytes and rejects the
  # URL-safe -v_--w== with 500, despite the reference calling the field
  # "base64-url-safe-encoded".
  $docker->secrets->create(Name => 'bytes', Data => "\xfa\xff\xfe\xfb");
  is($body->{Data}, '+v/++w==', 'standard base64 alphabet, + and / rather than - and _');

  # encode_base64 wraps at 76 characters unless told otherwise, and a wrapped
  # value is a JSON string with newlines in it that the engine will not decode.
  my $long = 'x' x 300;
  $docker->secrets->create(Name => 'big', Data => $long);
  unlike($body->{Data}, qr/\n/, '300 bytes of Data goes out unwrapped');
  is(decode_base64($body->{Data}), $long, 'and still round-trips');
};

subtest 'secrets create validates before it opens a socket' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker('POST /secrets/create' => sub { $requests++; return { ID => 'x' } });

  eval { $docker->secrets->create(Data => "x") };
  like($@, qr/Name required/, 'a missing Name croaks');

  eval { $docker->secrets->create(Name => 'n') };
  like($@, qr/Data required/, 'a missing Data croaks');

  eval { $docker->secrets->create(Name => 'n', Data => '') };
  like($@, qr/Data required/, 'an empty Data croaks -- the engine rejects it with 500 anyway');

  eval { $docker->secrets->create(Name => 'n', Data => "\x{263A}") };
  like($@, qr/must be a byte string/,
    'decoded characters croak here instead of dying inside MIME::Base64');

  is($requests, 0, 'none of them reached the daemon');
};

# --- update: the version query parameter ------------------------------------

subtest 'secrets update sends Version.Index as the version parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($path, $params, $body);
  my $docker = test_docker(
    'GET /secrets/db-password'         => load_fixture('secrets_list')->[0],
    'POST /secrets/db-password/update' => sub {
      my ($method, $req_path, %opts) = @_;
      ($path, $params, $body) = ($req_path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $secret = $docker->secrets->inspect('db-password');
  is($secret->{Version}{Index}, 1, 'the version the caller is meant to pass comes from inspect');

  my %spec = %{ $secret->{Spec} };
  $spec{Labels} = { env => 'staging' };
  my $result = $docker->secrets->update('db-password', $secret->{Version}{Index}, %spec);

  is($path, '/secrets/db-password/update', 'update posts to the right path');
  is_deeply($params, { version => 1 },
    'Version.Index rides in the version query parameter, and it is the only parameter');
  is_deeply($body->{Labels}, { env => 'staging' }, 'the spec is the request body');
  is($body->{Name}, 'db-password', 'the rest of the spec goes back unchanged');
  ok(!exists $body->{version}, 'version is not also smuggled into the body');
  is($result, undef, 'update returns nothing -- the daemon answers with an empty body');
};

subtest 'secrets update will not go out without a usable version' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /secrets/db-password/update' => sub { $requests++; return undef },
  );

  eval { $docker->secrets->update('db-password', undef, Labels => {}) };
  my $missing = $@;
  like($missing, qr/version/, 'a missing version croaks about the version');
  like($missing, qr/Version\.Index/, 'and names the field it comes from');
  like($missing, qr/inspect/, 'and the call that produces it');

  eval { $docker->secrets->update('db-password', 'latest', Labels => {}) };
  like($@, qr/must be the numeric Version\.Index/, 'a non-numeric version croaks');

  eval { $docker->secrets->update(undef, 1, Labels => {}) };
  like($@, qr/ID or name required/, 'a missing id croaks');

  is($requests, 0,
    'the guard is client-side: no request was made for any of them');
};

subtest 'secrets update encodes a Data it is given' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker('POST /secrets/s/update' => sub {
    my ($method, $path, %opts) = @_;
    $body = $opts{body};
    return undef;
  });

  $docker->secrets->update('s', 7, Name => 's', Data => "hunter2\n");
  is($body->{Data}, 'aHVudGVyMgo=', 'Data is encoded on update just as on create');

  $docker->secrets->update('s', 7, Name => 's', Labels => { a => 'b' });
  ok(!exists $body->{Data}, 'and no Data key is invented when none was passed');
};

subtest 'secrets remove' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $method_seen;
  my $docker = test_docker('DELETE /secrets/db-password' => sub {
    my ($method) = @_;
    $method_seen = $method;
    return undef;
  });

  my $result = $docker->secrets->remove('db-password');
  is($method_seen, 'DELETE', 'remove uses DELETE');
  is($result, undef, 'and returns nothing -- the daemon answers 204');

  eval { $docker->secrets->remove('') };
  like($@, qr/ID or name required/, 'an empty id croaks');
};

# --- configs: the same five endpoints, one different return -----------------
#
# Podman serves no /configs at all, so none of this can run live.

subtest 'configs list' => sub {
  plan skip_all => 'Podman serves no /configs route (404 Not Found on every path)'
    if is_live();

  my $docker  = test_docker('GET /configs' => [$CONFIG]);
  my $configs = $docker->configs->list;

  is(ref $configs, 'ARRAY', 'list returns an ArrayRef');
  is($configs->[0]{Spec}{Name}, 'server.conf', 'config name');
  is($configs->[0]{Version}{Index}, 11, 'carries Version.Index');
};

subtest 'configs create encodes Data, inspect does not decode it' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $body;
  my $docker = test_docker(
    'POST /configs/create'      => sub {
      my ($method, $path, %opts) = @_;
      $body = $opts{body};
      return { ID => 'ktnbjxoalbkvbvedmg1urrz8h' };
    },
    'GET /configs/server.conf'  => $CONFIG,
  );

  $docker->configs->create(Name => 'server.conf', Data => "listen 8080;\n");
  is($body->{Data}, 'bGlzdGVuIDgwODA7Cg==', 'Data goes out base64, like secrets');
  is(decode_base64($body->{Data}), "listen 8080;\n", 'round-trips');

  my $config = $docker->configs->inspect('server.conf');
  is($config->{Spec}{Data}, 'bGlzdGVuIDgwODA7Cg==',
    'inspect hands back the daemon response untouched -- Spec.Data stays base64');
  is(decode_base64($config->{Spec}{Data}), "listen 8080;\n",
    'so the caller decodes it, which is visible rather than silent');
};

subtest 'configs update sends Version.Index as the version parameter' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my ($path, $params, $body);
  my $docker = test_docker(
    'GET /configs/server.conf'         => $CONFIG,
    'POST /configs/server.conf/update' => sub {
      my ($method, $req_path, %opts) = @_;
      ($path, $params, $body) = ($req_path, $opts{params}, $opts{body});
      return undef;
    },
  );

  my $config = $docker->configs->inspect('server.conf');
  my %spec   = %{ $config->{Spec} };
  delete $spec{Data};                        # already base64 -- see the POD
  $spec{Labels} = { 'com.example.some-label' => 'other-value' };

  $docker->configs->update('server.conf', $config->{Version}{Index}, %spec);

  is($path, '/configs/server.conf/update', 'update posts to the right path');
  is_deeply($params, { version => 11 },
    'Version.Index rides in the version query parameter, and it is the only parameter');
  is_deeply($body->{Labels}, { 'com.example.some-label' => 'other-value' },
    'the spec is the request body');
};

subtest 'configs update will not go out without a usable version' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /configs/server.conf/update' => sub { $requests++; return undef },
  );

  eval { $docker->configs->update('server.conf', undef, Labels => {}) };
  like($@, qr/Version\.Index/, 'a missing version croaks naming where the value comes from');

  eval { $docker->configs->update('server.conf', '11.0', Labels => {}) };
  like($@, qr/must be the numeric Version\.Index/, 'a non-integer version croaks');

  is($requests, 0, 'the guard is client-side: nothing reached the daemon');
};

subtest 'configs create validates and configs remove' => sub {
  plan skip_all => $REQUEST_SHAPE if is_live();

  my $requests = 0;
  my $docker = test_docker(
    'POST /configs/create'     => sub { $requests++; return { ID => 'x' } },
    'DELETE /configs/server.conf' => undef,
  );

  eval { $docker->configs->create(Data => 'x') };
  like($@, qr/Name required/, 'a missing Name croaks');

  eval { $docker->configs->create(Name => 'n') };
  like($@, qr/Data required/, 'a missing Data croaks');

  is($requests, 0, 'neither reached the daemon');
  is($docker->configs->remove('server.conf'), undef, 'remove returns nothing');
};

# --- the swarm decision is documented, not merely absent ---------------------

subtest 'the excluded Swarm endpoints are named as a decision in the POD' => sub {
  require API::Docker;
  my $pod = do {
    open my $fh, '<', $INC{'API/Docker.pm'} or die "$INC{'API/Docker.pm'}: $!";
    local $/;
    <$fh>;
  };

  like($pod, qr/Swarm orchestration is out of scope/,
    'API::Docker says so under its own heading');
  like($pod, qr{C</swarm>.*C</nodes>.*C</services>.*C</tasks>}s,
    'and names all four excluded endpoint groups');

  # Matched by paragraph rather than by directive: under `dzil test` this file
  # has already been through PodWeaver, which turns `=attr secrets` into
  # `=head2 secrets`. The prose is what the reader gets either way.
  #
  # Only these two paragraphs are this ticket's -- the other =attr entries are
  # still scaffolding, and other agents own them.
  my @paragraphs = split /\n\n/, $pod;
  for my $class (qw( Secrets Configs )) {
    my ($para) = grep { /L<API::Docker::API::$class> instance/ } @paragraphs;
    ok($para, "API::Docker documents its $class accessor");
    unlike($para, qr/Scaffolding/, "and no longer calls $class scaffolding");
    like($para, qr/C<update>/, "and names the methods it now has");
  }
};

done_testing;
