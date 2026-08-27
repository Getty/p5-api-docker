use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 );
use API::Docker;

# Nothing here opens a socket or reaches a daemon, and nothing here is gated
# on is_live().
#
# Test::API::Docker::Mock is deliberately not used: under
# API_DOCKER_TEST_HOST it ignores its route table and hands back a real
# client, and the only engine this repo can reach is Podman, which serves
# none of /plugins -- measured, 2026-08-27, rootless Podman 5.4.2 (API 1.41):
# GET /v1.41/plugins answers 404 with
# {"cause":"","message":"Path /v1.41/plugins is not supported","response":0}
# and every other path in the family answers a bare text/plain 404, i.e. the
# compat layer has no route for them at all. A live run of this file would
# therefore be red, and a skip_all would leave the whole class untested on
# the machine that actually runs the suite.
#
# So the daemon is faked below the socket instead, in both modes. Most of
# what is worth pinning about this endpoint family is in the request rather
# than the response -- a privilege list in a POST body, a query parameter
# that must not be omitted, a path that must not be escaped -- and that is
# what these assertions read.
#
# The canned responses are the Engine API reference's own example payloads,
# not daemon captures, which is why they are inline rather than in
# t/fixtures: a hand-rolled file there would claim a provenance it does not
# have.

# ---------------------------------------------------------------------------
# A client whose socket is an in-memory sink and whose response is canned, so
# _request assembles a real request line, query string, headers and body with
# nothing on the other end. Same pattern as t/role_http.t.
package Test::Plugins::FakeTransport;
use Moo;
extends 'API::Docker';

has canned => (is => 'rw', default => sub { [200, 'OK', {}, ''] });
has _sink  => (is => 'rw');

sub _build__socket {
  my ($self) = @_;
  my $sink = '';
  $self->_sink(\$sink);
  open my $fh, '>', \$sink or die "open: $!";
  return $fh;
}

sub _read_response { return $_[0]->canned }

sub written { return ${ $_[0]->_sink } }

package main;

sub fake_client {
  my ($body, $status) = @_;
  return Test::Plugins::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'OK', {}, $body // ''],
  );
}

sub request_line {
  my ($raw) = @_;
  my ($line) = $raw =~ /\A([^\r\n]*)/;
  return $line;
}

sub request_body {
  my ($raw) = @_;
  my ($body) = $raw =~ /\r\n\r\n(.*)\z/s;
  return $body;
}

sub query_param {
  my ($raw, $name) = @_;
  my ($qs) = request_line($raw) =~ /\?([^ ]*) HTTP/;
  return undef unless defined $qs;
  for my $pair (split /&/, $qs) {
    my ($k, $v) = split /=/, $pair, 2;
    next unless $k eq $name;
    $v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    return $v;
  }
  return undef;
}

sub b64url_decode {
  my ($s) = @_;
  $s =~ tr{-_}{+/};
  return decode_base64($s);
}

# The two example privilege sets below are the ones the Engine API reference
# ships for PluginPrivilege.
my $PRIVILEGES = [
  { Name => 'network', Description => '', Value => ['host'] },
  { Name => 'mount',   Description => '', Value => ['/data'] },
];

# ---------------------------------------------------------------------------
subtest 'list: filters are JSON-encoded, and the filter name is "enabled"' => sub {
  my $c = fake_client('[]');
  $c->plugins->list(filters => { enabled => ['true'] });

  like request_line($c->written), qr{\AGET /v1\.41/plugins\?}, 'GET /plugins';
  is_deeply decode_json(query_param($c->written, 'filters')),
    { enabled => ['true'] },
    'the filters HashRef reaches the wire as a JSON map of string to array '
    . 'of string';

  # Not "enable". The Engine API reference documents that spelling, but the
  # daemon validates plugin filter names against {enabled, capability} and
  # refuses an unknown one outright, so copying the reference is a hard
  # error rather than a silently empty list.
  like query_param($c->written, 'filters'), qr/"enabled"/,
    'the name sent is enabled, not enable';
};

subtest 'list: no filters means no query string' => sub {
  my $c = fake_client('[]');
  $c->plugins->list;
  is request_line($c->written), 'GET /v1.41/plugins HTTP/1.1',
    'an empty params hash appends nothing';
};

