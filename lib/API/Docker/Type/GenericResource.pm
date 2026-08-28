package API::Docker::Type::GenericResource;
# ABSTRACT: User-defined resources can be either Integer resources (e.g, C<SSD=3>) or String resources (e.g, C<GPU=UUID1>)
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::GenericResource::DiscreteResourceSpec;
use API::Docker::Type::GenericResource::NamedResourceSpec;

=head1 DESCRIPTION

Generated from the C<GenericResources> definition of C<spec/v1.51.yaml>.

=cut

docker named_resource_spec => 'GenericResource::NamedResourceSpec';

=attr named_resource_spec

Undocumented upstream. See
L<API::Docker::Type::GenericResource::NamedResourceSpec>.

=cut

docker discrete_resource_spec => 'GenericResource::DiscreteResourceSpec';

=attr discrete_resource_spec

Undocumented upstream. See
L<API::Docker::Type::GenericResource::DiscreteResourceSpec>.

=cut

1;
