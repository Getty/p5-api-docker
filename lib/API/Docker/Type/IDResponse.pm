package API::Docker::Type::IDResponse;
# ABSTRACT: Response to an API call that returns just an Id
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<IDResponse> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, since => '1.51', required => 1;

=attr id

The id of the newly created object. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
