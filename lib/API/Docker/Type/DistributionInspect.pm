package API::Docker::Type::DistributionInspect;
# ABSTRACT: Describes the result obtained from contacting the registry to retrieve image metadata
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::OCIDescriptor;
use API::Docker::Type::OCIPlatform;

=head1 DESCRIPTION

Generated from the C<DistributionInspect> definition of C<spec/v1.51.yaml>.

=cut

docker descriptor => 'OCIDescriptor', required => 1;

=attr descriptor

A descriptor struct containing digest, media type, and size, as defined in
the L<OCI Content Descriptors
Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/descriptor.md>.
See L<API::Docker::Type::OCIDescriptor>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker platforms => [ 'OCIPlatform' ], required => 1;

=attr platforms

An array containing all platforms supported by the image. See
L<API::Docker::Type::OCIPlatform>. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
