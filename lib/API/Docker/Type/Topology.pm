package API::Docker::Type::Topology;
# ABSTRACT: A map of topological domains to topological segments
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<Topology> definition of C<spec/v1.51.yaml>.

For in depth details, see documentation for the Topology object in the CSI
specification.

=cut

docker segments => { Str, Str }, since => '1.44';

=attr segments

Undocumented upstream. B<The keys are the caller's data> and are never
translated.

=cut

1;
