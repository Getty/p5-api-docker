package API::Docker::Type::ImageInspect::RootFS;
# ABSTRACT: Information about the image's RootFS, including the layer IDs
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<RootFS> schema of the C<ImageInspect> definition
in C<spec/v1.51.yaml>.

=cut

docker type => Str;

=attr type

Undocumented upstream. How the root filesystem is stored. C<layers> is the
only value the swagger shows, and the only one measured: C<GET
/images/{id}/json> on Podman 5.8.4 (API 1.44) answers C<"Type": "layers">.

=cut

docker layers => [Str];

=attr layers

Undocumented upstream. One diff ID per layer of the image. Measured against
Podman 5.8.4 (API 1.44), a Debian-based image answers eight C<sha256:...>
digests here; the swagger's example shows two of the same form.

=cut

1;
