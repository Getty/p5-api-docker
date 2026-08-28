package API::Docker::Type::ContainerState;
# ABSTRACT: Container's running state
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Health;

=head1 DESCRIPTION

Generated from the C<ContainerState> definition of C<spec/v1.51.yaml>.

It's part of ContainerJSONBase and will be returned by the "inspect"
command.

=cut

docker status => Str,
  enum => [qw( created running paused restarting removing exited dead )];

=attr status

String representation of the container state. Can be one of "created",
"running", "paused", "restarting", "removing", "exited", or "dead".

=cut

docker running => Bool;

=attr running

Whether this container is running.

Note that a running container can be I<paused>. The C<Running> and C<Paused>
booleans are not mutually exclusive:

When pausing a container (on Linux), the freezer cgroup is used to suspend
all processes in the container. Freezing the process requires the process to
be running. As a result, paused containers are both C<Running> I<and>
C<Paused>.

Use the C<Status> field instead to determine if a container's state is
"running".

=cut

docker paused => Bool;

=attr paused

Whether this container is paused.

=cut

docker restarting => Bool;

=attr restarting

Whether this container is restarting.

=cut

docker oom_killed => Bool, wire => 'OOMKilled';

=attr oom_killed

Whether a process within this container has been killed because it ran out
of memory since the container was last started. Serialised as C<OOMKilled>
-- spelled out, because deriving it from the Perl name would produce
C<OomKilled>.

=cut

docker dead => Bool;

=attr dead

Undocumented upstream.

=cut

docker pid => Int;

=attr pid

The process ID of this container.

=cut

docker exit_code => Int;

=attr exit_code

The last exit code of this container.

=cut

docker error => Str;

=attr error

Undocumented upstream.

=cut

docker started_at => Str;

=attr started_at

The time when this container was last started.

=cut

docker finished_at => Str;

=attr finished_at

The time when this container last exited.

=cut

docker health => 'Health';

=attr health

Health stores information about the container's healthcheck results. See
L<API::Docker::Type::Health>.

=cut

1;
