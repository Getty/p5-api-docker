package API::Docker::Type::Mount::ImageOptions;
# ABSTRACT: Optional configuration for the C<image> type
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<ImageOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>. The whole schema is newer than v1.44.

=cut

docker subpath => Str, since => '1.51';

=attr subpath

Source path inside the image. Must be relative without any back traversals.

=cut

1;
