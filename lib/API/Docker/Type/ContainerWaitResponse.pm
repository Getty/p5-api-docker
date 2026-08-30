package API::Docker::Type::ContainerWaitResponse;
# ABSTRACT: OK response to ContainerWait operation
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ContainerWaitExitError;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerWaitResponse> definition of
C<spec/v1.51.yaml>.

=cut

docker status_code => Int, required => 1;

=attr status_code

Exit code of the container. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker error => 'ContainerWaitExitError';

=attr error

Container waiting error, if any. See
L<API::Docker::Type::ContainerWaitExitError>.

=cut

1;
