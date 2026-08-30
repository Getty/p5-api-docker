package API::Docker::Type::GenericResource::DiscreteResourceSpec;
# ABSTRACT: An integer-valued user-defined resource
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<DiscreteResourceSpec> schema of the
C<GenericResources> definition in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. The C<Kind>/C<Value> pair for a countable resource,
C<SSD=3> in the swagger's example.

=cut

docker kind => Str;

=attr kind

Undocumented upstream. The resource's name, C<SSD> in that example.

=cut

docker value => Int;

=attr value

Undocumented upstream. How many there are, C<3> in that example.

=cut

1;
