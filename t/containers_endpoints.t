#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::API::Docker::Mock;
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( encode_base64 );
use API::Docker;

# The container endpoints this client did not expose:
#
#   karr #18  GET/PUT/HEAD /containers/{id}/archive  -- what docker cp is
#   karr #19  POST /containers/{id}/attach           -- the one-way variant
#   karr #23  changes, export, resize
#
# Measured against the rootless Podman socket (5.4.2, API 1.41): all five
# routes are served there. A nonexistent container answers 404 on archive,
# export, resize and attach -- and 500 with "layer not known" on changes,
# which is why changes documents that difference.
#
# What is NOT measured here: the bytes of a real archive, a real attach
# stream, and the X-Docker-Container-Path-Stat header, because all three need
# a container and this work was held to read-only probes. The live subtests at
# the bottom read them off a container that already exists; with none on the
# daemon they skip, and they skipped on the run that produced this file.

check_live_access();

# A real ustar archive built with GNU tar, shaped like what the engine returns
# for path=/etc/hostname: one member, named after the basename. Deliberately
# not hand-rolled bytes -- the property under test is that nothing in the
# client touches them, so it has to be a stream a tar reader accepts.
my $TAR = load_fixture_raw('containers_archive.tar');

# The one-way attach stream is byte-identical to the logs stream, which is the
# whole claim of karr #19. This is the captured logs fixture rather than a
# second file holding the same bytes: it is real engine output, and a copy
# made by hand would only look like one.
my $FRAMES = load_fixture_raw('containers_logs_multiplexed.bin');

# Constructed from the shape the Docker Engine API documents, not captured --
# see the note above and API::Docker::API::Containers/stat_archive.
my %STAT = (
  name       => 'hostname',
  size       => 13,
  mode       => 420,
  mtime      => '2026-08-27T05:00:00Z',
  linkTarget => '',
);
my $STAT_HEADER = encode_base64(encode_json(\%STAT), '');

# ---------------------------------------------------------------------------
# A client whose socket is an in-memory sink and whose response is canned, so
# the real _request runs -- and with it raw => 1, raw_body, the query string
# and the verb. Same pattern as t/images_tar.t and t/streaming_shape.t; the
# mock harness replaces _request wholesale and can reach none of it.
package Test::ContainersEndpoints::FakeTransport;
use Moo;
extends 'API::Docker';

has canned => (is => 'rw', default => sub { [200, 'OK', {}, ''] });
has _sink  => (is => 'rw');

sub _build__socket {
  my ($self) = @_;
  my $sink = '';
  $self->_sink(\$sink);
  open my $fh, '>', \$sink or die "open: $!";
  binmode $fh;
  return $fh;
}

sub _read_response { return $_[0]->canned }

sub written { return ${ $_[0]->_sink } }

sub request_line {
  my ($line) = $_[0]->written =~ /\A([^\r\n]+)\r\n/;
  return $line;
}

sub request_body {
  my ($body) = $_[0]->written =~ /\r\n\r\n(.*)\z/s;
  return $body;
}

package main;

sub fake_client {
  return Test::ContainersEndpoints::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
  );
}

# ---------------------------------------------------------------------------
subtest 'the tar fixture really is a tar, so byte-exactness means something' => sub {
  is length($TAR) % 512, 0, 'a whole number of 512-byte blocks';
  is substr($TAR, 257, 5), 'ustar', 'ustar magic in the header block';
  is unpack('Z100', $TAR), 'hostname', 'one member, named after the basename';
  like $TAR, qr/\0/, 'carries NUL bytes -- it is not text';
};

# ===========================================================================
# karr #18 -- the archive endpoints
# ===========================================================================