# ---------------------------------------------------------------------------
subtest 'the plugin name reaches the path unescaped' => sub {
  my $c = fake_client('{"Name":"docker.io/vieux/sshfs:latest"}');
  $c->plugins->inspect('docker.io/vieux/sshfs:latest');

  is request_line($c->written),
    'GET /v1.41/plugins/docker.io/vieux/sshfs:latest/json HTTP/1.1',
    'registry host, repository slashes and the tag colon all survive raw';

  # The daemon routes this family as /plugins/{name:.*}/json, so the slashes
  # are part of the captured name and percent-encoding them would not match.
  unlike $c->written, qr/%2F|%3A/i, 'nothing in the name got percent-encoded';
};

subtest 'remove: force is normalised to 1/0 and omitted when unset' => sub {
  my $c = fake_client('');
  $c->plugins->remove('vieux/sshfs:latest');
  is request_line($c->written),
    'DELETE /v1.41/plugins/vieux/sshfs:latest HTTP/1.1',
    'no force parameter when the caller passed none';

  $c->plugins->remove('vieux/sshfs:latest', force => 1);
  is query_param($c->written, 'force'), '1', 'force => 1';

  $c->plugins->remove('vieux/sshfs:latest', force => 0);
  is query_param($c->written, 'force'), '0',
    'an explicit false is still sent, as 0';
};

# ---------------------------------------------------------------------------
subtest 'enable: timeout is always sent' => sub {
  my $c = fake_client('');
  $c->plugins->enable('vieux/sshfs:latest');

  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/enable?timeout=0 HTTP/1.1',
    'timeout=0 is sent even though the caller passed no timeout';

  # This is not tidiness. The daemon reads the raw query value and parses it
  # with Go's strconv.Atoi, with no default: an absent timeout is parsed as
  # the empty string and the request fails with
  # `strconv.Atoi: parsing "": invalid syntax`. Making this parameter
  # conditional, the way force and filters are, would break every enable.
  $c->plugins->enable('vieux/sshfs:latest', timeout => 30);
  is query_param($c->written, 'timeout'), '30', 'an explicit timeout is used';

  $c->plugins->enable('vieux/sshfs:latest', timeout => 0);
  is query_param($c->written, 'timeout'), '0', 'an explicit 0 stays 0';
};

subtest 'disable: force is optional' => sub {
  my $c = fake_client('');
  $c->plugins->disable('vieux/sshfs:latest');
  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/disable HTTP/1.1',
    'no force parameter by default';

  $c->plugins->disable('vieux/sshfs:latest', force => 1);
  is query_param($c->written, 'force'), '1', 'force => 1';
};

# ---------------------------------------------------------------------------
subtest 'privileges: remote in the query, list in the response' => sub {
  my $c = fake_client(JSON::MaybeXS->new->encode($PRIVILEGES));
  my $got = $c->plugins->privileges('vieux/sshfs');

  is request_line($c->written),
    'GET /v1.41/plugins/privileges?remote=vieux/sshfs HTTP/1.1',
    'remote is a query parameter, and its slash is not escaped';
  is_deeply $got, $PRIVILEGES, 'the privilege list comes back as an ArrayRef';
  unlike $c->written, qr/X-Registry-Auth/i,
    'no auth header without auth: the plugin router discards an '
    . 'undecodable one, so anonymous needs none';
};

subtest 'privileges: a plugin that demands nothing answers null' => sub {
  # computePrivileges starts from `var privileges types.PluginPrivileges` and
  # appends only what the config asks for, so a plugin needing nothing sends
  # a nil Go slice, which marshals to a bare `null`.
  my $c = fake_client('null');

  # karr #30 (fixed): the transport used to decode a body only when it
  # started with { or [, so a bare JSON scalar came back as its own bytes --
  # the four-character string 'null'. It now decodes any JSON body, scalars
  # included, so this comes back as undef, same as decode_json('null') would.
  is $c->get('/plugins/privileges', params => { remote => 'x' }), undef,
    'the transport decodes the bare null to undef (karr #30)';

  # Unguarded, that undef would be POSTed to /plugins/pull as a JSON null
  # where the engine expects an array.
  is_deeply $c->plugins->privileges('vieux/sshfs'), [],
    'privileges normalises it to the empty list it means';
};

subtest 'privileges: auth is sent as padded base64url X-Registry-Auth' => sub {
  my $c = fake_client('[]');
  $c->plugins->privileges('private.example.com/p/sshfs',
    auth => { username => 'me', password => 'secret' });

  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  ok defined $hdr, 'header present when auth was given';
  is length($hdr) % 4, 0, 'padded, as Go base64.URLEncoding requires';
  is_deeply decode_json(b64url_decode($hdr)),
    { username => 'me', password => 'secret' },
    'header decodes to the credentials passed';
};

