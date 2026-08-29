package API::Docker::Type::Service::Endpoint::VirtualIP;
# ABSTRACT: One entry of C<Service.Endpoint.VirtualIPs>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Service.Endpoint.VirtualIPs>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker network_id => Str, wire => 'NetworkID';

=attr network_id

Undocumented upstream. The network the address is on,
C<4qvuz4ko70xaltuqbt8956gd1> on both entries of the swagger's C<Service>
example. Serialised as C<NetworkID> -- spelled out, because deriving it from
the Perl name would produce C<NetworkId>.

=cut

docker addr => Str;

=attr addr

Undocumented upstream. The address with its prefix length, C<10.255.0.2/16>
in that example -- CIDR, the way
L<API::Docker::Type::NetworkContainer/ipv4_address> is and
L<API::Docker::Type::EndpointSettings/ip_address> is not.

=cut

1;
