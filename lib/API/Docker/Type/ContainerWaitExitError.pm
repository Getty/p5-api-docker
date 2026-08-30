package API::Docker::Type::ContainerWaitExitError;
# ABSTRACT: container waiting error, if any
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerWaitExitError> definition of
C<spec/v1.51.yaml>.

=cut

docker message => Str;

=attr message

Details of an error.

=cut

1;
