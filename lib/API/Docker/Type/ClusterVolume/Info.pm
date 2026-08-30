package API::Docker::Type::ClusterVolume::Info;
# ABSTRACT: Information about the global status of the volume
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::Topology;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Info> schema of the C<ClusterVolume> definition
in C<spec/v1.51.yaml>.

=cut

docker capacity_bytes => Int, since => '1.44';

=attr capacity_bytes

The capacity of the volume in bytes. A value of 0 indicates that the
capacity is unknown.

=cut

docker volume_context => { Str, Str }, since => '1.44';

=attr volume_context

A map of strings to strings returned from the storage plugin when the volume
is created. B<The keys are the caller's data> and are never translated.

=cut

docker volume_id => Str, wire => 'VolumeID', since => '1.44';

=attr volume_id

The ID of the volume as returned by the CSI storage plugin. This is distinct
from the volume's ID as provided by Docker. This ID is never used by the
user when communicating with Docker to refer to this volume. If the ID is
blank, then the Volume has not been successfully created in the plugin yet.
Serialised as C<VolumeID> -- spelled out, because deriving it from the Perl
name would produce C<VolumeId>.

=cut

docker accessible_topology => [ 'Topology' ], since => '1.44';

=attr accessible_topology

The topology this volume is actually accessible from. See
L<API::Docker::Type::Topology>.

=cut

1;
