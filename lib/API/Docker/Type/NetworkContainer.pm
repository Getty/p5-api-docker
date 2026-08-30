package API::Docker::Type::NetworkContainer;
# ABSTRACT: One value of C<Network.Containers>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<NetworkContainer> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one value of C<Network.Containers>. The keys of that map are
container IDs, and the swagger describes the field holding it as containing
the endpoints attached to the network.

=cut

docker name => Str;

=attr name

Undocumented upstream. The container's name, C<container_1> in the swagger's
example.

=cut

docker endpoint_id => Str, wire => 'EndpointID';

=attr endpoint_id

Undocumented upstream. The endpoint's ID, the value the swagger describes
under L<API::Docker::Type::EndpointSettings/endpoint_id> as unique for a
service endpoint in a sandbox. Serialised as C<EndpointID> -- spelled out,
because deriving it from the Perl name would produce C<EndpointId>.

=cut

docker mac_address => Str;

=attr mac_address

Undocumented upstream. The endpoint's MAC address on this network, which the
swagger notes under L<API::Docker::Type::EndpointSettings/mac_address> a
network driver may ignore.

=cut

docker ipv4_address => Str, wire => 'IPv4Address';

=attr ipv4_address

Undocumented upstream. The address with its prefix length, C<172.19.0.2/16>
in the swagger's example -- not the bare address
L<API::Docker::Type::EndpointSettings/ip_address> carries. Serialised as
C<IPv4Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv4Address>.

=cut

docker ipv6_address => Str, wire => 'IPv6Address';

=attr ipv6_address

Undocumented upstream. The IPv6 counterpart of L</ipv4_address>, empty in
the swagger's example, where the network has none. Serialised as
C<IPv6Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv6Address>.

=cut

1;
