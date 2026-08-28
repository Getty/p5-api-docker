use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;
use JSON::MaybeXS qw( decode_json );
# The role, not the type class: it is what composes the entity methods onto
# the generated classes, and constructing one before that has happened inlines
# its constructor and makes the composition impossible ("has been inlined and
# cannot be updated"). Loading API::Docker gets there too, through
# API::Docker::API::Images -- but the first subtest below builds an
# ImageSummary before any client exists.
use API::Docker::Role::Entity::Image;

# The engine's build stream, as captured from a real daemon. build/pull/push
# hand the caller one event per line, always as an ArrayRef.
sub build_events {
  my $body = load_fixture_raw('images_build_stream.ndjson');
  return [ map { decode_json($_) } grep { /\S/ } split /\n/, $body ];
}

# Live picks a name out of whatever `list` handed back. repo_tags on an
# untagged image is `[]` -- true in Perl -- so testing the ref for truth
# (as this used to) takes the tag branch for an untagged image and hands
# inspect()/history() an undef name. Walk the list for the first image that
# actually HAS a tag; fall back to an id only when none do -- both engines
# accept either as a name, so either is correct, but the ref-as-boolean
# check was right for neither. See karr k75.
sub _live_image_name {
  my ($images) = @_;
  for my $image (@$images) {
    my $tags = $image->repo_tags;
    return $tags->[0] if ref $tags eq 'ARRAY' && @$tags;
  }
  return $images->[0]->id;
}

check_live_access();