subtest 'get_archive: asks for raw bytes and hands them back untouched' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my %seen;
  my $docker = test_docker(
    'GET /containers/deadbeef/archive' => sub {
      my ($method, $path, %opts) = @_;
      %seen = %opts;
      return $TAR;
    },
  );

  my $out = $docker->containers->get_archive('deadbeef', path => '/etc/hostname');

  ok $seen{raw}, 'the request asked the transport for raw bytes';
  ok !$seen{ndjson}, 'and not for a decoded event stream';
  is_deeply $seen{params}, { path => '/etc/hostname' },
    'path is the only query parameter';
  is $out, $TAR, 'the daemon bytes come back verbatim';
  is length($out), length($TAR), 'no truncation';
};

subtest 'get_archive: raw bytes survive the real _request' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', { 'content-type' => 'application/x-tar' }, $TAR]);

  my $out = $t->containers->get_archive('deadbeef', path => '/var/log/app.log');

  is $out, $TAR, 'byte-exact through _request';
  is $t->request_line,
    'GET /v1.41/containers/deadbeef/archive?path=/var/log/app.log HTTP/1.1',
    'GET on the versioned path, the path parameter keeping its slashes';
};

subtest 'get_archive: a body that looks like JSON is still not decoded' => sub {
  # The transport tries decode_json on any body starting with { or [ unless
  # raw is set. A tar cannot start that way, but the guarantee is "never
  # decoded", not "never decodable" -- so assert it directly.
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '{"name":"not really a tar"}']);

  is ref $t->containers->get_archive('deadbeef', path => '/x'), '',
    'a JSON-shaped body comes back as a plain string, not a HashRef';
};

subtest 'get_archive: the stat out-parameter decodes the header' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK',
    { 'x-docker-container-path-stat' => $STAT_HEADER }, $TAR]);

  my %stat;
  my $out = $t->containers->get_archive('deadbeef',
    path => '/etc/hostname', stat => \%stat);

  is $out, $TAR, 'the return value is still the archive, not the stat';
  is_deeply \%stat, \%STAT,
    'the base64 JSON header is decoded, not handed over as base64';

  # The engine sends the header on this response too, so a caller wanting
  # both does not have to pay for the HEAD as well.
  my $t2 = fake_client();
  $t2->canned([200, 'OK', {}, $TAR]);
  my %empty = ( leftover => 1 );
  $t2->containers->get_archive('deadbeef', path => '/x', stat => \%empty);
  is_deeply \%empty, {}, 'emptied when the engine sent no such header';

  my $err = do { local $@; eval {
    $t->containers->get_archive('deadbeef', path => '/x', stat => 'nope') }; $@ };
  like $err, qr/stat option must be a HashRef/, 'a non-HashRef stat croaks';
};

subtest 'get_archive: the required arguments are required' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, $TAR]);

  my $no_id = do { local $@; eval { $t->containers->get_archive }; $@ };
  like $no_id, qr/Container ID required/, 'a missing id croaks';

  my $no_path = do { local $@; eval {
    $t->containers->get_archive('deadbeef') }; $@ };
  like $no_path, qr/Path required/, 'a missing path croaks';

  my $empty = do { local $@; eval {
    $t->containers->get_archive('deadbeef', path => '') }; $@ };
  like $empty, qr/Path required/, 'an empty path croaks rather than reaching the daemon';
};

subtest 'put_archive: the tar is the request body, the options are the query' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);

  my $out = $t->containers->put_archive('deadbeef', $TAR, path => '/opt/app');

  is $out, undef, 'a success carries no body, so there is nothing to return';
  is $t->request_line, 'PUT /v1.41/containers/deadbeef/archive?path=/opt/app HTTP/1.1',
    'PUT on the archive path';
  like $t->written, qr{Content-Type: application/x-tar\r\n}, 'sent as a tar';
  like $t->written, qr{Content-Length: @{[ length $TAR ]}\r\n}, 'the whole archive';
  is $t->request_body, $TAR, 'the request body is the archive byte for byte';
};

