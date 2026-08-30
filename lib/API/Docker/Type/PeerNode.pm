package API::Docker::Type::PeerNode;
# ABSTRACT: Represents a peer-node in the swarm
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PeerNode> definition of C<spec/v1.51.yaml>.

=cut

docker node_id => Str, wire => 'NodeID';

=attr node_id

Unique identifier of for this node in the swarm. Serialised as C<NodeID> --
spelled out, because deriving it from the Perl name would produce C<NodeId>.

=cut

docker addr => Str;

=attr addr

IP address and ports at which this node can be reached.

=cut

1;
