package API::Docker::Type::ClusterVolumeSpec::AccessMode::AccessibilityRequirements;
# ABSTRACT: Requirements for the accessible topology of the volume
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::Topology;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<AccessibilityRequirements> schema of
C<ClusterVolumeSpec.AccessMode> in C<spec/v1.51.yaml>.

These fields are optional. For an in-depth description of what these fields
mean, see the CSI specification.

=cut

docker requisite => [ 'Topology' ], since => '1.44';

=attr requisite

A list of required topologies, at least one of which the volume must be
accessible from. See L<API::Docker::Type::Topology>.

=cut

docker preferred => [ 'Topology' ], since => '1.44';

=attr preferred

A list of topologies that the volume should attempt to be provisioned in.
See L<API::Docker::Type::Topology>.

=cut

1;
