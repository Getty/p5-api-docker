package API::Docker;
# ABSTRACT: Perl client for the Docker Engine API
our $VERSION = '0.004';
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

use API::Docker::API::System;
use API::Docker::API::Containers;
use API::Docker::API::Images;
use API::Docker::API::Networks;
use API::Docker::API::Volumes;
use API::Docker::API::Exec;
use API::Docker::API::Distribution;
use API::Docker::API::Secrets;
use API::Docker::API::Configs;
use API::Docker::API::Plugins;

=head1 SYNOPSIS

    use API::Docker;

    # Connect to local Docker daemon via Unix socket
    my $docker = API::Docker->new;

    # Or connect to remote Docker daemon
    my $docker = API::Docker->new(
        host => 'tcp://192.168.1.100:2375',
    );

    # System information
    my $info = $docker->system->info;
    my $version = $docker->system->version;

    # Container management
    my $containers = $docker->containers->list(all => 1);
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
    );
    $docker->containers->start($result->{Id});

    # Image operations
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    my $images = $docker->images->list;

    # Network and volume management
    my $networks = $docker->networks->list;
    my $volumes = $docker->volumes->list;

=head1 DESCRIPTION

API::Docker is a Perl client for the Docker Engine API. It provides a clean
object-oriented interface to manage Docker containers, images, networks, and
volumes.

Key features:

=over

=item * Pure Perl implementation with minimal dependencies

=item * Unix socket and TCP transport, the latter in the clear or over TLS
with client certificates (L</tls>, L</cert_path>)

=item * Automatic API version negotiation

=item * Object-oriented entity classes (Container, Image, Network, Volume)

=item * Comprehensive logging via L<Log::Any>

=back

=head2 Architecture

The distribution is organized into several layers:

=over

=item * B<Main Client> - L<API::Docker> - Entry point with API version negotiation

=item * B<API Modules> - Resource-specific API methods:

=over

=item * L<API::Docker::API::System> - System info, version, ping

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Exec into containers

=item * L<API::Docker::API::Distribution> - Registry manifest lookups

=item * L<API::Docker::API::Secrets> - Swarm secrets

=item * L<API::Docker::API::Configs> - Swarm configs

=item * L<API::Docker::API::Plugins> - Managed plugins

=back

=item * B<Entity Classes> - Object wrappers for Docker resources:

=over

=item * L<API::Docker::Container> - Container entity with convenience methods

=item * L<API::Docker::Image> - Image entity

=item * L<API::Docker::Network> - Network entity

=item * L<API::Docker::Volume> - Volume entity

=back

=item * B<Roles> - Behaviour shared across the API modules:

=over

=item * L<API::Docker::Role::HTTP> - HTTP transport layer

=item * L<API::Docker::Role::RegistryAuth> - X-Registry-Auth / AuthConfig
encoding, shared by Images, Plugins, Distribution and System

=item * L<API::Docker::Role::Filters> - the C<filters> query parameter,
normalised into the one shape the engine reads

=back

=back

=head2 Swarm orchestration is out of scope

C</swarm>, C</nodes>, C</services> and C</tasks> are deliberately absent and
are not planned: Podman -- the engine this distribution is actually tested
against -- implements none of them, so the whole family would ship untested,
and no consumer asks for it. Compose and Kubernetes took the job Swarm was
aimed at. L<API::Docker::API::Secrets> and L<API::Docker::API::Configs> are
covered despite belonging to that same Engine API family, because they stand
on their own rather than on an orchestrator -- Podman serves C</secrets> from
its own local secret store with no swarm anywhere in sight.

=cut

has host => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_HOST} // 'unix:///var/run/docker.sock' },
);

=attr host

Docker daemon connection URL. Defaults to C<$ENV{DOCKER_HOST}> or
C<unix:///var/run/docker.sock>.

No other source is consulted; see L</Socket discovery>.

Supported formats:

=over

=item * C<unix:///path/to/socket> - Unix socket (default)

=item * C<tcp://host:port> - TCP connection

=back

=cut

has api_version => (
  is      => 'rwp',
  default => undef,
);

=attr api_version

Docker API version to use (e.g., C<1.41>). If not set, the client will
automatically negotiate the highest API version supported by the daemon.

This attribute is set automatically by L</negotiate_version>.

=cut

has tls => (
  is      => 'ro',
  default => 0,
);

=attr tls

Speak TLS on a C<tcp://> connection. Default C<0>, which is plaintext.

    my $docker = API::Docker->new(
      host      => 'tcp://dockerhost:2376',
      tls       => 1,
      cert_path => '/home/me/.docker',
    );

With C<< tls => 1 >> the transport opens an L<IO::Socket::SSL> connection
instead of an L<IO::Socket::INET> one and nothing above the socket changes.
The daemon's certificate is B<verified>, and so is its hostname; L</cert_path>
supplies the trust anchor and this client's own certificate.

With no certificates at all it still means encrypt and verify, against the
system trust store -- see
L<API::Docker::Role::HTTP/"TLS with no certificates at all">
for why that rather than an error. To switch verification off, and to read
what that gives away, see L</tls_insecure>.