# ---------------------------------------------------------------------------
subtest 'install: the privilege list is the request body' => sub {
  my $c = fake_client(qq({"status":"Pulling plugin"}\n));
  my $events = $c->plugins->install('vieux/sshfs:latest',
    privileges => $PRIVILEGES);

  like request_line($c->written), qr{\APOST /v1\.41/plugins/pull\?},
    'install is POST /plugins/pull';
  is query_param($c->written, 'remote'), 'vieux/sshfs:latest',
    'remote is a query parameter';
  like $c->written, qr{^Content-Type: application/json\r$}m,
    'the body is JSON, not a tarball';
  is_deeply decode_json(request_body($c->written)), $PRIVILEGES,
    'the privileges go back to the engine verbatim -- it compares them '
    . 'against what the plugin demands and refuses a mismatch';

  is_deeply $events, [ { status => 'Pulling plugin' } ],
    'the NDJSON progress stream comes back as an ArrayRef of events';
};

subtest 'install: local name and auth' => sub {
  my $c = fake_client(qq({"status":"Pulling plugin"}\n));
  $c->plugins->install('vieux/sshfs:latest',
    privileges => [],
    name       => 'sshfs',
    auth       => { identitytoken => 'tok-123' },
  );

  is query_param($c->written, 'name'), 'sshfs', 'local name sent';
  is request_body($c->written), '[]',
    'an empty privilege list is sent as an empty JSON array, not omitted';
  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  is_deeply decode_json(b64url_decode($hdr)), { identitytoken => 'tok-123' },
    'identitytoken auth reaches the header';
};

subtest 'install: a failure inside the 200 stream croaks' => sub {
  my $c = fake_client(
    qq({"status":"Pulling plugin"}\n)
    . qq({"errorDetail":{"message":"incorrect privileges"},"error":"incorrect privileges"}\n)
  );

  eval {
    $c->plugins->install('vieux/sshfs:latest', privileges => []);
    1;
  };
  my $err = $@;
  ok $err, 'a failed install does not return quietly';
  like "$err", qr/incorrect privileges/,
    'the engine reason survives into the exception';
  isa_ok $err, 'API::Docker::Error::Stream';
  is_deeply [ map { $_->{status} } grep { $_->{status} } @{ $err->events } ],
    ['Pulling plugin'], 'the progress that preceded the failure is kept';
};

subtest 'install: accept_privileges resolves both calls' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  my @calls;
  no warnings 'redefine';
  local *API::Docker::_request = sub {
    my ($self, $method, $path, %opts) = @_;
    push @calls, { method => $method, path => $path, %opts };
    return $PRIVILEGES if $path eq '/plugins/privileges';
    return [];
  };

  $docker->plugins->install('vieux/sshfs:latest', accept_privileges => 1);

  is scalar @calls, 2, 'two requests, not one';
  is $calls[0]{path}, '/plugins/privileges', 'privileges are fetched first';
  is $calls[0]{params}{remote}, 'vieux/sshfs:latest',
    'for the reference being installed';
  is $calls[1]{path}, '/plugins/pull', 'then the install';
  is_deeply $calls[1]{body}, $PRIVILEGES,
    'and exactly what the engine reported is what gets granted';
};

subtest 'install: privileges are required, and the croak says how' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  # No transport is faked here on purpose: nothing may reach the socket.
  eval { $docker->plugins->install('vieux/sshfs:latest') };
  my $err = $@;
  like $err, qr/requires privileges/, 'a blind install is refused';
  like $err, qr/->privileges\(/, 'the croak names the call that supplies them';
  like $err, qr/accept_privileges/, 'and the explicit blanket grant';

  eval { $docker->plugins->install('vieux/sshfs:latest', privileges => 'all') };
  like $@, qr/privileges must be an ArrayRef/,
    'a scalar is refused rather than JSON-encoded as a string';

  eval { $docker->plugins->install() };
  like $@, qr/remote reference required/, 'and the reference is required';
};

# ---------------------------------------------------------------------------
subtest 'upgrade: remote defaults to the plugin name' => sub {
  my $c = fake_client(qq({"status":"Upgrading"}\n));
  $c->plugins->upgrade('vieux/sshfs:latest', privileges => $PRIVILEGES);

  like request_line($c->written),
    qr{\APOST /v1\.41/plugins/vieux/sshfs:latest/upgrade\?},
    'POST /plugins/{name}/upgrade';
  is query_param($c->written, 'remote'), 'vieux/sshfs:latest',
    'remote defaults to the name, as the CLI does';
  is_deeply decode_json(request_body($c->written)), $PRIVILEGES,
    'the same privilege body as install';
};