subtest 'put_archive: noOverwriteDirNonDir and copyUIDGID' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);

  $t->containers->put_archive('deadbeef', $TAR,
    path => '/opt/app', noOverwriteDirNonDir => 1, copyUIDGID => 1);
  is $t->request_line,
    'PUT /v1.41/containers/deadbeef/archive?copyUIDGID=1&noOverwriteDirNonDir=1&path=/opt/app HTTP/1.1',
    'both flags on the wire as 1';

  $t->containers->put_archive('deadbeef', $TAR,
    path => '/opt/app', noOverwriteDirNonDir => 0, copyUIDGID => 0);
  is $t->request_line,
    'PUT /v1.41/containers/deadbeef/archive?copyUIDGID=0&noOverwriteDirNonDir=0&path=/opt/app HTTP/1.1',
    'a false flag is sent as 0, not dropped -- the engine reads absence as false too, '
    . 'but a caller that passed it explicitly gets it sent';

  $t->containers->put_archive('deadbeef', $TAR, path => '/opt/app');
  is $t->request_line, 'PUT /v1.41/containers/deadbeef/archive?path=/opt/app HTTP/1.1',
    'neither appears when neither was asked for';
};

subtest 'put_archive: takes a scalar ref, and requires what it requires' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);

  $t->containers->put_archive('deadbeef', \$TAR, path => '/opt/app');
  is $t->request_body, $TAR, 'dereferenced, not stringified';

  my $no_tar = do { local $@; eval {
    $t->containers->put_archive('deadbeef', undef, path => '/opt/app') }; $@ };
  like $no_tar, qr/Tar archive required/, 'a missing archive croaks';

  my $no_path = do { local $@; eval {
    $t->containers->put_archive('deadbeef', $TAR) }; $@ };
  like $no_path, qr/Path required/, 'a missing path croaks';

  my $no_id = do { local $@; eval { $t->containers->put_archive }; $@ };
  like $no_id, qr/Container ID required/, 'a missing id croaks';
};

subtest 'stat_archive: HEAD, and the payload comes out of the header' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', { 'x-docker-container-path-stat' => $STAT_HEADER }, '']);

  my $stat = $t->containers->stat_archive('deadbeef', path => '/etc/hostname');

  is $t->request_line,
    'HEAD /v1.41/containers/deadbeef/archive?path=/etc/hostname HTTP/1.1',
    'the verb is HEAD, not GET';
  is_deeply $stat, \%STAT, 'the header is decoded into a HashRef';
  is $stat->{mode} & 0777, 0644, 'the permission bits are the low nine of mode';
};

subtest 'stat_archive: the base64 alphabet is read tolerantly' => sub {
  # Docker encodes this header with Go's base64.StdEncoding. Decoding is done
  # with the URL-safe characters translated back first, so an engine that
  # reached for the other alphabet is still read rather than croaking.
  my $payload   = encode_json({ name => 'a+b/c', size => 1 });
  my $url_safe  = encode_base64($payload, '');
  $url_safe =~ tr{+/}{-_};

  my $t = fake_client();
  $t->canned([200, 'OK', { 'x-docker-container-path-stat' => $url_safe }, '']);

  is_deeply $t->containers->stat_archive('deadbeef', path => '/x'),
    { name => 'a+b/c', size => 1 },
    'a URL-safe encoding decodes to the same JSON';
};

subtest 'stat_archive: nothing to decode, and something undecodable' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);
  is $t->containers->stat_archive('deadbeef', path => '/x'), undef,
    'undef when the engine sent no stat header at all';

  $t->canned([200, 'OK', { 'x-docker-container-path-stat' => '' }, '']);
  is $t->containers->stat_archive('deadbeef', path => '/x'), undef,
    'undef for an empty header, not a croak';

  $t->canned([200, 'OK',
    { 'x-docker-container-path-stat' => 'bm90IEpTT04=' }, '']);
  my $err = do { local $@; eval {
    $t->containers->stat_archive('deadbeef', path => '/x') }; $@ };
  like $err, qr/Cannot decode X-Docker-Container-Path-Stat/,
    'base64 that is not JSON croaks and names the header';

  my $no_path = do { local $@; eval {
    $t->containers->stat_archive('deadbeef') }; $@ };
  like $no_path, qr/Path required/, 'a missing path croaks';
};

