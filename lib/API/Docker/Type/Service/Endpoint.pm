package API::Docker::Type::Service::Endpoint;
# ABSTRACT: The resolved endpoint of a service
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use API::Docker::Type::EndpointSpec;
use API::Docker::Type::Service::Endpoint::VirtualIP;
use namespace::clean;

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

Undocumented upstream. The ports as published. In the swagger's C<Service>
example they are the very entry C<Spec.Ports> asked for -- C<tcp>, target
C<6379>, published C<30001>. See L<API::Docker::Type::EndpointPortConfig>.

=cut

docker virtual_ips => [ 'Service::Endpoint::VirtualIP' ],
  wire => 'VirtualIPs';

=attr virtual_ips

Undocumented upstream. One entry per virtual IP the routing mesh gave the
service. The swagger's C<Service> example carries two, C<10.255.0.2/16> and
C<10.255.0.3/16>, both on the same network. See
L<API::Docker::Type::Service::Endpoint::VirtualIP>. Serialised as
C<VirtualIPs> -- spelled out, because deriving it from the Perl name would
produce C<VirtualIps>.

=cut

1;
