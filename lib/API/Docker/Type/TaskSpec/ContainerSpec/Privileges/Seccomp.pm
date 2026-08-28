package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::Seccomp;
# ABSTRACT: Options for configuring seccomp on the container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Seccomp> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=cut

docker mode => Str,
  since => '1.44', enum => [qw( default unconfined custom )];

=attr mode

Undocumented upstream. The swagger enumerates C<default>, C<unconfined> and
C<custom>.

=cut

docker profile => Str, since => '1.44';

=attr profile

The custom seccomp profile as a json object.

=cut

1;
