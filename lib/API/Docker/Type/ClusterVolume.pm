package API::Docker::Type::ClusterVolume;
# ABSTRACT: Options and information specific to, and only present on, Swarm CSI cluster volumes
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ClusterVolume::Info;
use API::Docker::Type::ClusterVolume::PublishStatus;
use API::Docker::Type::ClusterVolumeSpec;
use API::Docker::Type::ObjectVersion;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ClusterVolume> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID', since => '1.44';

=attr id

The Swarm ID of this volume. Because cluster volumes are Swarm objects, they
have an ID, unlike non-cluster volumes. This ID can be used to refer to the
Volume instead of the name. Serialised as C<ID> -- spelled out, because
deriving it from the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion', since => '1.44';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str, since => '1.44';

=attr created_at

Undocumented upstream. A C<dateTime>, with no example given. Cluster volumes
are Swarm objects, which is what L</id> says makes them carry an ID where a
plain volume does not, and it is why they carry these two timestamps as
well.

=cut

docker updated_at => Str, since => '1.44';

=attr updated_at

Undocumented upstream. The same, for the last change.

=cut

docker spec => 'ClusterVolumeSpec', since => '1.44';

=attr spec

Cluster-specific options used to create the volume. See
L<API::Docker::Type::ClusterVolumeSpec>.

=cut

docker info => 'ClusterVolume::Info', since => '1.44';

=attr info

Information about the global status of the volume. See
L<API::Docker::Type::ClusterVolume::Info>.

=cut

docker publish_status => [ 'ClusterVolume::PublishStatus' ], since => '1.44';

=attr publish_status

The status of the volume as it pertains to its publishing and use on
specific nodes. See L<API::Docker::Type::ClusterVolume::PublishStatus>.

=cut

1;
