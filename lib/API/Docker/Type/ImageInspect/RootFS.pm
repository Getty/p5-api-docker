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

Undocumented upstream.

=cut

docker layers => [Str];

=attr layers

Undocumented upstream.

=cut

1;
