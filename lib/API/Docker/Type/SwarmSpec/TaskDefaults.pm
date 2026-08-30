package API::Docker::Type::SwarmSpec::TaskDefaults;
# ABSTRACT: Defaults for creating tasks in this cluster
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::SwarmSpec::TaskDefaults::LogDriver;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<TaskDefaults> schema of the C<SwarmSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker log_driver => 'SwarmSpec::TaskDefaults::LogDriver';

=attr log_driver

The log driver to use for tasks created in the orchestrator if unspecified
by a service.

Updating this value only affects new tasks. Existing tasks continue to use
their previously configured log driver until recreated. See
L<API::Docker::Type::SwarmSpec::TaskDefaults::LogDriver>.

=cut

1;
