package API::Docker::Type::ContainerStatus;
# ABSTRACT: represents the status of a container
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerStatus> definition of C<spec/v1.51.yaml>.

=cut

docker container_id => Str, wire => 'ContainerID', since => '1.44';

=attr container_id

Undocumented upstream. The container a swarm task is running in -- the
object hangs off L<API::Docker::Type::TaskStatus/container_status> -- and an
ordinary container ID that C<GET /containers/{id}/json> will take. The
swagger's C<Task> example carries a 64-character hex digest. Serialised as
C<ContainerID> -- spelled out, because deriving it from the Perl name would
produce C<ContainerId>.

=cut

docker pid => Int, wire => 'PID', since => '1.44';

=attr pid

Undocumented upstream. Its process ID, the measure the swagger describes
under L<API::Docker::Type::ContainerState/pid>. C<677> in the swagger's
C<Task> example. Serialised as C<PID> -- spelled out, because deriving it
from the Perl name would produce C<Pid>.

=cut

docker exit_code => Int, since => '1.44';

=attr exit_code

Undocumented upstream. Its last exit code, the measure the swagger describes
under L<API::Docker::Type::ContainerState/exit_code>. Absent from the
C<Task> example, whose container is still running.

=cut

1;
