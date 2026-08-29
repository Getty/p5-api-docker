package API::Docker::Type::TaskSpec::LogDriver;
# ABSTRACT: Specifies the log driver to use for tasks created from this spec
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<LogDriver> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

If not present, the default one for the swarm will be used, finally falling
back to the engine default if not specified.

=cut

docker name => Str;

=attr name

Undocumented upstream. The driver, named the way
L<API::Docker::Type::HostConfig::LogConfig/type> names it for a container.
The field holding this object says an absent log driver falls back to the
swarm's default and then to the engine's.

=cut

docker options => { Str, Str };

=attr options

Undocumented upstream. Driver-specific options, the same shape
L<API::Docker::Type::HostConfig::LogConfig/config> takes for a container,
whose example is C<< {"max-file": "5", "max-size": "10m"} >>. B<The keys are
the caller's data> and are never translated.

=cut

1;
