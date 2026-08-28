package API::Docker::Type::ImageID;
# ABSTRACT: Image ID or Digest
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ImageID> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. Serialised as C<ID> -- spelled out, because deriving
it from the Perl name would produce C<Id>.

=cut

1;
