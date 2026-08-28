package API::Docker::Type::TaskStatus;
# ABSTRACT: represents the status of a task
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ContainerStatus;
use API::Docker::Type::PortStatus;

=head1 DESCRIPTION

Generated from the C<TaskStatus> definition of C<spec/v1.51.yaml>.

=cut

docker timestamp => Str, since => '1.44';

=attr timestamp

Undocumented upstream.

=cut

docker state => Str, since => '1.44',
  enum => [qw(
    new allocated pending assigned accepted preparing ready starting running
    complete shutdown failed rejected remove orphaned
  )];

=attr state

Undocumented upstream. The swagger enumerates C<new>, C<allocated>,
C<pending>, C<assigned>, C<accepted>, C<preparing>, C<ready>, C<starting>,
C<running>, C<complete>, C<shutdown>, C<failed>, C<rejected>, C<remove> and
C<orphaned>.

=cut

docker message => Str, since => '1.44';

=attr message

Undocumented upstream.

=cut

docker err => Str, since => '1.44';

=attr err

Undocumented upstream.

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
