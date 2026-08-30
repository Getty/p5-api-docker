package API::Docker::Type::NodeStatus;
# ABSTRACT: The status of a node
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<NodeStatus> definition of C<spec/v1.51.yaml>.

It provides the current status of the node, as seen by the manager.

=cut

docker state => Str, enum => [qw( unknown down ready disconnected )];

=attr state

NodeState represents the state of a node. The swagger enumerates C<unknown>,
C<down>, C<ready> and C<disconnected>.

=cut

docker message => Str;

=attr message

Undocumented upstream. Free text about the node from the manager that
watches it -- the human-readable half of L</state>. The swagger's example is
the empty string.

=cut

docker addr => Str;

=attr addr

IP address of the node.

=cut

1;
