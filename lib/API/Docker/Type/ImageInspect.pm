package API::Docker::Type::ImageInspect;
# ABSTRACT: Information about an image in the local image cache
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::DriverData;
use API::Docker::Type::ImageConfig;
use API::Docker::Type::ImageInspect::Metadata;
use API::Docker::Type::ImageInspect::RootFS;
use API::Docker::Type::ImageManifestSummary;
use API::Docker::Type::OCIDescriptor;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ImageInspect> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str;

=attr id

ID is the content-addressable ID of an image.

This identifier is a content-addressable digest calculated from the image's
configuration (which includes the digests of layers used by the image).

Note that this digest differs from the C<RepoDigests> below, which holds
digests of image manifests that reference the image.

=cut

docker descriptor => 'OCIDescriptor', since => '1.51';

=attr descriptor

Descriptor is an OCI descriptor of the image target. In case of a
multi-platform image, this descriptor points to the OCI index or a manifest
list.

This field is only present if the daemon provides a multi-platform image
store.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::OCIDescriptor>.

=cut

docker manifests => [ 'ImageManifestSummary' ], since => '1.51';

=attr manifests

Manifests is a list of image manifests available in this image. It provides
a more detailed view of the platform-specific image manifests or other
image-attached data like build attestations.

Only available if the daemon provides a multi-platform image store and the
C<manifests> option is set in the inspect request.

WARNING: This is experimental and may change at any time without any
backward compatibility. See L<API::Docker::Type::ImageManifestSummary>.

=cut

docker repo_tags => [Str];

=attr repo_tags

List of image names/tags in the local image cache that reference this image.

Multiple image tags can refer to the same image, and this list may be empty
if no tags reference the image, in which case the image is "untagged", in
which case it can still be referenced by its ID.

=cut

docker repo_digests => [Str];

=attr repo_digests

List of content-addressable digests of locally available image manifests
that the image is referenced from. Multiple manifests can refer to the same
image.

These digests are usually only available if the image was either pulled from
a registry, or if the image was pushed to a registry, which is when the
manifest is generated and its digest calculated.

=cut

docker parent => Str;

=attr parent

ID of the parent image.

Depending on how the image was created, this field may be empty and is only
set for images that were built/created locally. This field is empty if the
image was pulled from an image registry.

> B<Deprecated>: This field is only set when using the deprecated > legacy
builder. It is included in API responses for informational > purposes, but
should not be depended on as it will be omitted > once the legacy builder is
removed.

=cut

docker comment => Str;

=attr comment

Optional message that was set when committing or importing the image.

=cut

docker created => Str;

=attr created

Date and time at which the image was created, formatted in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

This information is only available if present in the image, and omitted
otherwise.

=cut

docker docker_version => Str;

=attr docker_version

The version of Docker that was used to build the image.

Depending on how the image was created, this field may be empty.

> B<Deprecated>: This field is only set when using the deprecated > legacy
builder. It is included in API responses for informational > purposes, but
should not be depended on as it will be omitted > once the legacy builder is
removed.

=cut

docker author => Str;

=attr author

Name of the author that was specified when committing the image, or as
specified through MAINTAINER (deprecated) in the Dockerfile.

=cut

docker config => 'ImageConfig';

=attr config

Configuration of the image. See L<API::Docker::Type::ImageConfig>.

=cut

docker architecture => Str;

=attr architecture

Hardware CPU architecture that the image runs on.

=cut

docker variant => Str;

=attr variant

CPU architecture variant (presently ARM-only).

=cut

docker os => Str;

=attr os

Operating System the image is built to run on.

=cut

docker os_version => Str;

=attr os_version

Operating System version the image is built to run on (especially for
Windows).

=cut

docker size => Int;

=attr size

Total size of the image including all layers it is composed of.

=cut

docker graph_driver => 'DriverData';

=attr graph_driver

Information about the storage driver used to store the container's and
image's filesystem. See L<API::Docker::Type::DriverData>.

=cut

docker root_fs => 'ImageInspect::RootFS', wire => 'RootFS';

=attr root_fs

Information about the image's RootFS, including the layer IDs. See
L<API::Docker::Type::ImageInspect::RootFS>. Serialised as C<RootFS> --
spelled out, because deriving it from the Perl name would produce C<RootFs>.

=cut

docker metadata => 'ImageInspect::Metadata';

=attr metadata

Additional metadata of the image in the local cache. This information is
local to the daemon, and not part of the image itself. See
L<API::Docker::Type::ImageInspect::Metadata>.

=cut

1;
