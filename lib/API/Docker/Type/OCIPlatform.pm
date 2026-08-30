package API::Docker::Type::OCIPlatform;
# ABSTRACT: Describes the platform which the image in the manifest runs on, as defined in the L<OCI Image Index Specification|https://github.com/opencontainers/image-spec/blob/v1.0.1/image-index.md>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<OCIPlatform> definition of C<spec/v1.51.yaml>.

=cut

docker architecture => Str, wire => 'architecture';

=attr architecture

The CPU architecture, for example C<amd64> or C<ppc64>. Serialised as
C<architecture> -- spelled out, because deriving it from the Perl name would
produce C<Architecture>.

=cut

docker os => Str, wire => 'os';

=attr os

The operating system, for example C<linux> or C<windows>. Serialised as
C<os> -- spelled out, because deriving it from the Perl name would produce
C<Os>.

=cut

docker os_version => Str, wire => 'os.version';

=attr os_version

Optional field specifying the operating system version, for example on
Windows C<10.0.19041.1165>. Serialised as C<os.version> -- spelled out,
because deriving it from the Perl name would produce C<OsVersion>.

=cut

docker os_features => [Str], wire => 'os.features';

=attr os_features

Optional field specifying an array of strings, each listing a required OS
feature (for example on Windows C<win32k>). Serialised as C<os.features> --
spelled out, because deriving it from the Perl name would produce
C<OsFeatures>.

=cut

docker variant => Str, wire => 'variant';

=attr variant

Optional field specifying a variant of the CPU, for example C<v7> to specify
ARMv7 when architecture is C<arm>. Serialised as C<variant> -- spelled out,
because deriving it from the Perl name would produce C<Variant>.

=cut

1;
