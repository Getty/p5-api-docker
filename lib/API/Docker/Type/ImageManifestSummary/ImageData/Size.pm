package API::Docker::Type::ImageManifestSummary::ImageData::Size;
# ABSTRACT: The unpacked size of an image manifest
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Size> schema of
C<ImageManifestSummary.ImageData> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed. One byte count, C<Unpacked>.

=cut

docker unpacked => Int, since => '1.51';

=attr unpacked

Unpacked is the size (in bytes) of the locally unpacked (uncompressed) image
content that's directly usable by the containers running this image. It's
independent of the distributable content - e.g. the image might still have
an unpacked data that's still used by some container even when the
distributable/compressed content is already gone.

=cut

1;
