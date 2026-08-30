package API::Docker::Type::SwarmSpec::TaskDefaults::LogDriver;
# ABSTRACT: The log driver to use for tasks created in the orchestrator if unspecified by a service
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<LogDriver> schema of C<SwarmSpec.TaskDefaults>
in C<spec/v1.51.yaml>.

Updating this value only affects new tasks. Existing tasks continue to use
their previously configured log driver until recreated.

=cut

docker name => Str;

=attr name

The log driver to use as a default for new tasks.

=cut

docker options => { Str, Str };

=attr options

Driver-specific options for the selected log driver, specified as key/value
pairs. B<The keys are the caller's data> and are never translated.

=cut

1;
