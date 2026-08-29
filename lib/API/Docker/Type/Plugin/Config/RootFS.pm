package API::Docker::Type::Plugin::Config::RootFS;
# ABSTRACT: The root filesystem of a plugin
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<rootfs> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. The two fields are
spelled in lower case upstream, C<type> and C<diff_ids>, and the property
itself is C<rootfs>; the class is named C<RootFS> to match
C<ImageInspect.RootFS>, which is recorded in
C<maint/spec-drift-exceptions.yaml>.

=cut

docker type => Str, wire => 'type';

=attr type

Undocumented upstream. C<layers> in the swagger's example, the same value an
image answers with under L<API::Docker::Type::ImageInspect::RootFS/type>.
Serialised as C<type> -- spelled out, because deriving it from the Perl name
would produce C<Type>.

=cut

docker diff_ids => [Str], wire => 'diff_ids';

=attr diff_ids

Undocumented upstream. One C<sha256:...> digest per layer, two of them in
the swagger's example -- what
L<API::Docker::Type::ImageInspect::RootFS/layers> holds for an image.
Serialised as C<diff_ids> -- spelled out, because deriving it from the Perl
name would produce C<DiffIds>.

=cut

1;
