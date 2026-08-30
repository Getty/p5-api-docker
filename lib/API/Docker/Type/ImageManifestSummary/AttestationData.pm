package API::Docker::Type::ImageManifestSummary::AttestationData;
# ABSTRACT: The image data for the attestation manifest
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<AttestationData> schema of the
C<ImageManifestSummary> definition in C<spec/v1.51.yaml>.

This field is only populated when Kind is "attestation".

=cut

docker for => Str, since => '1.51';

=attr for

The digest of the image manifest that this attestation is for.

=cut

1;
