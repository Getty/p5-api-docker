package API::Docker::Container;
# ABSTRACT: Docker container entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Get container from list or inspect
    my $containers = $docker->containers->list;
    my $container = $containers->[0];

    # Access container properties
    say $container->Id;
    say $container->Status;
    say $container->Image;

    # Perform operations
    $container->start;
    $container->stop(timeout => 10);
    my $logs = $container->logs(tail => 100);
    $container->remove(force => 1);

    # Check state
    if ($container->is_running) {
        say "Container is running";
    }

=head1 DESCRIPTION

This class represents a Docker container and provides convenient access to
container properties and operations. Instances are returned by
L<API::Docker::API::Containers> methods like C<list> and C<inspect>.

Each attribute corresponds to fields in the Docker API container representation.
Methods delegate to L<API::Docker::API::Containers> for operations.

Every field below carries an C<=attr> block, and that list is also the
object's whole field surface: Moo's default constructor silently drops any
key in the daemon's response that has no matching C<has>, so there is no
additional, undocumented attribute waiting on the instance -- only daemon
fields this class does not keep at all. C<list> and C<inspect> return
different, overlapping subsets of it, noted per attribute below.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Used for delegating operations.

=cut

has Id            => (is => 'ro');

=attr Id

Container ID (64-character hex string).

=cut

has Names         => (is => 'ro');

=attr Names

ArrayRef of container names (from C<list>).

=cut

has Image         => (is => 'ro');

=attr Image

Image name used to create the container.

=cut

has ImageID       => (is => 'ro');

=attr ImageID

The image's ID (C<sha256:...> digest) the container was created from.
Present in the C<list> shape (F<t/fixtures/containers_list.json>) alongside
L</Image>, which there holds the human-readable name (C<nginx:latest>).
C<inspect> reports the digest directly as L</Image> instead and carries no
separate C<ImageID> -- see F<t/fixtures/container_inspect.json>.

=cut

has Command       => (is => 'ro');

=attr Command

The command the container runs, as one string (C<list> only, e.g.
C<"nginx -g 'daemon off;'">). C<inspect> gives the same information split
into L</Path> and L</Args> instead, plus the original C<Cmd> ArrayRef under
L</Config>.

=cut

has Created       => (is => 'ro');

=attr Created

Container creation timestamp. An integer Unix epoch from C<list> (e.g.
C<1705300000> in F<t/fixtures/containers_list.json>), but an RFC3339 string
from C<inspect> (e.g. C<"2025-01-15T08:00:00.000000000Z"> in
F<t/fixtures/container_inspect.json>) -- same field name, two shapes,
depending on which call produced the object.

=cut

has State         => (is => 'ro');

=attr State

Container state. From C<list>: string like C<running>, C<exited>. From
C<inspect>: hashref with C<Running>, C<Paused>, C<ExitCode>, etc.

=cut

has Status        => (is => 'ro');

=attr Status

Human-readable status string (e.g., "Up 2 hours").

=cut

has Ports         => (is => 'ro');

=attr Ports

ArrayRef of HashRefs describing published ports (C<list> only), each with
C<IP>, C<PrivatePort>, C<PublicPort> and C<Type> -- see
F<t/fixtures/containers_list.json>. C<inspect> reports port bindings
differently, nested under L</NetworkSettings>.

=cut

has Labels        => (is => 'ro');

=attr Labels

HashRef of the container's labels (C<list> only; C<{}> when there are none).
C<inspect> carries the same information under C<< Config->{Labels} >>
instead -- see L</Config>.

=cut

has SizeRw        => (is => 'ro');

=attr SizeRw

Size in bytes of files created or changed by the container, relative to its
image (C<list> only).

=cut

has SizeRootFs    => (is => 'ro');

=attr SizeRootFs

Total size in bytes of all files in the container's filesystem (C<list>
only).

=cut

has HostConfig    => (is => 'ro');

=attr HostConfig

