package API::Docker::Type::SwarmSpec::Orchestration;
# ABSTRACT: Orchestration configuration
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Orchestration> schema of the C<SwarmSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker task_history_retention_limit => Int;

=attr task_history_retention_limit

The number of historic tasks to keep per instance or node. If negative,
never remove completed or failed tasks.

=cut

1;
