package API::Docker::Type::ImageManifestSummary::Size;
# ABSTRACT: The sizes of one manifest of an image
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Size> schema of the C<ImageManifestSummary>
definition in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Two
byte counts, C<Content> and C<Total>.

=cut

docker total => Int, since => '1.51';

=attr total

Total is the total size (in bytes) of all the locally present data (both
distributable and non-distributable) that's related to this manifest and its
children. This equal to the sum of [Content] size AND all the sizes in the
[Size] struct present in the Kind-specific data struct. For example, for an
image kind (Kind == "image") this would include the size of the image
content and unpacked image snapshots ([Size.Content] +
[ImageData.Size.Unpacked]).

=cut

docker content => Int, since => '1.51';

=attr content

Content is the size (in bytes) of all the locally present content in the
content store (e.g. image config, layers) referenced by this manifest and
its children. This only includes blobs in the content store.

=cut

1;
