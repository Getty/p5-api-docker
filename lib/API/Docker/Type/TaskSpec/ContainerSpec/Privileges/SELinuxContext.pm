package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext;
# ABSTRACT: SELinux labels of the container
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<SELinuxContext> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=cut

docker disable => Bool;

=attr disable

Disable SELinux.

=cut

docker user => Str;

=attr user

SELinux user label.

=cut

docker role => Str;

=attr role

SELinux role label.

=cut

docker type => Str;

=attr type

SELinux type label.

=cut

docker level => Str;

=attr level

SELinux level label.

=cut

1;
