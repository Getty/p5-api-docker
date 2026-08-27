use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw( decode_json );
use API::Docker;

# GET /distribution/{name}/json -- asking a registry for an image manifest
# without pulling it (karr #15).
#
# Nothing here opens a socket or reaches a daemon, and nothing is gated on
# is_live(). Test::API::Docker::Mock is deliberately not used for two
# reasons: under API_DOCKER_TEST_HOST it ignores its route table and returns
# a real client, and the only engine reachable here is Podman, which serves
# no route for this endpoint at all -- measured, rootless Podman 5.4.2
# (API 1.41):
#
#   GET /v1.41/distribution/nginx:latest/json
#   -> 404 {"cause":"","message":"Path /v1.41/distribution/nginx:latest/json
#           is not supported","response":0}
#
# and the same for a bare name and for a percent-escaped reference. Second,
# the mock replaces _request wholesale and so never croaks on a status at or
# above 400, which is precisely the behaviour under test here.
#
# So the daemon is faked below the socket instead, in both modes, and the
# real _request runs. The success payload is the Engine API reference's own
# example descriptor.

package Test::Distribution::FakeTransport;
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

sub written { my $sink = $_[0]->_sink; return defined $sink ? $$sink : '' }

package main;

my $DESCRIPTOR = <<'JSON';
{"Descriptor":{"MediaType":"application/vnd.docker.distribution.manifest.v2+json","digest":"sha256:c0537ff6a5218ef531ece93d4984efc99bbf3f7497c0a7726c88e2bb7584dc96","size":3987},"Platforms":[{"architecture":"amd64","os":"linux"}]}
JSON

sub fake_client {
  my ($body, $status) = @_;
  return Test::Distribution::FakeTransport->new(
    host        => 'unix:///nonexistent.sock',
    api_version => '1.41',
    canned      => [$status // 200, 'Not Found', {}, $body // $DESCRIPTOR],
  );
}

sub request_line {
  my ($raw) = @_;
  my ($line) = $raw =~ /\A([^\r\n]*)/;
  return $line;
}

# The two 404s this endpoint can give. Only the message tells them apart.
my $REGISTRY_404 = '{"message":"manifest unknown"}';
my $PODMAN_404   = '{"cause":"","message":"Path /v1.41/distribution/'
  . 'nginx:latest/json is not supported","response":0}';
my $DOCKER_404   = '{"message":"page not found"}';

# ---------------------------------------------------------------------------
subtest 'the reference keeps its slashes and its tag in the path' => sub {
  # Percent-encoding them breaks the reference: the daemon parses the path
  # segment as a docker reference, and %2F is not a repository separator.
  my $c = fake_client();
  $c->distribution->inspect('myrepo/app:1.0');
  is request_line($c->written),
    'GET /v1.41/distribution/myrepo/app:1.0/json HTTP/1.1',
    'slashes and the colon survive into the request line';

  my $plain = fake_client();
  $plain->distribution->inspect('nginx:latest');
  is request_line($plain->written),
    'GET /v1.41/distribution/nginx:latest/json HTTP/1.1',
    'and so does a plain library reference';

  ok !eval { fake_client()->distribution->inspect; 1 },
    'no reference croaks';
  like $@, qr/image reference/, 'and says what was missing';
};

# ---------------------------------------------------------------------------
subtest 'inspect returns the descriptor as the engine gave it' => sub {
  my $c = fake_client();
  my $d = $c->distribution->inspect('nginx:latest');

  is_deeply $d, decode_json($DESCRIPTOR),
    'the decoded response, not an entity object -- there is no '
    . 'API::Docker::Distribution class to wrap it in';
  is $d->{Descriptor}{size}, 3987, 'the descriptor is reachable';
};

# ---------------------------------------------------------------------------
subtest 'inspect croaks on 404, like every other endpoint method' => sub {
  my $c = fake_client($REGISTRY_404, 404);
  my %res;
  ok !eval { $c->distribution->inspect('nginx:latest', response => \%res); 1 },
    'a reference the registry does not have croaks';
  like $@, qr/manifest unknown/, 'with the registry message';
  is $res{status}, 404,
    'and response is filled before the croak, so an eval-ing caller reaches '
    . 'the status';
};

# ---------------------------------------------------------------------------
subtest 'exists answers the question without an eval' => sub {
  my $yes = fake_client();
  is $yes->distribution->exists('nginx:latest'), 1, '200 is yes';

  my $no = fake_client($REGISTRY_404, 404);
  ok !$no->distribution->exists('nginx:latest'),
    'the registry saying 404 is no, not an exception';

  # The property the whole predicate exists for. Podman has no route, so a
  # naive "404 means no" would answer no for every image on this machine --
  # which is the constant "no" the consumer's remote_tag_exists stub already
  # had, reintroduced one layer down where it looks like an answer.
  my $unsupported = fake_client($PODMAN_404, 404);
  ok !eval { $unsupported->distribution->exists('nginx:latest'); 1 },
    'an engine with no such route croaks rather than answering no';
  like $@, qr/cannot ask this engine/, 'and says the engine could not ask';
  like $@, qr/is not supported/, 'quoting what the engine said';

  my $docker_404 = fake_client($DOCKER_404, 404);
  ok !eval { $docker_404->distribution->exists('nginx:latest'); 1 },
    "Docker's own unknown-route 404 croaks too";

  # Anything that is not a 404 is not this method's to interpret.
  my $boom = fake_client('{"message":"server error"}', 500);
  ok !eval { $boom->distribution->exists('nginx:latest'); 1 },
    'a 500 propagates';
  like $@, qr/server error/, 'unchanged';
};

# ---------------------------------------------------------------------------
subtest 'exists fills a response HashRef the caller passed through' => sub {
  # It uses one internally; a caller's own must not be shadowed by it.
  my $c = fake_client($REGISTRY_404, 404);
  my %res;
  ok !$c->distribution->exists('nginx:latest', response => \%res), 'no';
  is $res{status}, 404, 'the caller sees the status behind the answer';
};

done_testing;
