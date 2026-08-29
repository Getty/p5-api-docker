package API::Docker::Type::SwarmInfo;
# ABSTRACT: Represents generic information about swarm
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ClusterInfo;
use API::Docker::Type::PeerNode;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<SwarmInfo> definition of C<spec/v1.51.yaml>.

=cut

docker node_id => Str, wire => 'NodeID';

=attr node_id

Unique identifier of for this node in the swarm. The daemon defaults it to .
Serialised as C<NodeID> -- spelled out, because deriving it from the Perl
name would produce C<NodeId>.

=cut

docker node_addr => Str;

=attr node_addr

IP address at which this node can be reached by other nodes in the swarm.
The daemon defaults it to .

=cut

docker local_node_state => Str,
  enum => [ '', 'inactive', 'pending', 'active', 'error', 'locked' ];

=attr local_node_state

Current local status of this node. The swagger enumerates the empty string,
C<inactive>, C<pending>, C<active>, C<error> and C<locked>.

=cut

docker control_available => Bool;

=attr control_available

Undocumented upstream. A boolean, defaulted to C<false> upstream and C<true>
in the example, standing beside L</local_node_state> and L</managers>.
Measured against Podman 5.8.4 (API 1.44), C<GET /info> answers a complete
C<Swarm> block -- C<ControlAvailable> C<false>, C<LocalNodeState>
C<inactive> -- on an engine running no swarm at all.

=cut

docker error => Str;

=attr error

Undocumented upstream. Defaulted to the empty string upstream, which is also
what that same Podman 5.8.4 measurement answers.

=cut

docker remote_managers => [ 'PeerNode' ];

=attr remote_managers

List of ID's and addresses of other managers in the swarm. See
L<API::Docker::Type::PeerNode>. The daemon defaults it to null.

=cut

docker nodes => Int;

=attr nodes

Total number of nodes in the swarm.

=cut

docker managers => Int;

=attr managers

Total number of managers in the swarm.

=cut

docker cluster => 'ClusterInfo';

=attr cluster

ClusterInfo represents information about the swarm as is returned by the
"/info" endpoint. See L<API::Docker::Type::ClusterInfo>.

=cut

1;
