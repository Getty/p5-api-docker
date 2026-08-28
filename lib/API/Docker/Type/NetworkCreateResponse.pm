package API::Docker::Type::NetworkCreateResponse;
# ABSTRACT: OK response to NetworkCreate operation
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<NetworkCreateResponse> definition of
C<spec/v1.51.yaml>.

=cut

docker id => Str, since => '1.51', required => 1;

=attr id

The ID of the created network. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker warning => Str, since => '1.51', required => 1;

=attr warning

Warnings encountered when creating the container. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
