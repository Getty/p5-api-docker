package API::Docker::Type::PortStatus;
# ABSTRACT: represents the port status of a task's host ports whose service has published host ports
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;

=head1 DESCRIPTION

Generated from the C<PortStatus> definition of C<spec/v1.51.yaml>.

=cut

docker ports => [ 'EndpointPortConfig' ], since => '1.44';

=attr ports

Undocumented upstream. See L<API::Docker::Type::EndpointPortConfig>.

=cut

1;
