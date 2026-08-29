package API::Docker::Type::TaskSpec::ContainerSpec::Ulimit;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Ulimits>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Ulimits> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker name => Str;

=attr name

Name of ulimit.

=cut

docker soft => Int;

=attr soft

Soft limit.

=cut

docker hard => Int;

=attr hard

Hard limit.

=cut

1;
