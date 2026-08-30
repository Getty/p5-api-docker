package API::Docker::Type::ServiceCreateResponse;
# ABSTRACT: contains the information returned to a client on the creation of a new service
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ServiceCreateResponse> definition of
C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID', since => '1.44';

=attr id

The ID of the created service. Serialised as C<ID> -- spelled out, because
deriving it from the Perl name would produce C<Id>.

=cut

docker warnings => [Str], since => '1.44';

=attr warnings

Optional warning message.

FIXME(thaJeztah): this should have "omitempty" in the generated type.

=cut

1;
