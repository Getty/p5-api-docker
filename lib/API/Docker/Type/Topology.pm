package API::Docker::Type::Topology;
# ABSTRACT: A map of topological domains to topological segments
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Topology> definition of C<spec/v1.51.yaml>.

For in depth details, see documentation for the Topology object in the CSI
specification.

=cut

docker segments => { Str, Str }, since => '1.44';

=attr segments

Undocumented upstream. The map itself -- topological domains for keys,
topological segments for values, which is what the definition above says the
object is. The swagger sends you to the CSI specification's own Topology
object for what those are. B<The keys are the caller's data> and are never
translated.

=cut

1;
