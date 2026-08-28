package API::Docker::Type::GenericResource::NamedResourceSpec;
# ABSTRACT: A string-valued user-defined resource
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<NamedResourceSpec> schema of the
C<GenericResources> definition in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. The C<Kind>/C<Value> pair for a named resource,
C<GPU=UUID1> in the swagger's example.

=cut

docker kind => Str;

=attr kind

Undocumented upstream.

=cut

docker value => Str;

=attr value

Undocumented upstream.

=cut

1;
