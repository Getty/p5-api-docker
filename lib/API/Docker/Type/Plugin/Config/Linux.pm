package API::Docker::Type::Plugin::Config::Linux;
# ABSTRACT: The Linux-specific capabilities and devices a plugin needs
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Linux> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker capabilities => [Str];

=attr capabilities

Undocumented upstream. The Linux capabilities the plugin's process needs,
C<CAP_SYS_ADMIN> and C<CAP_SYSLOG> in the swagger's example.

=cut

docker allow_all_devices => Bool;

=attr allow_all_devices

Undocumented upstream. A boolean, C<false> in the swagger's example,
required beside the explicit L</devices> list.

=cut

docker devices => [ 'PluginDevice' ];

=attr devices

Undocumented upstream. The device list that stands beside
L</allow_all_devices>. See L<API::Docker::Type::PluginDevice>.

=cut

1;
