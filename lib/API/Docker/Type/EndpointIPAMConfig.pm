package API::Docker::Type::EndpointIPAMConfig;
# ABSTRACT: An endpoint's IPAM configuration
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<EndpointIPAMConfig> definition of C<spec/v1.51.yaml>.

=cut

docker ipv4_address => Str, wire => 'IPv4Address';

=attr ipv4_address

Undocumented upstream. An IPv4 address for the endpoint, C<172.20.30.33> in
the swagger's example. This is the address configured; the one the endpoint
ends up with is reported separately as
L<API::Docker::Type::EndpointSettings/ip_address>. Serialised as
C<IPv4Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv4Address>.

=cut

docker ipv6_address => Str, wire => 'IPv6Address';

=attr ipv6_address

Undocumented upstream. The IPv6 counterpart of L</ipv4_address>,
C<2001:db8:abcd::3033> in the swagger's example. Serialised as
C<IPv6Address> -- spelled out, because deriving it from the Perl name would
produce C<Ipv6Address>.

=cut

docker link_local_ips => [Str], wire => 'LinkLocalIPs';

=attr link_local_ips

Undocumented upstream. Link-local addresses for the endpoint. The swagger's
example holds one of each family, C<< ["169.254.34.68", "fe80::3468"] >>.
Serialised as C<LinkLocalIPs> -- spelled out, because deriving it from the
Perl name would produce C<LinkLocalIps>.

=cut

1;
