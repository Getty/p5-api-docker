package API::Docker::Type::NetworkSettings;
# ABSTRACT: NetworkSettings exposes the network settings in the API
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Address;
use API::Docker::Type::EndpointSettings;
use API::Docker::Type::PortBinding;

=head1 DESCRIPTION

Generated from the C<NetworkSettings> definition of C<spec/v1.51.yaml>.

=cut

docker bridge => Str;

=attr bridge

Name of the default bridge interface when dockerd's --bridge flag is set.

Deprecated: This field is only set when the daemon is started with the
--bridge flag specified.

=cut

docker sandbox_id => Str, wire => 'SandboxID';

=attr sandbox_id

SandboxID uniquely represents a container's network stack. Serialised as
C<SandboxID> -- spelled out, because deriving it from the Perl name would
produce C<SandboxId>.

=cut

docker hairpin_mode => Bool;

=attr hairpin_mode

Indicates if hairpin NAT should be enabled on the virtual interface.

Deprecated: This field is never set and will be removed in a future release.

=cut

docker link_local_ipv6_address => Str, wire => 'LinkLocalIPv6Address';

=attr link_local_ipv6_address

IPv6 unicast address using the link-local prefix.

Deprecated: This field is never set and will be removed in a future release.
Serialised as C<LinkLocalIPv6Address> -- spelled out, because deriving it
from the Perl name would produce C<LinkLocalIpv6Address>.

=cut

docker link_local_ipv6_prefix_len => Int, wire => 'LinkLocalIPv6PrefixLen';

=attr link_local_ipv6_prefix_len

Prefix length of the IPv6 unicast address.

Deprecated: This field is never set and will be removed in a future release.
Serialised as C<LinkLocalIPv6PrefixLen> -- spelled out, because deriving it
from the Perl name would produce C<LinkLocalIpv6PrefixLen>.

=cut

docker ports => { Str, [ 'PortBinding' ] };

=attr ports

PortMap describes the mapping of container ports to host ports, using the
container's port-number and protocol as key in the format C<<
<port>/<protocol> >>, for example, C<80/udp>.

If a container's port is mapped for multiple protocols, separate entries are
added to the mapping table. See L<API::Docker::Type::PortBinding>. B<The
keys are the caller's data> and are never translated.

=cut

docker sandbox_key => Str;

=attr sandbox_key

SandboxKey is the full path of the netns handle.

=cut

docker secondary_ip_addresses => [ 'Address' ],
  wire => 'SecondaryIPAddresses';

=attr secondary_ip_addresses

Deprecated: This field is never set and will be removed in a future release.
See L<API::Docker::Type::Address>. Serialised as C<SecondaryIPAddresses> --
spelled out, because deriving it from the Perl name would produce
C<SecondaryIpAddresses>.

=cut

docker secondary_ipv6_addresses => [ 'Address' ],
  wire => 'SecondaryIPv6Addresses';

=attr secondary_ipv6_addresses

Deprecated: This field is never set and will be removed in a future release.
See L<API::Docker::Type::Address>. Serialised as C<SecondaryIPv6Addresses>
-- spelled out, because deriving it from the Perl name would produce
C<SecondaryIpv6Addresses>.

=cut

docker endpoint_id => Str, wire => 'EndpointID';

=attr endpoint_id

EndpointID uniquely represents a service endpoint in a Sandbox.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<EndpointID> -- spelled out, because deriving
it from the Perl name would produce C<EndpointId>.

=cut

docker gateway => Str;

=attr gateway

Gateway address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0.

=cut

docker global_ipv6_address => Str, wire => 'GlobalIPv6Address';

=attr global_ipv6_address

Global IPv6 address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<GlobalIPv6Address> -- spelled out, because
deriving it from the Perl name would produce C<GlobalIpv6Address>.

=cut

docker global_ipv6_prefix_len => Int, wire => 'GlobalIPv6PrefixLen';

=attr global_ipv6_prefix_len

Mask length of the global IPv6 address.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<GlobalIPv6PrefixLen> -- spelled out, because
deriving it from the Perl name would produce C<GlobalIpv6PrefixLen>.

=cut

docker ip_address => Str, wire => 'IPAddress';

=attr ip_address

IPv4 address for the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPAddress> -- spelled out, because deriving
it from the Perl name would produce C<IpAddress>.

=cut

docker ip_prefix_len => Int, wire => 'IPPrefixLen';

=attr ip_prefix_len

Mask length of the IPv4 address.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPPrefixLen> -- spelled out, because
deriving it from the Perl name would produce C<IpPrefixLen>.

=cut

docker ipv6_gateway => Str, wire => 'IPv6Gateway';

=attr ipv6_gateway

IPv6 gateway address for this network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0. Serialised as C<IPv6Gateway> -- spelled out, because
deriving it from the Perl name would produce C<Ipv6Gateway>.

=cut

docker mac_address => Str;

=attr mac_address

MAC address for the container on the default "bridge" network.

> B<Deprecated>: This field is only propagated when attached to the >
default "bridge" network. Use the information from the "bridge" > network
inside the C<Networks> map instead, which contains the same > information.
This field was deprecated in Docker 1.9 and is scheduled > to be removed in
Docker 17.12.0.

=cut

docker networks => { Str, 'EndpointSettings' };

=attr networks

Information about all networks that the container is connected to. See
L<API::Docker::Type::EndpointSettings>. B<The keys are the caller's data>
and are never translated.

=cut

1;
