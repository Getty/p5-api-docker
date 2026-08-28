package API::Docker::Type::EndpointIPAMConfig;
# ABSTRACT: An endpoint's IPAM configuration
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<EndpointIPAMConfig> definition of C<spec/v1.51.yaml>.

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

docker link_local_ips => [Str], wire => 'LinkLocalIPs';

=attr link_local_ips

Undocumented upstream. Serialised as C<LinkLocalIPs> -- spelled out, because
deriving it from the Perl name would produce C<LinkLocalIps>.

=cut

1;
