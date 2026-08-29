package API::Docker::Type::TaskSpec::Resources;
# ABSTRACT: Resource requirements which apply to each individual container created as part of the service
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Limit;
use API::Docker::Type::ResourceObject;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Resources> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

=cut

docker limits => 'Limit';

=attr limits

Define resources limits. See L<API::Docker::Type::Limit>.

=cut

docker reservations => 'ResourceObject';

=attr reservations

Define resources reservation. See L<API::Docker::Type::ResourceObject>.

=cut

1;