C<< tls => 1 >> on a C<unix://> host croaks at construction. A Unix socket is
a file, not a wire; there is nothing on it to encrypt, and accepting the
option would mean answering a request for an encrypted transport with an
unencrypted one -- which is the failure this attribute previously had.

L<IO::Socket::SSL> is a recommended rather than a required dependency, loaded
when the first TLS connection is opened; C<< tls => 1 >> without it installed
croaks naming it. See
L<API::Docker::Role::HTTP/"TLS on a tcp:// connection"> for the whole of the
policy.

=cut

has cert_path => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_CERT_PATH} },
);

=attr cert_path

Directory holding the TLS certificates, in the layout the C<docker> CLI
writes: F<ca.pem> as the trust anchor, F<cert.pem> and F<key.pem> as this
client's certificate and key. Defaults to C<$ENV{DOCKER_CERT_PATH}>.

Each file is used if it is there. F<ca.pem> alone is a daemon this client
verifies but does not authenticate to; F<cert.pem> without F<key.pem> or the
reverse is a croak, since half a client certificate is an accident rather than
a mode. A C<cert_path> naming something that is not a directory croaks too.

B<Read only when L</tls> is set.> The default comes from the environment, and
C<DOCKER_CERT_PATH> is exported on plenty of machines that run the C<docker>
CLI, so a client that never asked for TLS is unaffected by having it set. A
TLS client that wants the system trust store rather than the CLI's private one
on such a machine passes C<< cert_path => undef >> explicitly.

=cut

has tls_insecure => (
  is      => 'ro',
  default => 0,
);

=attr tls_insecure

Turn certificate verification off. Default C<0>. Only read when L</tls> is
set, and named for what it does.

C<< tls_insecure => 1 >> sets C<SSL_VERIFY_NONE> and drops the hostname check,
which leaves a connection encrypted against a passive listener and against
nothing else: whoever answers it chooses the certificate, so anyone able to
redirect the connection reads and rewrites everything on it -- registry
credentials, image contents, the commands containers are started with.

It exists for a self-signed daemon certificate whose CA is not to hand. The
better answer is nearly always L</cert_path>: a self-signed certificate is its
own CA and works as F<ca.pem> directly.

Setting it without L</tls> croaks, rather than being accepted and doing
nothing.

=cut

sub BUILD {
  my ($self) = @_;

  # Both checks are here rather than at connect time so that a request for
  # encryption that cannot be honoured is refused before the caller has a
  # client to hand credentials to.
  croak __PACKAGE__ . '->new tls_insecure => 1 without tls => 1 does '
    . 'nothing: verification is only reachable on a connection that has TLS '
    . 'to verify. Set tls => 1 as well, or drop the option'
    if $self->tls_insecure && !$self->tls;

  return unless $self->tls;

  my $host = $self->host;
  croak __PACKAGE__ . '->new tls => 1 is only meaningful for a tcp:// host, '
    . 'and this one is ' . $host . '. A Unix socket is a file rather than a '
    . 'wire and carries nothing to encrypt, so honouring the option is not '
    . 'possible and ignoring it would answer a request for an encrypted '
    . 'transport with an unencrypted one'
    unless $host =~ m{^tcp://};
}

has _version_negotiated => (
  is      => 'rw',
  default => 0,
);

with 'API::Docker::Role::HTTP';

has system => (
  is      => 'lazy',
  builder => sub { API::Docker::API::System->new(client => $_[0]) },
);

=attr system

Returns L<API::Docker::API::System> instance for system operations like
C<info>, C<version>, C<ping>, and C<events>.

=cut

has containers => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Containers->new(client => $_[0]) },
);

=attr containers

Returns L<API::Docker::API::Containers> instance for container operations like
C<list>, C<create>, C<start>, C<stop>, and C<remove>.

=cut

has images => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Images->new(client => $_[0]) },
);

=attr images

Returns L<API::Docker::API::Images> instance for image operations like
C<list>, C<pull>, C<push>, and C<remove>.

=cut

has networks => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Networks->new(client => $_[0]) },
);

=attr networks

Returns L<API::Docker::API::Networks> instance for network operations like
C<list>, C<create>, C<connect>, and C<disconnect>.

=cut

has volumes => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Volumes->new(client => $_[0]) },
);

=attr volumes

Returns L<API::Docker::API::Volumes> instance for volume operations like
C<list>, C<create>, and C<remove>.

=cut

has exec => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Exec->new(client => $_[0]) },
);

=attr exec

Returns L<API::Docker::API::Exec> instance for executing commands in containers.

=cut

has distribution => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Distribution->new(client => $_[0]) },
);

=attr distribution

Returns L<API::Docker::API::Distribution> instance for registry manifest
lookups: C<inspect> and C<exists>.

=cut

has secrets => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Secrets->new(client => $_[0]) },
);

=attr secrets

Returns L<API::Docker::API::Secrets> instance for secret operations: C<list>,
C<create>, C<inspect>, C<update> and C<remove>.

=cut

has configs => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Configs->new(client => $_[0]) },
);

=attr configs

