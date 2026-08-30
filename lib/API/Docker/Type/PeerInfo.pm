package API::Docker::Type::PeerInfo;
# ABSTRACT: One peer of an overlay network
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PeerInfo> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

ID of the peer-node in the Swarm cluster.

=cut

docker ip => Str, wire => 'IP';

=attr ip

IP-address of the peer-node in the Swarm cluster. Serialised as C<IP> --
spelled out, because deriving it from the Perl name would produce C<Ip>.

=cut

1;
