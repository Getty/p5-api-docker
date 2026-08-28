package API::Docker::Type::Service::Endpoint::VirtualIP;
# ABSTRACT: One entry of C<Service.Endpoint.VirtualIPs>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Service.Endpoint.VirtualIPs>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker network_id => Str, wire => 'NetworkID';

=attr network_id

Undocumented upstream. Serialised as C<NetworkID> -- spelled out, because
deriving it from the Perl name would produce C<NetworkId>.

=cut

docker addr => Str;

=attr addr

Undocumented upstream.

=cut

1;