subtest 'stat_archive: a missing path is a croak, not an undef' => sub {
  # The transport croaks on >= 400 before anything here can look at headers,
  # so "no such file" and "no stat header" are different outcomes and a caller
  # testing for undef will not silently swallow the first.
  my $t = fake_client();
  $t->canned([404, 'Not Found', {},
    '{"cause":"no such file or directory","message":"Could not find the file /nope in container deadbeef","response":404}']);

  my $err = do { local $@; eval {
    $t->containers->stat_archive('deadbeef', path => '/nope') }; $@ };
  like $err, qr/Docker API error \(404\)/, 'the status handling croaks first';
  like $err, qr/Could not find the file/, 'with the message key';
};

# ===========================================================================
# karr #19 -- the one-way attach
# ===========================================================================

subtest 'attach: demultiplexes exactly as logs does' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my $docker = test_docker(
    'POST /containers/deadbeef/attach' => sub { $FRAMES },
    'GET /containers/deadbeef/logs'    => sub { $FRAMES },
  );

  my $attached = $docker->containers->attach('deadbeef');
  is_deeply $attached, [
    { stream => 'stdout', data => "OUT\n" },
    { stream => 'stderr', data => "ERR\n" },
  ], 'two frames, headers stripped';

  is_deeply $attached, $docker->containers->logs('deadbeef'),
    'the same bytes give the same frames through either method';

  is join('', map { $_->{data} } @$attached), "OUT\nERR\n",
    'joining the payloads gives the plain text';
};

subtest 'attach: the query parameters, and the defaults that differ from the engine' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, $FRAMES]);

  $t->containers->attach('deadbeef');
  is $t->request_line,
    'POST /v1.41/containers/deadbeef/attach?stderr=1&stdout=1&stream=1 HTTP/1.1',
    'stream, stdout and stderr default on -- the engine defaults all three off, '
    . 'and with stream and logs both off the response is empty';

  $t->containers->attach('deadbeef',
    stream => 0, stdout => 0, stderr => 0, stdin => 1, logs => 1);
  is $t->request_line,
    'POST /v1.41/containers/deadbeef/attach?logs=1&stderr=0&stdin=1&stdout=0&stream=0 HTTP/1.1',
    'every one of the five is sent as asked, false as 0';

  $t->containers->attach('deadbeef', logs => 0, stdin => 0);
  is $t->request_line,
    'POST /v1.41/containers/deadbeef/attach?logs=0&stderr=1&stdin=0&stdout=1&stream=1 HTTP/1.1',
    'stdin and logs appear only when named; a false one is still sent';

  my $err = do { local $@; eval { $t->containers->attach }; $@ };
  like $err, qr/Container ID required/, 'a missing id croaks';
};

subtest 'attach: it is a POST with no body, not a GET' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, $FRAMES]);
  $t->containers->attach('deadbeef');

  like $t->written, qr{\APOST /v1\.41/containers/deadbeef/attach\?},
    'POST, as the engine requires for this endpoint';
  is $t->request_body, '', 'and no request body -- every option is in the query';
  unlike $t->written, qr/Upgrade:/i,
    'no Upgrade header: this is the 200 one-way variant, not the 101 upgraded one';
};

subtest 'attach: tty skips demultiplexing' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, "OUT\r\nERR\r\n"]);

  is_deeply $t->containers->attach('deadbeef', tty => 1),
    [ { stream => 'raw', data => "OUT\r\nERR\r\n" } ],
    'a TTY attach comes back as one raw frame';

  # And the framing is detected from the bytes when tty was not declared,
  # so the common case needs no flag.
  is_deeply $t->containers->attach('deadbeef'),
    [ { stream => 'raw', data => "OUT\r\nERR\r\n" } ],
    'unframed bytes are reported raw without being told';

  $t->canned([200, 'OK', {}, $FRAMES]);
  is_deeply $t->containers->attach('deadbeef', tty => 1),
    [ { stream => 'raw', data => $FRAMES } ],
    'tty => 1 suppresses the walk even on bytes that would have framed';
};

