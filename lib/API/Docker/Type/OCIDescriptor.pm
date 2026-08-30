package API::Docker::Type::OCIDescriptor;
# ABSTRACT: A descriptor struct containing digest, media type, and size, as defined in the L<OCI Content Descriptors Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::OCIPlatform;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<OCIDescriptor> definition of C<spec/v1.51.yaml>.

=cut

docker media_type => Str, wire => 'mediaType';

=attr media_type

The media type of the object this schema refers to. Serialised as
C<mediaType> -- spelled out, because deriving it from the Perl name would
produce C<MediaType>.

=cut

docker digest => Str, wire => 'digest';

=attr digest

The digest of the targeted content. Serialised as C<digest> -- spelled out,
because deriving it from the Perl name would produce C<Digest>.

=cut

docker size => Int, wire => 'size';

=attr size

The size in bytes of the blob. Serialised as C<size> -- spelled out, because
deriving it from the Perl name would produce C<Size>.

=cut

docker urls => [Str], wire => 'urls', since => '1.51';

=attr urls

List of URLs from which this object MAY be downloaded. Serialised as C<urls>
-- spelled out, because deriving it from the Perl name would produce
C<Urls>.

=cut

docker annotations => { Str, Str }, wire => 'annotations', since => '1.51';

=attr annotations

Arbitrary metadata relating to the targeted content. B<The keys are the
caller's data> and are never translated. Serialised as C<annotations> --
spelled out, because deriving it from the Perl name would produce
C<Annotations>.

=cut

docker data => Str, wire => 'data', since => '1.51';

=attr data

Data is an embedding of the targeted content. This is encoded as a base64
string when marshalled to JSON (automatically, by encoding/json). If
present, Data can be used directly to avoid fetching the targeted content.
Serialised as C<data> -- spelled out, because deriving it from the Perl name
would produce C<Data>.

=cut

docker platform => 'OCIPlatform', wire => 'platform', since => '1.51';

=attr platform

Describes the platform which the image in the manifest runs on, as defined
in the L<OCI Image Index
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/image-index.md>.
See L<API::Docker::Type::OCIPlatform>. Serialised as C<platform> -- spelled
out, because deriving it from the Perl name would produce C<Platform>.

=cut

docker artifact_type => Str, wire => 'artifactType', since => '1.51';

=attr artifact_type

ArtifactType is the IANA media type of this artifact. Serialised as
C<artifactType> -- spelled out, because deriving it from the Perl name would
produce C<ArtifactType>.

=cut

1;
