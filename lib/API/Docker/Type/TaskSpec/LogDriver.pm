package API::Docker::Type::TaskSpec::LogDriver;
# ABSTRACT: Specifies the log driver to use for tasks created from this spec
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<LogDriver> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

If not present, the default one for the swarm will be used, finally falling
back to the engine default if not specified.

=cut

docker name => Str;

=attr name

Undocumented upstream.

=cut

docker options => { Str, Str };

=attr options

Undocumented upstream. B<The keys are the caller's data> and are never
translated.

=cut

1;
