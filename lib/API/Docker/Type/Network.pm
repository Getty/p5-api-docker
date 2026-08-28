package API::Docker::Type::Network;
# ABSTRACT: One entry of the C<200> response to C<GET /networks>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ConfigReference;
use API::Docker::Type::IPAM;
use API::Docker::Type::NetworkContainer;
use API::Docker::Type::PeerInfo;

=head1 DESCRIPTION

Generated from the C<Network> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /networks> and the body of the C<200> response to
C<GET /networks/{id}>.

=cut

docker name => Str;

=attr name

Name of the network.

=cut

docker id => Str;

=attr id

ID that uniquely identifies a network on a single machine.

=cut

docker created => Str;

=attr created

Date and time at which the network was created in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker scope => Str;

=attr scope

The level at which the network exists (e.g. C<swarm> for cluster-wide or
C<local> for machine level).

=cut

docker driver => Str;

=attr driver

The name of the driver used to create the network (e.g. C<bridge>,
C<overlay>).

=cut

docker enable_ipv4 => Bool, wire => 'EnableIPv4', since => '1.51';

=attr enable_ipv4

Whether the network was created with IPv4 enabled. Serialised as
C<EnableIPv4> -- spelled out, because deriving it from the Perl name would
produce C<EnableIpv4>.

=cut

docker enable_ipv6 => Bool, wire => 'EnableIPv6';

=attr enable_ipv6

Whether the network was created with IPv6 enabled. Serialised as
C<EnableIPv6> -- spelled out, because deriving it from the Perl name would
produce C<EnableIpv6>.

=cut

docker ipam => 'IPAM', wire => 'IPAM';

=attr ipam

Undocumented upstream. See L<API::Docker::Type::IPAM>. Serialised as C<IPAM>
-- spelled out, because deriving it from the Perl name would produce
C<Ipam>.

=cut

docker internal => Bool;

=attr internal

Whether the network is created to only allow internal networking
connectivity. The daemon defaults it to false.

=cut

docker attachable => Bool;

=attr attachable

Whether a global / swarm scope network is manually attachable by regular
containers from workers in swarm mode. The daemon defaults it to false.

=cut

docker ingress => Bool;

=attr ingress

Whether the network is providing the routing-mesh for the swarm cluster. The
daemon defaults it to false.

=cut

docker config_from => 'ConfigReference';

=attr config_from

The config-only network source to provide the configuration for this
network. See L<API::Docker::Type::ConfigReference>.

=cut

docker config_only => Bool;

=attr config_only

Whether the network is a config-only network. Config-only networks are
placeholder networks for network configurations to be used by other
networks. Config-only networks cannot be used directly to run containers or
services. The daemon defaults it to false.

=cut

docker containers => { Str, 'NetworkContainer' };

=attr containers

Contains endpoints attached to the network. See
L<API::Docker::Type::NetworkContainer>. B<The keys are the caller's data>
and are never translated.

=cut

docker options => { Str, Str };

=attr options

Network-specific options uses when creating the network. B<The keys are the
caller's data> and are never translated.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker peers => [ 'PeerInfo' ];

=attr peers

List of peer nodes for an overlay network. This field is only present for
overlay networks, and omitted for other network types. See
L<API::Docker::Type::PeerInfo>.

=cut

1;