HashRef of the container's host configuration. C<list>
(F<t/fixtures/containers_list.json>) reports just C<NetworkMode>; C<inspect>
(F<t/fixtures/container_inspect.json>) additionally carries
C<RestartPolicy>. The real daemon response for either call is considerably
larger than either fixture captured here shows.

=cut

has NetworkSettings => (is => 'ro');

=attr NetworkSettings

HashRef of the container's network state, keyed under C<Networks> by network
name (C<IPAddress>, C<Gateway>, ...). C<inspect> additionally carries
C<Bridge> and a C<Ports> mapping of container port to host bindings, which is
not the same structure as the top-level L</Ports> that C<list> returns.

=cut

has Mounts        => (is => 'ro');

=attr Mounts

ArrayRef of the container's mounts. Empty in every fixture captured here, so
the per-mount shape (source, destination, mode, ...) is not verified against
a real, non-empty response.

=cut

has Name          => (is => 'ro');

=attr Name

Container name (from C<inspect>, includes leading C</>).

=cut

has RestartCount  => (is => 'ro');

=attr RestartCount

Number of times the daemon has restarted the container (C<inspect> only;
C<0> in F<t/fixtures/container_inspect.json>).

=cut

has Driver        => (is => 'ro');

=attr Driver

The storage driver backing the container's filesystem (C<inspect> only, e.g.
C<overlay2>).

=cut

has Platform      => (is => 'ro');

=attr Platform

The OS platform the container runs under (C<inspect> only, e.g. C<linux>).

=cut

has Path          => (is => 'ro');

=attr Path

The executable that was run as the container's entrypoint (C<inspect> only,
e.g. C<nginx>). Paired with L</Args>.

=cut

has Args          => (is => 'ro');

=attr Args

ArrayRef of the arguments passed to L</Path> (C<inspect> only).

=cut

has Config        => (is => 'ro');

=attr Config

HashRef of the container's static configuration as it was created --
C<Hostname>, C<Env>, C<Cmd>, C<Image>, C<Labels> in
F<t/fixtures/container_inspect.json>, though the real daemon response
carries more. C<inspect> only.

=cut

sub start {
  my ($self) = @_;
  return $self->client->containers->start($self->Id);
}

=method start

    $container->start;

    say 'was already running' unless $container->start;

Start the container. Returns 1 when it was started and 0 when it was already
running. Delegates to L<API::Docker::API::Containers/start>, which documents
what that 0 replaces.

=cut

sub stop {
  my ($self, %opts) = @_;
  return $self->client->containers->stop($self->Id, %opts);
}

=method stop

    $container->stop(timeout => 10);

Stop the container. Returns 1 when it was stopped and 0 when it was already
stopped. Delegates to L<API::Docker::API::Containers/stop>.

=cut

sub restart {
  my ($self, %opts) = @_;
  return $self->client->containers->restart($self->Id, %opts);
}

=method restart

    $container->restart;

Restart the container. Returns 1/0 as L<API::Docker::API::Containers/restart>
does; no engine measured here answers a restart with 304, so it is 1.

=cut

sub kill {
  my ($self, %opts) = @_;
  return $self->client->containers->kill($self->Id, %opts);
}

=method kill

    $container->kill(signal => 'SIGTERM');

Send a signal to the container.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->containers->remove($self->Id, %opts);
}

=method remove

    $container->remove(force => 1);

Remove the container.

=cut

sub logs {
  my ($self, %opts) = @_;
  return $self->client->containers->logs($self->Id, %opts);
}

=method logs

    my $logs = $container->logs(tail => 100);

    # or follow it, one frame at a time
    $container->logs(follow => 1, tail => 0,
        on_frame => sub { print $_[0]{data} });

Get container logs. Every option goes to
L<API::Docker::API::Containers/logs>, C<follow> and C<on_frame> included; with
a callback the return value is that method's summary HashRef rather than the
frames.

=cut

sub attach {
  my ($self, %opts) = @_;
  return $self->client->containers->attach($self->Id, %opts);
}

=method attach

    my $frames = $container->attach;