subtest 'attach: an empty stream is an empty ArrayRef' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);
  is_deeply $t->containers->attach('deadbeef'), [],
    'a container that wrote nothing gives no frames, not undef';
};

# ===========================================================================
# karr #23 -- changes, export, resize
# ===========================================================================

subtest 'changes: the diff, and what the Kind numbers are' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', { 'content-type' => 'application/json' },
    '[{"Path":"/etc/hostname","Kind":0},{"Path":"/tmp/new","Kind":1},'
    . '{"Path":"/etc/gone","Kind":2}]']);

  my $changes = $t->containers->changes('deadbeef');

  is $t->request_line, 'GET /v1.41/containers/deadbeef/changes HTTP/1.1',
    'GET on the changes path, no query parameters';
  is ref $changes, 'ARRAY', 'an ArrayRef';
  is scalar @$changes, 3, 'one entry per changed path';
  is_deeply $changes->[0], { Path => '/etc/hostname', Kind => 0 }, '0 is modified';
  is_deeply $changes->[1], { Path => '/tmp/new',      Kind => 1 }, '1 is added';
  is_deeply $changes->[2], { Path => '/etc/gone',     Kind => 2 }, '2 is deleted';

  my $err = do { local $@; eval { $t->containers->changes }; $@ };
  like $err, qr/Container ID required/, 'a missing id croaks';
};

subtest 'changes: a container with nothing changed is an empty ArrayRef' => sub {
  # The engine answers that case with a JSON null. The transport decodes any
  # JSON body, scalars included (karr #30), so a null body reaches this
  # method as undef -- which a caller iterating the result would dereference
  # and die on just the same.
  my $t = fake_client();
  $t->canned([200, 'OK', { 'content-type' => 'application/json' }, 'null']);

  is_deeply $t->containers->changes('deadbeef'), [],
    'a null body is normalised to an empty ArrayRef, not left as undef';

  $t->canned([204, 'No Content', {}, '']);
  is_deeply $t->containers->changes('deadbeef'), [],
    'and so is an empty body';
};

subtest 'export: raw tar bytes, never decoded' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', { 'content-type' => 'application/x-tar' }, $TAR]);

  my $out = $t->containers->export('deadbeef');

  is $t->request_line, 'GET /v1.41/containers/deadbeef/export HTTP/1.1',
    'GET on the export path';
  is $out, $TAR, 'byte-exact';
  is length($out), length($TAR), 'no truncation';

  $t->canned([200, 'OK', {}, '{"Id":"not really a tar"}']);
  is ref $t->containers->export('deadbeef'), '',
    'a JSON-shaped body is not decoded either';

  my $err = do { local $@; eval { $t->containers->export }; $@ };
  like $err, qr/Container ID required/, 'a missing id croaks';
};

subtest 'resize: form-identical to the one Exec already had' => sub {
  my $t = fake_client();
  $t->canned([200, 'OK', {}, '']);

  $t->containers->resize('deadbeef', h => 40, w => 120);
  is $t->request_line, 'POST /v1.41/containers/deadbeef/resize?h=40&w=120 HTTP/1.1',
    'w and h as query parameters on a POST with no body';
  is $t->request_body, '', 'no request body';

  $t->exec->resize('deadbeef', h => 40, w => 120);
  is $t->request_line, 'POST /v1.41/exec/deadbeef/resize?h=40&w=120 HTTP/1.1',
    'the exec one spells the query identically -- the two classes no longer '
    . 'disagree about the same capability';

  $t->containers->resize('deadbeef', w => 80);
  is $t->request_line, 'POST /v1.41/containers/deadbeef/resize?w=80 HTTP/1.1',
    'an option that was not given is not sent, as in Exec::resize';

  my $err = do { local $@; eval { $t->containers->resize }; $@ };
  like $err, qr/Container ID required/, 'a missing id croaks';
};

# ===========================================================================
# The entity forwards
# ===========================================================================

