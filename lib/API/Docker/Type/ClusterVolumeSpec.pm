package API::Docker::Type::ClusterVolumeSpec;
# ABSTRACT: Cluster-specific options used to create the volume
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ClusterVolumeSpec::AccessMode;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ClusterVolumeSpec> definition of C<spec/v1.51.yaml>.

=cut

docker group => Str, since => '1.44';

=attr group

Group defines the volume group of this volume. Volumes belonging to the same
group can be referred to by group name when creating Services. Referring to
a volume by group instructs Swarm to treat volumes in that group
interchangeably for the purpose of scheduling. Volumes with an empty string
for a group technically all belong to the same, emptystring group.

=cut

docker access_mode => 'ClusterVolumeSpec::AccessMode', since => '1.44';

=attr access_mode

Defines how the volume is used by tasks. See
L<API::Docker::Type::ClusterVolumeSpec::AccessMode>.

=cut

1;
