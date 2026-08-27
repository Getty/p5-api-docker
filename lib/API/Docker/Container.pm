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
has Command       => (is => 'ro');
has Created       => (is => 'ro');

=attr Created

Container creation timestamp (Unix epoch).

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
has Labels        => (is => 'ro');
has SizeRw        => (is => 'ro');
has SizeRootFs    => (is => 'ro');
has HostConfig    => (is => 'ro');
has NetworkSettings => (is => 'ro');
has Mounts        => (is => 'ro');

has Name          => (is => 'ro');

=attr Name

Container name (from C<inspect>, includes leading C</>).

=cut

has RestartCount  => (is => 'ro');
has Driver        => (is => 'ro');
has Platform      => (is => 'ro');
has Path          => (is => 'ro');
has Args          => (is => 'ro');
has Config        => (is => 'ro');

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

Attach to the container's output and return its frames. This is the one-way
attach and, without a callback, it blocks until the stream ends -- see
L<API::Docker::API::Containers/attach> before reaching for it on a container
that keeps running. C<on_frame> is passed through and reads the stream as it
arrives instead.

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
