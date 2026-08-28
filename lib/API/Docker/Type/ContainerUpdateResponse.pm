package API::Docker::Type::ContainerUpdateResponse;
# ABSTRACT: Response for a successful container-update
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerUpdateResponse> definition of
C<spec/v1.51.yaml>.

=cut

docker warnings => [Str], since => '1.51';

=attr warnings

Warnings encountered when updating the container.

=cut

1;
