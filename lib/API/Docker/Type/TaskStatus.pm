package API::Docker::Type::TaskStatus;
# ABSTRACT: represents the status of a task
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ContainerStatus;
use API::Docker::Type::PortStatus;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<TaskStatus> definition of C<spec/v1.51.yaml>.

=cut

docker timestamp => Str, since => '1.44';

=attr timestamp

Undocumented upstream. When L</state> was observed:
C<2016-06-07T21:07:31.290032978Z> in the swagger's C<Task> example, between
that task's L<API::Docker::Type::Task/created_at> and its
L<API::Docker::Type::Task/updated_at>.

=cut

docker state => Str, since => '1.44',
  enum => [qw(
    new allocated pending assigned accepted preparing ready starting running
    complete shutdown failed rejected remove orphaned
  )];

=attr state

Undocumented upstream. Where the task actually is, against the
L<API::Docker::Type::Task/desired_state> the orchestrator wants. Both are
C<running> in the swagger's example. The swagger enumerates C<new>,
C<allocated>, C<pending>, C<assigned>, C<accepted>, C<preparing>, C<ready>,
C<starting>, C<running>, C<complete>, C<shutdown>, C<failed>, C<rejected>,
C<remove> and C<orphaned>.

=cut

docker message => Str, since => '1.44';

=attr message

Undocumented upstream. Free text about that state, C<"started"> in the
swagger's C<Task> example.

=cut

docker err => Str, since => '1.44';

=attr err

Undocumented upstream. The failure, as text. The swagger's C<Task> example
shows a task that started and carries no C<Err> at all, only L</message>.

=cut

docker container_status => 'ContainerStatus', since => '1.44';

=attr container_status

Represents the status of a container. See
L<API::Docker::Type::ContainerStatus>.

=cut

docker port_status => 'PortStatus', since => '1.44';

=attr port_status

Represents the port status of a task's host ports whose service has
published host ports. See L<API::Docker::Type::PortStatus>.

=cut

1;
