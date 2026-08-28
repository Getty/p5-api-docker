package API::Docker::Type::ContainerStatus;
# ABSTRACT: represents the status of a container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerStatus> definition of C<spec/v1.51.yaml>.

=cut

docker container_id => Str, wire => 'ContainerID', since => '1.44';

=attr container_id

Undocumented upstream. Serialised as C<ContainerID> -- spelled out, because
deriving it from the Perl name would produce C<ContainerId>.

=cut

docker pid => Int, wire => 'PID', since => '1.44';

=attr pid

Undocumented upstream. Serialised as C<PID> -- spelled out, because deriving
it from the Perl name would produce C<Pid>.

=cut

docker exit_code => Int, since => '1.44';

=attr exit_code

Undocumented upstream.

=cut

1;
