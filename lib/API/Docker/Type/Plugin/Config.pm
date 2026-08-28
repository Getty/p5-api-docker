package API::Docker::Type::Plugin::Config;
# ABSTRACT: The config of a plugin
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Plugin::Config::Args;
use API::Docker::Type::Plugin::Config::Interface;
use API::Docker::Type::Plugin::Config::Linux;
use API::Docker::Type::Plugin::Config::Network;
use API::Docker::Type::Plugin::Config::RootFS;
use API::Docker::Type::Plugin::Config::User;
use API::Docker::Type::PluginEnv;
use API::Docker::Type::PluginMount;

=head1 DESCRIPTION

Generated from the inline C<Config> schema of the C<Plugin> definition in
C<spec/v1.51.yaml>.

=cut

docker docker_version => Str;

=attr docker_version

Docker Version used to create the plugin.

Depending on how the plugin was created, this field may be empty or omitted.

Deprecated: this field is no longer set, and will be removed in the next API
version.

=cut

docker description => Str;

=attr description

Undocumented upstream.

=cut

docker documentation => Str;

=attr documentation

Undocumented upstream.

=cut

docker interface => 'Plugin::Config::Interface';

=attr interface

The interface between Docker and the plugin. See
L<API::Docker::Type::Plugin::Config::Interface>.

=cut

docker entrypoint => [Str];

=attr entrypoint

Undocumented upstream.

=cut

docker work_dir => Str;

=attr work_dir

Undocumented upstream.

=cut

docker user => 'Plugin::Config::User';

=attr user

Undocumented upstream. See L<API::Docker::Type::Plugin::Config::User>.

=cut

docker network => 'Plugin::Config::Network';

=attr network

Undocumented upstream. See L<API::Docker::Type::Plugin::Config::Network>.

=cut

docker linux => 'Plugin::Config::Linux';

=attr linux

Undocumented upstream. See L<API::Docker::Type::Plugin::Config::Linux>.

=cut

docker propagated_mount => Str;

=attr propagated_mount

Undocumented upstream.

=cut

docker ipc_host => Bool;

=attr ipc_host

Undocumented upstream.

=cut

docker pid_host => Bool;

=attr pid_host

Undocumented upstream.

=cut

docker mounts => [ 'PluginMount' ];

=attr mounts

Undocumented upstream. See L<API::Docker::Type::PluginMount>.

=cut

docker env => [ 'PluginEnv' ];

=attr env

Undocumented upstream. See L<API::Docker::Type::PluginEnv>.

=cut

docker args => 'Plugin::Config::Args';

=attr args

Undocumented upstream. See L<API::Docker::Type::Plugin::Config::Args>.

=cut

docker rootfs => 'Plugin::Config::RootFS', wire => 'rootfs';

=attr rootfs

Undocumented upstream. See L<API::Docker::Type::Plugin::Config::RootFS>.
Serialised as C<rootfs> -- spelled out, because deriving it from the Perl
name would produce C<Rootfs>.

=cut

1;
