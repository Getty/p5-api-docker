package API::Docker::Type::Node;
# ABSTRACT: One entry of the C<200> response to C<GET /nodes>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ManagerStatus;
use API::Docker::Type::NodeDescription;
use API::Docker::Type::NodeSpec;
use API::Docker::Type::NodeStatus;
use API::Docker::Type::ObjectVersion;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Node> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /nodes> and the body of the C<200> response to
C<GET /nodes/{id}>.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. The node's ID in the swarm, C<24ifsmvkjbyhk> in the
swagger's example, and what the C</nodes/{id}> endpoints take in their path.
Serialised as C<ID> -- spelled out, because deriving it from the Perl name
would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Date and time at which the node was added to the swarm in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker updated_at => Str;

=attr updated_at

Date and time at which the node was last updated in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker spec => 'NodeSpec';

=attr spec

Undocumented upstream. The name, role, availability and labels an operator
set on the node -- C<< {"Name": "node-name", "Role": "manager",
"Availability": "active", "Labels": {"foo": "bar"}} >> in that definition's
own example. L</description> is what the node itself reports back instead.
See L<API::Docker::Type::NodeSpec>.

=cut

docker description => 'NodeDescription';

=attr description

NodeDescription encapsulates the properties of the Node as reported by the
agent. See L<API::Docker::Type::NodeDescription>.

=cut

docker status => 'NodeStatus';

=attr status

NodeStatus represents the status of a node. See
L<API::Docker::Type::NodeStatus>.

=cut

docker manager_status => 'ManagerStatus';

=attr manager_status

ManagerStatus represents the status of a manager. See
L<API::Docker::Type::ManagerStatus>.

=cut

1;