Returns L<API::Docker::API::Configs> instance for config operations: C<list>,
C<create>, C<inspect>, C<update> and C<remove>.

=cut

has plugins => (
  is      => 'lazy',
  builder => sub { API::Docker::API::Plugins->new(client => $_[0]) },
);

=attr plugins

Returns L<API::Docker::API::Plugins> instance for managed-plugin operations:
C<list>, C<privileges>, C<install>, C<inspect>, C<remove>, C<enable>,
C<disable>, C<upgrade>, C<push> and C<configure>.

=cut

sub negotiate_version {
  my ($self) = @_;
  return if $self->_version_negotiated;
  return if defined $self->api_version;

  $log->debug("Auto-negotiating API version");
  my $version_info = $self->_request('GET', '/version');
  if ($version_info && $version_info->{ApiVersion}) {
    $self->_set_api_version($version_info->{ApiVersion});
    $log->debugf("Negotiated API version: %s", $version_info->{ApiVersion});
  }
  $self->_version_negotiated(1);
}

=method negotiate_version

    $docker->negotiate_version;

Automatically negotiate the highest API version supported by the Docker daemon.
This is called automatically before the first API request if L</api_version>
is not set.

After negotiation, L</api_version> will contain the negotiated version
(e.g., C<1.41>).

=cut

around _request => sub {
  my ($orig, $self, $method, $path, %opts) = @_;

  # Auto-negotiate before any versioned request, but not for /version itself
  if ($path ne '/version' && !defined $self->api_version && !$self->_version_negotiated) {
    $self->negotiate_version;
  }

  return $self->$orig($method, $path, %opts);
};

=head1 CONTAINER ENGINES

This client speaks the Docker Engine HTTP API over a socket. It never shells
out to the C<docker> binary, so any engine serving that API works, whether or
not Docker itself is installed.

=head2 Podman

Podman ships a Docker-compatible API service. Enable its rootless socket and
point L</host> at it:

    systemctl --user enable --now podman.socket
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

The socket announces API version 1.41, which L</negotiate_version> picks up
like any other daemon. Multi-stage builds are passed through unchanged,
C<target> included, down to skipping the stages the target does not depend on.

=head2 Socket discovery

L</host> resolves in two steps and no more: C<$ENV{DOCKER_HOST}>, then
C<unix:///var/run/docker.sock>. It deliberately does B<not> read Docker
contexts. C<currentContext> in F<~/.docker/config.json> and the matching
F<~/.docker/contexts/meta/*/meta.json> are ignored, so if you switch daemons
with C<docker context use>, that choice is not picked up here. Set
C<DOCKER_HOST> explicitly instead.

Other clients sit at different points on that scale. The C<docker> CLI and
docker-java resolve contexts, with C<DOCKER_HOST> outranking them when set.
docker-py's C<from_env()> reads C<DOCKER_HOST> and otherwise falls back to the
default socket, leaving contexts to a separate API. Testcontainers layers its
own F<~/.testcontainers.properties> and a rootless probe list
(C<$XDG_RUNTIME_DIR/docker.sock>, F<~/.docker/run/docker.sock>,
F<~/.docker/desktop/docker.sock>, C</run/user/$UID/docker.sock>) on top.

What none of them do is guess Podman's socket path: that probe list is for
rootless Docker, not for Podman. Every one of those projects documents
C<DOCKER_HOST> as the way to reach Podman, which is the same answer given
above.

=head1 ENVIRONMENT VARIABLES

=over

=item C<DOCKER_HOST>

Docker daemon connection URL. Used as default for L</host> if not explicitly set.

Examples: C<unix:///var/run/docker.sock>, C<tcp://localhost:2375>

Also the supported way to reach a non-Docker engine such as Podman:
C<unix://$XDG_RUNTIME_DIR/podman/podman.sock>. See L</CONTAINER ENGINES>.

=item C<DOCKER_CERT_PATH>

Path to the TLS certificate directory (F<ca.pem>, F<cert.pem>, F<key.pem>).
Used as the default for L</cert_path>, which is read only when L</tls> is set
-- so having it exported, as machines running the C<docker> CLI usually do,
changes nothing for a client that speaks plaintext or over a Unix socket.

=back

=seealso

=over

=item * L<API::Docker::Role::HTTP> - HTTP transport implementation

=item * L<API::Docker::Role::RegistryAuth> - X-Registry-Auth / AuthConfig
encoding

=item * L<API::Docker::Role::Filters> - the C<filters> query parameter

=item * L<API::Docker::API::System> - System and daemon operations

=item * L<API::Docker::API::Containers> - Container management

=item * L<API::Docker::API::Images> - Image management

=item * L<API::Docker::API::Networks> - Network management

=item * L<API::Docker::API::Volumes> - Volume management

=item * L<API::Docker::API::Exec> - Execute commands in containers

=item * L<API::Docker::API::Distribution> - Registry manifest lookups

=item * L<API::Docker::API::Secrets> - Swarm secrets

=item * L<API::Docker::API::Configs> - Swarm configs

=item * L<API::Docker::API::Plugins> - Managed plugins

=back

=cut

1;