subtest '_live_image_name picks a tag, falling back to id' => sub {
  my $SUMMARY = 'API::Docker::Type::ImageSummary';
  my $untagged_1 = $SUMMARY->new(Id => 'sha256:untagged1', RepoTags => []);
  my $untagged_2 = $SUMMARY->new(Id => 'sha256:untagged2', RepoTags => []);
  my $tagged     = $SUMMARY->new(Id => 'sha256:tagged', RepoTags => ['alpine:3', 'alpine:latest']);

  is(
    _live_image_name([ $untagged_1, $untagged_2, $tagged ]),
    'alpine:3',
    'untagged images sorted first are skipped in favour of the first tag',
  );

  is(
    _live_image_name([ $tagged, $untagged_1 ]),
    'alpine:3',
    'a tagged image still wins when it is already first',
  );

  is(
    _live_image_name([ $untagged_1, $untagged_2 ]),
    'sha256:untagged1',
    q{falls back to the first image's id when nothing in the store is tagged},
  );
};

# --- Read Tests (always run) ---

subtest 'list images' => sub {
  my $docker = test_docker(
    'GET /images/json' => load_fixture('images_list'),
  );

  my $images = $docker->images->list;

  is(ref $images, 'ARRAY', 'returns array');
  if (@$images) {
    isa_ok($images->[0], 'API::Docker::Type::ImageSummary');
    ok($images->[0]->id, 'has id');
  }

  unless (is_live()) {
    is(scalar @$images, 2, 'two images');

    my $first = $images->[0];
    like($first->id, qr/^sha256:abc123/, 'image id');
    is_deeply($first->repo_tags, ['nginx:latest', 'nginx:1.25'], 'repo tags');
    is($first->size, 187654321, 'image size');
    is($first->containers, 2, 'container count');
  }
};

subtest 'inspect image' => sub {
  my $docker = test_docker(
    'GET /images/nginx:latest/json' => {
      Id           => 'sha256:abc123',
      RepoTags     => ['nginx:latest'],
      Architecture => 'amd64',
      Os           => 'linux',
      Size         => 187654321,
      Config       => {
        Cmd => ['nginx', '-g', 'daemon off;'],
      },
    },
  );

  my $image;
  if (is_live()) {
    my $images = $docker->images->list;
    if (@$images) {
      my $name = _live_image_name($images);
      $image = $docker->images->inspect($name);
    } else {
      plan skip_all => 'No images available for inspect test';
      return;
    }
  } else {
    $image = $docker->images->inspect('nginx:latest');
  }

  isa_ok($image, 'API::Docker::Type::ImageInspect');
  ok($image->id, 'has id');

  unless (is_live()) {
    is($image->id, 'sha256:abc123', 'image id');
    is($image->architecture, 'amd64', 'architecture');
    is($image->os, 'linux', 'os');
    is_deeply($image->config->cmd, ['nginx', '-g', 'daemon off;'],
      'and a nested field is inflated into its own generated class');
  }
};

subtest 'image history' => sub {
  my $docker = test_docker(
    'GET /images/nginx:latest/history' => [
      {
        Id        => 'sha256:abc123',
        Created   => 1705300000,
        CreatedBy => '/bin/sh -c #(nop) CMD ["nginx" "-g" "daemon off;"]',
        Size      => 0,
      },
      {
        Id        => 'sha256:def456',
        Created   => 1705299000,
        CreatedBy => '/bin/sh -c apt-get update',
        Size      => 50000000,
      },
    ],
  );

  my $history;
  if (is_live()) {
    my $images = $docker->images->list;
    if (@$images) {
      my $name = _live_image_name($images);
      $history = $docker->images->history($name);
    } else {
      plan skip_all => 'No images available for history test';
      return;
    }
  } else {
    $history = $docker->images->history('nginx:latest');
  }

  is(ref $history, 'ARRAY', 'history is array');

  unless (is_live()) {
    is(scalar @$history, 2, 'two history entries');
  }
};

subtest 'search images' => sub {
  my $docker = test_docker(
    'GET /images/search' => [
      {
        name         => 'nginx',
        description  => 'Official nginx image',
        star_count   => 19000,
        is_official  => 1,
        is_automated => 0,
      },
    ],
  );

  my $results = $docker->images->search('nginx');

  is(ref $results, 'ARRAY', 'search returns array');

  unless (is_live()) {
    is($results->[0]{name}, 'nginx', 'found nginx');
  }
};

# --- Write Tests (mock always, live only with WRITE) ---

subtest 'image build and pull lifecycle' => sub {
  skip_unless_write();

  my $docker = test_docker(
    'POST /build' => sub {
      my ($method, $path, %opts) = @_;
      ok(defined $opts{raw_body}, 'raw_body present in request');
      is($opts{content_type}, 'application/x-tar', 'content type is tar');
      ok($opts{ndjson}, 'build asks for stream decoding');
      return build_events();
    },
    'POST /images/create' => sub {
      my ($method, $path, %opts) = @_;
      return '';
    },
    'POST /images/nginx:latest/tag'  => undef,
    'DELETE /images/nginx:latest'    => [
      { Untagged => 'nginx:latest' },
      { Deleted  => 'sha256:abc123' },
    ],
  );

  if (is_live()) {
    my $dockerfile = "FROM alpine:latest\nRUN echo 'hello from api-docker-test'\n";

    my $filename = 'Dockerfile';
    my $size = length($dockerfile);

    my $header = pack('a100', $filename);
    $header .= pack('a8', sprintf('%07o', 0644));
    $header .= pack('a8', sprintf('%07o', 0));
    $header .= pack('a8', sprintf('%07o', 0));
    $header .= pack('a12', sprintf('%011o', $size));
    $header .= pack('a12', sprintf('%011o', time()));
    $header .= '        ';
    $header .= '0';
    $header .= pack('a100', '');
    $header .= pack('a6', 'ustar');
    $header .= pack('a2', '00');
    $header .= pack('a32', '');
    $header .= pack('a32', '');
    $header .= pack('a8', '');
    $header .= pack('a8', '');
    $header .= pack('a155', '');
    $header .= "\0" x (512 - length($header));

    my $checksum = 0;
    $checksum += ord(substr($header, $_, 1)) for 0..511;
    substr($header, 148, 8, sprintf('%06o', $checksum) . "\0 ");

    my $tar = $header;
    $tar .= $dockerfile;
    $tar .= "\0" x (512 - ($size % 512)) if $size % 512;
    $tar .= "\0" x 1024;

    my $tag = 'api-docker-test-build:latest';
    # q => 1 makes the engine emit exactly one event -- the case that used
    # to come back as a HashRef instead of an ArrayRef.
    my $result = $docker->images->build(context => $tar, t => $tag, q => 1);
    is(ref $result, 'ARRAY', 'a single-event build stream is still an ArrayRef');
    register_cleanup(sub { eval { $docker->images->remove($tag, force => 1) } });
  } else {
    my $result = $docker->images->build(
      context    => 'fake-tar-data',
      t          => 'myapp:latest',
      dockerfile => 'Dockerfile',
    );
    is(ref $result, 'ARRAY', 'build returns an ArrayRef of events');
    like(
      join('', map { $_->{stream} // '' } @$result),
      qr/Successfully built/,
      'build output contains success',
    );

    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    pass('pull completed');

    $docker->images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');
    pass('tag completed');

    my $removed = $docker->images->remove('nginx:latest');
    is(ref $removed, 'ARRAY', 'remove returns array of actions');
  }
};

# --- Validation Tests (always run, no Docker needed) ---

subtest 'build requires context' => sub {
  my $docker = test_docker();

  eval { $docker->images->build(t => 'myapp:latest') };
  like($@, qr/Build context required/, 'croak on missing context');
};

subtest 'image name required' => sub {
  my $docker = test_docker();

  eval { $docker->images->inspect(undef) };
  like($@, qr/Image name required/, 'croak on missing name for inspect');

  eval { $docker->images->remove(undef) };
  like($@, qr/Image name required/, 'croak on missing name for remove');
};

done_testing;
