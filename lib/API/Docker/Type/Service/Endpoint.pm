package API::Docker::Type::Service::Endpoint;
# ABSTRACT: The resolved endpoint of a service
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use API::Docker::Type::EndpointSpec;
use API::Docker::Type::Service::Endpoint::VirtualIP;

=head1 DESCRIPTION

Generated from the inline C<Endpoint> schema of the C<Service> definition in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. The specification
a service was asked for, alongside the ports and virtual IPs the swarm
actually gave it.

=cut

docker spec => 'EndpointSpec';

=attr spec

Properties that can be configured to access and load balance a service. See
L<API::Docker::Type::EndpointSpec>.

=cut

docker ports => [ 'EndpointPortConfig' ];

=attr ports

Undocumented upstream. See L<API::Docker::Type::EndpointPortConfig>.

=cut

docker virtual_ips => [ 'Service::Endpoint::VirtualIP' ],
  wire => 'VirtualIPs';

=attr virtual_ips

Undocumented upstream. See
L<API::Docker::Type::Service::Endpoint::VirtualIP>. Serialised as
C<VirtualIPs> -- spelled out, because deriving it from the Perl name would
produce C<VirtualIps>.

=cut

1;
