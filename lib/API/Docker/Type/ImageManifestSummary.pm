package API::Docker::Type::ImageManifestSummary;
# ABSTRACT: A summary of an image manifest
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ImageManifestSummary::AttestationData;
use API::Docker::Type::ImageManifestSummary::ImageData;
use API::Docker::Type::ImageManifestSummary::Size;
use API::Docker::Type::OCIDescriptor;

=head1 DESCRIPTION

Generated from the C<ImageManifestSummary> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID', since => '1.51', required => 1;

=attr id

ID is the content-addressable ID of an image and is the same as the digest
of the image manifest. Serialised as C<ID> -- spelled out, because deriving
it from the Perl name would produce C<Id>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker descriptor => 'OCIDescriptor', since => '1.51', required => 1;

=attr descriptor

A descriptor struct containing digest, media type, and size, as defined in
the L<OCI Content Descriptors
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>.
See L<API::Docker::Type::OCIDescriptor>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker available => Bool, since => '1.51', required => 1;

=attr available

Indicates whether all the child content (image config, layers) is fully
available locally. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker size => 'ImageManifestSummary::Size', since => '1.51', required => 1;

=attr size

Undocumented upstream. Two byte counts: C<Content> for what of this manifest
and its children is in the local content store, C<Total> for that plus every
other locally present byte belonging to it. See
L<API::Docker::Type::ImageManifestSummary::Size>. The swagger lists this
field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker kind => Str,
  since => '1.51', required => 1, enum => [qw( image attestation unknown )];

=attr kind

The kind of the manifest.

kind | description
-------------|-----------------------------------------------------------
image | Image manifest that can be used to start a container. attestation |
Attestation manifest produced by the Buildkit builder for a specific image
manifest. The swagger enumerates C<image>, C<attestation> and C<unknown>.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker image_data => 'ImageManifestSummary::ImageData', since => '1.51';

=attr image_data

The image data for the image manifest. This field is only populated when
Kind is "image". See L<API::Docker::Type::ImageManifestSummary::ImageData>.

=cut

docker attestation_data => 'ImageManifestSummary::AttestationData',
  since => '1.51';

=attr attestation_data

The image data for the attestation manifest. This field is only populated
when Kind is "attestation". See
L<API::Docker::Type::ImageManifestSummary::AttestationData>.

=cut

1;