subtest 'API::Docker::Container forwards all six' => sub {
  plan skip_all => 'route assertions are fixture-only' if is_live();

  my %seen;
  my $docker = test_docker(
    'GET /containers/json' => [ { Id => 'deadbeef', Names => ['/c'] } ],
    'GET /containers/deadbeef/archive'  => sub { $seen{get_archive}++;  $TAR },
    'PUT /containers/deadbeef/archive'  => sub { $seen{put_archive}++;  undef },
    'HEAD /containers/deadbeef/archive' => sub {
      $seen{stat_archive}++;
      mock_response(headers => { 'X-Docker-Container-Path-Stat' => $STAT_HEADER });
    },
    'POST /containers/deadbeef/attach'  => sub { $seen{attach}++; $FRAMES },
    'GET /containers/deadbeef/changes'  => sub { $seen{changes}++; [] },
    'GET /containers/deadbeef/export'   => sub { $seen{export}++;  $TAR },
    'POST /containers/deadbeef/resize'  => sub { $seen{resize}++;  undef },
  );

  # The client must stay in a live variable: entities hold it as a weak_ref.
  my ($container) = @{ $docker->containers->list };
  isa_ok $container, 'API::Docker::Container';

  is $container->get_archive(path => '/etc/hostname'), $TAR, 'get_archive';
  is $container->put_archive($TAR, path => '/opt'), undef, 'put_archive';
  is_deeply $container->stat_archive(path => '/etc/hostname'), \%STAT, 'stat_archive';
  is scalar @{ $container->attach }, 2, 'attach';
  is_deeply $container->changes, [], 'changes';
  is $container->export, $TAR, 'export';
  is $container->resize(h => 40, w => 120), undef, 'resize';

  is_deeply \%seen, {
    get_archive => 1, put_archive => 1, stat_archive => 1,
    attach => 1, changes => 1, export => 1, resize => 1,
  }, 'each forward reached its own endpoint exactly once';
};

# ===========================================================================
# Live, read-only. These need a container that already exists on the daemon;
# creating one is a write and out of scope for the work that added them.
#
# attach is deliberately not here: the transport buffers, so attaching to a
# container that keeps running never returns. export is not here either -- it
# would buffer the whole filesystem in RAM.
# ===========================================================================

sub live_container {
  my $docker = shift;
  my ($c) = grep { $_->Id } @{ $docker->containers->list(all => 1) };
  return $c;
}

subtest 'live: changes and the archive endpoints against a real container' => sub {
  plan skip_all => 'live only' unless is_live();

  my $docker = test_docker();
  my $container = live_container($docker);
  plan skip_all => 'no container on the daemon to read from' unless $container;

  my $changes = $docker->containers->changes($container->Id);
  is ref $changes, 'ARRAY', 'changes returns an ArrayRef';
  for my $change (@$changes) {
    ok defined $change->{Path}, 'each entry has a Path';
    like $change->{Kind}, qr/\A[012]\z/, 'and a Kind of 0, 1 or 2';
  }

  my $stat = $docker->containers->stat_archive($container->Id,
    path => '/etc/hostname');
  ok defined $stat, 'stat_archive found /etc/hostname';
  is ref $stat, 'HASH', 'and decoded the header into a HashRef';
  # The engine's key names, verified here rather than assumed.
  ok exists $stat->{name}, 'the stat carries a name key';
  ok exists $stat->{size}, 'and a size key';
  ok exists $stat->{mode}, 'and a mode key';
  note 'X-Docker-Container-Path-Stat keys: ' . join(', ', sort keys %$stat);

  my $tar = $docker->containers->get_archive($container->Id,
    path => '/etc/hostname');
  ok defined $tar && length $tar, 'get_archive returned bytes';
  is length($tar) % 512, 0, 'a whole number of tar blocks';
  is substr($tar, 257, 5), 'ustar', 'ustar magic';
  is unpack('Z100', $tar), 'hostname', 'the member is the basename';
};

done_testing;
