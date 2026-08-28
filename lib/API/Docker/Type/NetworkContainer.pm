package API::Docker::Type::NetworkContainer;
# ABSTRACT: One value of C<Network.Containers>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<NetworkContainer> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one value of C<Network.Containers>.

=cut

docker name => Str;

=attr name

Undocumented upstream.

=cut

docker endpoint_id => Str, wire => 'EndpointID';

=attr endpoint_id

Undocumented upstream. Serialised as C<EndpointID> -- spelled out, because
deriving it from the Perl name would produce C<EndpointId>.

=cut

docker mac_address => Str;

=attr mac_address

Undocumented upstream.

=cut

docker ipv4_address => Str, wire => 'IPv4Address';

=attr ipv4_address

Undocumented upstream. Serialised as C<IPv4Address> -- spelled out, because
deriving it from the Perl name would produce C<Ipv4Address>.

=cut

docker ipv6_address => Str, wire => 'IPv6Address';

=attr ipv6_address

Undocumented upstream. Serialised as C<IPv6Address> -- spelled out, because
deriving it from the Perl name would produce C<Ipv6Address>.

=cut

1;
