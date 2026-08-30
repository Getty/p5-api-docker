package API::Docker::Type::ResourceObject;
# ABSTRACT: An object describing the resources which can be advertised by a node and requested by a task
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::GenericResource;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ResourceObject> definition of C<spec/v1.51.yaml>.

=cut

docker nano_cpus => Int, wire => 'NanoCPUs';

=attr nano_cpus

Undocumented upstream. The same units and the same example as
L<API::Docker::Type::Limit/nano_cpus>: C<4000000000> is four whole CPUs.
Serialised as C<NanoCPUs> -- spelled out, because deriving it from the Perl
name would produce C<NanoCpus>.

=cut

docker memory_bytes => Int;

=attr memory_bytes

Undocumented upstream. Bytes, and the same example as
L<API::Docker::Type::Limit/memory_bytes>.

=cut

docker generic_resources => [ 'GenericResource' ];

=attr generic_resources

User-defined resources can be either Integer resources (e.g, C<SSD=3>) or
String resources (e.g, C<GPU=UUID1>). See
L<API::Docker::Type::GenericResource>.

=cut

1;
