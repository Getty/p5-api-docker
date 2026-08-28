package API::Docker::Type::ImageHistoryResponseItem;
# ABSTRACT: individual image layer information in response to ImageHistory operation
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ImageHistoryResponseItem> definition of
C<spec/v1.51.yaml>. The swagger describes none of the six fields, but the
example response it gives for C<GET /images/{name}/history> shows all six
across three layers, and the sentences below are read off it.

=cut

docker id => Str, required => 1;

=attr id

Undocumented upstream. The layer's ID, a bare hex digest without a
C<sha256:> prefix in the swagger's example response. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker created => Int, required => 1;

=attr created

Undocumented upstream. A Unix timestamp in seconds -- C<1398108230> in the
swagger's example response, the same form the spec spells out for
L<API::Docker::Type::ImageSummary/created>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker created_by => Str, required => 1;

=attr created_by

Undocumented upstream. What created the layer, C<< "/bin/sh -c #(nop) ADD
file:eb15... in /" >> in the swagger's example response, and the empty
string for a layer that carries none. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker tags => [Str], required => 1;

=attr tags

Undocumented upstream. The image names pointing at this layer, C<<
["ubuntu:lucid", "ubuntu:10.04"] >> in the swagger's example response, and
empty for the layers below it. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker size => Int, required => 1;

=attr size

Undocumented upstream. The layer's size in bytes: C<182964289> for the one
that adds the root filesystem in the swagger's example response, C<0> for
the two that only carry metadata. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker comment => Str, required => 1;

=attr comment

Undocumented upstream. The message set when the layer was committed or
imported, which is what L<API::Docker::Type::ImageInspect/comment> describes
for a whole image. C<"Imported from -"> on the imported layer of the
swagger's example response, empty on the other two. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
