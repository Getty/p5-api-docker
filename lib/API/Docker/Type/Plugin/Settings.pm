package API::Docker::Type::Plugin::Settings;
# ABSTRACT: Settings that can be modified by users
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;
use API::Docker::Type::PluginMount;

=head1 DESCRIPTION

Generated from the inline C<Settings> schema of the C<Plugin> definition in
C<spec/v1.51.yaml>.

=cut

docker mounts => [ 'PluginMount' ];

=attr mounts

Undocumented upstream. See L<API::Docker::Type::PluginMount>.

=cut

docker env => [Str];

=attr env

Undocumented upstream.

=cut

docker args => [Str];

=attr args

Undocumented upstream.

=cut

docker devices => [ 'PluginDevice' ];

=attr devices

Undocumented upstream. See L<API::Docker::Type::PluginDevice>.

=cut

1;
