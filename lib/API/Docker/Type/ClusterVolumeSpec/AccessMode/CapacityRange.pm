package API::Docker::Type::ClusterVolumeSpec::AccessMode::CapacityRange;
# ABSTRACT: The desired capacity that the volume should be created with
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<CapacityRange> schema of
C<ClusterVolumeSpec.AccessMode> in C<spec/v1.51.yaml>.

If empty, the plugin will decide the capacity.

=cut

docker required_bytes => Int, since => '1.44';

=attr required_bytes

The volume must be at least this big. The value of 0 indicates an
unspecified minimum.

=cut

docker limit_bytes => Int, since => '1.44';

=attr limit_bytes

The volume must not be bigger than this. The value of 0 indicates an
unspecified maximum.

=cut

1;
