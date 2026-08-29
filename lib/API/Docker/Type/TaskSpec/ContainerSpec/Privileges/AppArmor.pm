package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor;
# ABSTRACT: Options for configuring AppArmor on the container
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<AppArmor> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=cut

docker mode => Str, since => '1.44', enum => [qw( default disabled )];

=attr mode

Undocumented upstream. The whole of what this object configures: AppArmor
left at the engine's default, or turned off. The swagger enumerates
C<default> and C<disabled>.

=cut

1;
