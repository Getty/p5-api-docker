package API::Docker::Type::ImageDeleteResponseItem;
# ABSTRACT: One entry of the C<200> response to C<DELETE /images/{name}>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ImageDeleteResponseItem> definition of
C<spec/v1.51.yaml>, which the swagger leaves undescribed. C<paths:> says
what it is: one entry of the C<200> response to C<DELETE /images/{name}> and
the C<ImagesDeleted> field of the C<200> response to C<POST /images/prune>.

=cut

docker untagged => Str;

=attr untagged

The image ID of an image that was untagged.

=cut

docker deleted => Str;

=attr deleted

The image ID of an image that was deleted.

=cut

1;
