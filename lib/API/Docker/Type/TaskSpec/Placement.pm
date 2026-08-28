package API::Docker::Type::TaskSpec::Placement;
# ABSTRACT: Where in the swarm a task may be scheduled
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Platform;
use API::Docker::Type::TaskSpec::Placement::Preference;

=head1 DESCRIPTION

Generated from the inline C<Placement> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Hard
constraints, soft preferences, the platforms the task can run on, and a cap
on how many replicas one node may take.

=cut

docker constraints => [Str];

=attr constraints

An array of constraint expressions to limit the set of nodes where a task
can be scheduled. Constraint expressions can either use a I<match> (C<==>)
or I<exclude> (C<!=>) rule. Multiple constraints find nodes that satisfy
every expression (AND match). Constraints can match node or Docker Engine
labels as follows:

node attribute | matches | example
---------------------|--------------------------------|-----------------------------------------------
C<node.id> | Node ID | C<node.id==2ivku8v2gvtg4> C<node.hostname> | Node
hostname | C<node.hostname!=node-2> C<node.role> | Node role
(C<manager>/C<worker>) | C<node.role==manager> C<node.platform.os> | Node
operating system | C<node.platform.os==windows> C<node.platform.arch> | Node
architecture | C<node.platform.arch==x86_64> C<node.labels> | User-defined
node labels | C<node.labels.security==high> C<engine.labels> | Docker
Engine's labels | C<engine.labels.operatingsystem==ubuntu-24.04>

C<engine.labels> apply to Docker Engine labels like operating system,
drivers, etc. Swarm administrators add C<node.labels> for operational
purposes by using the [C<node update endpoint>](#operation/NodeUpdate).

=cut

docker preferences => [ 'TaskSpec::Placement::Preference' ];

=attr preferences

Preferences provide a way to make the scheduler aware of factors such as
topology. They are provided in order from highest to lowest precedence. See
L<API::Docker::Type::TaskSpec::Placement::Preference>.

=cut

docker max_replicas => Int;

=attr max_replicas

Maximum number of replicas for per node (default value is 0, which is
unlimited).

=cut

docker platforms => [ 'Platform' ];

=attr platforms

Platforms stores all the platforms that the service's image can run on. This
field is used in the platform filter for scheduling. If empty, then the
platform filter is off, meaning there are no scheduling restrictions. See
L<API::Docker::Type::Platform>.

=cut

1;
