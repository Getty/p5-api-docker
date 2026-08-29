package API::Docker::Type::ClusterVolume::PublishStatus;
# ABSTRACT: One entry of C<ClusterVolume.PublishStatus>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<ClusterVolume.PublishStatus>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker node_id => Str, wire => 'NodeID', since => '1.44';

=attr node_id

The ID of the Swarm node the volume is published on. Serialised as C<NodeID>
-- spelled out, because deriving it from the Perl name would produce
C<NodeId>.

=cut

docker state => Str, since => '1.44',
  enum => [qw(
    pending-publish published pending-node-unpublish
    pending-controller-unpublish
  )];

=attr state

The published state of the volume.

=over 4

=item * C<pending-publish> The volume should be published to this node, but
the call to the controller plugin to do so has not yet been successfully
completed.

=item * C<published> The volume is published successfully to the node.

=item * C<pending-node-unpublish> The volume should be unpublished from the
node, and the manager is awaiting confirmation from the worker that it has
done so.

=item * C<pending-controller-unpublish> The volume is successfully
unpublished from the node, but has not yet been successfully unpublished on
the controller.

=back

=cut

docker publish_context => { Str, Str }, since => '1.44';

=attr publish_context

A map of strings to strings returned by the CSI controller plugin when a
volume is published. B<The keys are the caller's data> and are never
translated.

=cut

1;
