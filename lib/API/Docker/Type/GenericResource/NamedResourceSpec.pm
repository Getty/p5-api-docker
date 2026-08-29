package API::Docker::Type::GenericResource::NamedResourceSpec;
# ABSTRACT: A string-valued user-defined resource
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<NamedResourceSpec> schema of the
C<GenericResources> definition in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. The C<Kind>/C<Value> pair for a named resource,
C<GPU=UUID1> in the swagger's example.

=cut

docker kind => Str;

=attr kind

Undocumented upstream. The resource's name, C<GPU> in that example.

=cut

docker value => Str;

=attr value

Undocumented upstream. The name of the one unit, C<UUID1> in that example.
The example carries two such objects, C<UUID1> and C<UUID2>, rather than one
object listing both -- a node advertising two GPUs advertises two entries.

=cut

1;
