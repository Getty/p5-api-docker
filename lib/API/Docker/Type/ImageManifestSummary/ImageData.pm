package API::Docker::Type::ImageManifestSummary::ImageData;
# ABSTRACT: The image data for the image manifest
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ImageManifestSummary::ImageData::Size;
use API::Docker::Type::OCIPlatform;

=head1 DESCRIPTION

Generated from the inline C<ImageData> schema of the C<ImageManifestSummary>
definition in C<spec/v1.51.yaml>.

This field is only populated when Kind is "image".

=cut

docker platform => 'OCIPlatform', since => '1.51';

=attr platform

OCI platform of the image. This will be the platform specified in the
manifest descriptor from the index/manifest list. If it's not available, it
will be obtained from the image config. See
L<API::Docker::Type::OCIPlatform>.

=cut

docker containers => [Str], since => '1.51';

=attr containers

The IDs of the containers that are using this image.

=cut

docker size => 'ImageManifestSummary::ImageData::Size', since => '1.51';

=attr size

Undocumented upstream. One byte count, C<Unpacked>: the unpacked,
uncompressed image content a container running this image uses. See
L<API::Docker::Type::ImageManifestSummary::ImageData::Size>.

=cut

1;
