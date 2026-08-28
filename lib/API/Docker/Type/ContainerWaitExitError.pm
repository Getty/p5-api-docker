package API::Docker::Type::ContainerWaitExitError;
# ABSTRACT: container waiting error, if any
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerWaitExitError> definition of
C<spec/v1.51.yaml>.

=cut

docker message => Str;

=attr message

Details of an error.

=cut

1;
