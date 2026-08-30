package API::Docker::Type::PortStatus;
# ABSTRACT: represents the port status of a task's host ports whose service has published host ports
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PortStatus> definition of C<spec/v1.51.yaml>.

=cut

docker ports => [ 'EndpointPortConfig' ], since => '1.44';

=attr ports

Undocumented upstream. The published ports themselves, the same entries a
service carries under L<API::Docker::Type::Service::Endpoint/ports>. See
L<API::Docker::Type::EndpointPortConfig>.

=cut

1;