Attach to the container's output and return the frames, one-way. Every option
goes to L<API::Docker::API::Containers/attach>, C<on_frame> included; with a
callback the return value is that method's summary HashRef rather than the
frames. Without options it replays what the container already wrote and
returns; C<< stream => 1 >> on a container that is not running never
returns -- not even with a callback -- see
L<API::Docker::API::Containers/"The defaults follow the engine">.

B<The container must be running.> Attaching to one that has already exited
destroys its exit status on Podman, so the call checks first and croaks rather
than attaching; L</logs> is how a finished container's output is read.
C<< require_running => 0 >> attaches anyway. The check is a pre-flight one and
does not close the race against a container stopping underneath it -- see
L<API::Docker::API::Containers/"This method refuses a container that is not running">.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->containers->inspect($self->Id);
}

=method inspect

    my $updated = $container->inspect;

Get fresh container information.

=cut

sub pause {
  my ($self) = @_;
  return $self->client->containers->pause($self->Id);
}

=method pause

    $container->pause;

Pause all processes in the container. Returns 1/0 as
L<API::Docker::API::Containers/pause> does; an already-paused container is an
error there, not a 0.

=cut

sub unpause {
  my ($self) = @_;
  return $self->client->containers->unpause($self->Id);
}

=method unpause

    $container->unpause;

Unpause the container. Returns 1/0 as
L<API::Docker::API::Containers/unpause> does.

=cut

sub top {
  my ($self, %opts) = @_;
  return $self->client->containers->top($self->Id, %opts);
}

=method top

    my $processes = $container->top;

List running processes in the container.

=cut

sub stats {
  my ($self, %opts) = @_;
  return $self->client->containers->stats($self->Id, %opts);
}

=method stats

    my $stats = $container->stats;

    # or follow the readings
    $container->stats(stream => 1, on_event => sub { ... });

Get resource usage statistics. Every option goes to
L<API::Docker::API::Containers/stats>, C<stream> and C<on_event> included;
with a callback the return value is that method's summary HashRef rather than
the readings.

=cut

sub changes {
  my ($self) = @_;
  return $self->client->containers->changes($self->Id);
}

=method changes

    for my $change (@{ $container->changes }) { ... }

Paths that differ from the image, as C<< { Path => ..., Kind => ... } >>.
Delegates to L<API::Docker::API::Containers/changes>, which documents what the
three C<Kind> numbers mean.

=cut

sub export {
  my ($self) = @_;
  return $self->client->containers->export($self->Id);
}

=method export

    my $tar = $container->export;

The container's filesystem as raw tar bytes.

=cut

sub resize {
  my ($self, %opts) = @_;
  return $self->client->containers->resize($self->Id, %opts);
}

=method resize

    $container->resize(h => 40, w => 120);

Resize the container's TTY.

=cut

sub get_archive {
  my ($self, %opts) = @_;
  return $self->client->containers->get_archive($self->Id, %opts);
}

=method get_archive

    my $tar = $container->get_archive(path => '/etc/hostname');

Read a path out of the container as raw tar bytes.

=cut

sub put_archive {
  my ($self, $tar, %opts) = @_;
  return $self->client->containers->put_archive($self->Id, $tar, %opts);
}

=method put_archive

    $container->put_archive($tar, path => '/opt/app');

Unpack a tar archive into a directory in the container.

=cut

sub stat_archive {
  my ($self, %opts) = @_;
  return $self->client->containers->stat_archive($self->Id, %opts);
}

=method stat_archive

    my $stat = $container->stat_archive(path => '/etc/hostname');

Stat a path in the container without transferring it.

=cut

sub is_running {
  my ($self) = @_;
  my $state = $self->State;
  return 0 unless defined $state;
  if (ref $state eq 'HASH') {
    return $state->{Running} ? 1 : 0;
  }
  return lc($state) eq 'running' ? 1 : 0;
}

=method is_running

    if ($container->is_running) { ... }

Returns true if container is running, false otherwise. Works with both C<list>
and C<inspect> response formats.

=cut

=seealso

=over

=item * L<API::Docker::API::Containers> - Container API operations

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
