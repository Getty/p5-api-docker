package API::Docker::Type::ImageHistoryResponseItem;
# ABSTRACT: individual image layer information in response to ImageHistory operation
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ImageHistoryResponseItem> definition of
C<spec/v1.51.yaml>. The swagger describes none of the six fields, but the
example response it gives for C<GET /images/{name}/history> shows all six
across three layers. That example is not the last word: measured against
Podman 5.8.4 (API 1.44), a locally built image answers ten entries that
contradict it on three of the six, so L</id>, L</tags> and L</comment> each
say what the spec shows and what the engine sent.

=cut

docker id => Str, required => 1;

=attr id

Undocumented upstream. The swagger's example response spells this as a bare
hex digest with no C<sha256:> prefix. The engine does not. Measured against
Podman 5.8.4 (API 1.44), a locally built image answers ten entries of which
exactly one -- the image's own top layer -- carries a real C<sha256:...>
digest; the other nine carry the literal string C<< sha256:<missing> >>,
which is a marker and not an ID. Handing that to C<GET /images/{id}/json>
looks up nothing, so test for it before treating this field as a reference
to anything. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker created => Int, required => 1;

=attr created

Undocumented upstream. A Unix timestamp in seconds -- C<1398108230> in the
swagger's example response, the same form the spec spells out for
L<API::Docker::Type::ImageSummary/created>, and the form measured against
Podman 5.8.4 (API 1.44), which answers C<1787794246> for the top layer of a
locally built image. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker created_by => Str, required => 1;

=attr created_by

Undocumented upstream. What created the layer, C<< "/bin/sh -c #(nop) ADD
file:eb15... in /" >> in the swagger's example response. Measured against
Podman 5.8.4 (API 1.44), one response mixes two forms: that C<< "/bin/sh -c
..." >> shell wrapping on the older layers, and bare Dockerfile instructions
on the ones a BuildKit build produced -- C<< CMD ["perl5.40.5" "-de0"] >>,
C<WORKDIR /usr/src/app>, C<< COPY *.patch /usr/src/perl/ # buildkit >>. Do
not parse it expecting either one. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker tags => [Str], required => 1;

=attr tags

Undocumented upstream. The image names pointing at this layer, C<<
["ubuntu:lucid", "ubuntu:10.04"] >> in the swagger's example response, which
writes C<[]> for a layer that has none. The engine writes C<null> there
instead: measured against Podman 5.8.4 (API 1.44), all ten entries of an
untagged image answer C<null>. An empty list is not what an absent tag looks
like on the wire. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker size => Int, required => 1;

=attr size

Undocumented upstream. The layer's size in bytes: C<182964289> for the one
that adds the root filesystem in the swagger's example response, C<0> for
the two that only carry metadata. Measured against Podman 5.8.4 (API 1.44),
the ten entries of one locally built image run from C<0> to C<410969600>,
and C<0> is not reserved for metadata layers -- a C<#(nop) COPY> among them
reports C<4262912>. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker comment => Str, required => 1;

=attr comment

Undocumented upstream. The message set when the layer was committed or
imported, which is what L<API::Docker::Type::ImageInspect/comment> describes
for a whole image. The swagger's example response leaves it empty on two
layers and gives C<"Imported from -"> on the third. Measured against Podman
5.8.4 (API 1.44) it is always present, never absent, and where the layer has
a provenance it carries that: on one locally built image,
C<"buildkit.dockerfile.v0"> on five entries, C<"debuerreotype 0.17"> on the
base layer, C<< "FROM docker.io/library/perl:5.40-slim" >> on one more, and
the empty string on the remaining three. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
