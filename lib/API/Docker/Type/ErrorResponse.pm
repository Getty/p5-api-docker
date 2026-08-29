package API::Docker::Type::ErrorResponse;
# ABSTRACT: Represents an error
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ErrorResponse> definition of C<spec/v1.51.yaml>.

=cut

docker message => Str, wire => 'message', required => 1;

=attr message

The error message. Serialised as C<message> -- spelled out, because deriving
it from the Perl name would produce C<Message>. The swagger lists this field
as required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