subtest 'upgrade: a locally renamed plugin upgrades from its remote' => sub {
  my $c = fake_client(qq({"status":"Upgrading"}\n));
  $c->plugins->upgrade('sshfs',
    remote     => 'vieux/sshfs:v2',
    privileges => [],
  );

  like request_line($c->written), qr{\APOST /v1\.41/plugins/sshfs/upgrade\?},
    'the local name is in the path';
  is query_param($c->written, 'remote'), 'vieux/sshfs:v2',
    'the remote reference is in the query';
};

subtest 'upgrade: accept_privileges asks about the remote, not the local name' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  my @calls;
  no warnings 'redefine';
  local *API::Docker::_request = sub {
    my ($self, $method, $path, %opts) = @_;
    push @calls, { path => $path, %opts };
    return $PRIVILEGES if $path eq '/plugins/privileges';
    return [];
  };

  $docker->plugins->upgrade('sshfs', remote => 'vieux/sshfs:v2',
    accept_privileges => 1);

  is $calls[0]{params}{remote}, 'vieux/sshfs:v2',
    'an upgrade is where the demands can change, so the new reference is '
    . 'what gets asked about';
};

subtest 'upgrade: privileges are required too' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );
  eval { $docker->plugins->upgrade('vieux/sshfs:latest') };
  like $@, qr/upgrade requires privileges/, 'refused, naming the method';
};

# ---------------------------------------------------------------------------
subtest 'push: request assembly only' => sub {
  # This never reaches a registry -- the socket is an in-memory sink. There
  # is no live variant of this subtest and there must not be one.
  my $c = fake_client(qq({"status":"Pushing"}\n));
  $c->plugins->push('myrepo/sshfs:v1', auth => { username => 'u', password => 'p' });

  is request_line($c->written),
    'POST /v1.41/plugins/myrepo/sshfs:v1/push HTTP/1.1',
    'POST /plugins/{name}/push, no query string';
  my ($hdr) = $c->written =~ /^X-Registry-Auth: (\S+)\r$/m;
  is_deeply decode_json(b64url_decode($hdr)), { username => 'u', password => 'p' },
    'credentials in X-Registry-Auth, which the reference does not document '
    . 'on this endpoint but the daemon reads';
};

subtest 'push: anonymous sends no auth header' => sub {
  my $c = fake_client(qq({"status":"Pushing"}\n));
  $c->plugins->push('myrepo/sshfs:v1');
  unlike $c->written, qr/X-Registry-Auth/i,
    'unlike images->push, which must always send one';
};

# ---------------------------------------------------------------------------
subtest 'configure: settings are a JSON array of strings' => sub {
  my $c = fake_client('');
  $c->plugins->configure('vieux/sshfs:latest', ['DEBUG=1', 'sshkey.source=/tmp']);

  is request_line($c->written),
    'POST /v1.41/plugins/vieux/sshfs:latest/set HTTP/1.1',
    'POST /plugins/{name}/set';
  is_deeply decode_json(request_body($c->written)),
    ['DEBUG=1', 'sshkey.source=/tmp'], 'body is the settings array';

  $c->plugins->configure('vieux/sshfs:latest', 'DEBUG=1');
  is_deeply decode_json(request_body($c->written)), ['DEBUG=1'],
    'a bare list is accepted and still sent as an array, so a single '
    . 'setting cannot become a JSON string by accident';
};

subtest 'configure: validation' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  eval { $docker->plugins->configure('vieux/sshfs:latest') };
  like $@, qr/requires at least one setting/, 'no settings is refused';

  eval { $docker->plugins->configure('vieux/sshfs:latest', []) };
  like $@, qr/requires at least one setting/, 'an empty ArrayRef too';

  eval { $docker->plugins->configure('vieux/sshfs:latest', { DEBUG => 1 }) };
  like $@, qr/settings must be plain strings/,
    'a HashRef is refused rather than encoded as an object';

  eval { $docker->plugins->configure() };
  like $@, qr/plugin name required/, 'and the name is required';
};

# ---------------------------------------------------------------------------
subtest 'every name-taking method croaks without a name' => sub {
  my $docker = API::Docker->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );

  for my $method (qw( inspect remove enable disable push )) {
    eval { $docker->plugins->$method(undef) };
    like $@, qr/plugin name required/, "$method croaks on an undefined name";
  }

  eval { $docker->plugins->upgrade(undef, privileges => []) };
  like $@, qr/plugin name required/, 'upgrade croaks on an undefined name';

  eval { $docker->plugins->privileges(undef) };
  like $@, qr/remote reference required/,
    'privileges croaks on an undefined remote';
};

done_testing;
