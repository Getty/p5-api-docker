package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor;
# ABSTRACT: Options for configuring AppArmor on the container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<AppArmor> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=cut

docker mode => Str, since => '1.44', enum => [qw( default disabled )];

=attr mode

Undocumented upstream. The swagger enumerates C<default> and C<disabled>.

=cut

1;
