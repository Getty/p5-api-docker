package API::Docker::Type::Plugin::Config::Linux;
# ABSTRACT: The Linux-specific capabilities and devices a plugin needs
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;

=head1 DESCRIPTION

Generated from the inline C<Linux> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker capabilities => [Str];

=attr capabilities

Undocumented upstream.

=cut

docker allow_all_devices => Bool;

=attr allow_all_devices

Undocumented upstream.

=cut

docker devices => [ 'PluginDevice' ];

=attr devices

Undocumented upstream. See L<API::Docker::Type::PluginDevice>.

=cut

1;
