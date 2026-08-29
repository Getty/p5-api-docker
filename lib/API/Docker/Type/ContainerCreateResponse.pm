package API::Docker::Type::ContainerCreateResponse;
# ABSTRACT: OK response to ContainerCreate operation
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerCreateResponse> definition of
C<spec/v1.51.yaml>.

=cut

docker id => Str, since => '1.44', required => 1;

=attr id

The ID of the created container. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker warnings => [Str], since => '1.44', required => 1;

=attr warnings

Warnings encountered when creating the container. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
