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

Undocumented upstream. The plugin's own one-line description, C<"A sample
volume plugin for Docker"> in the swagger's example.

=cut

docker documentation => Str;

=attr documentation

Undocumented upstream. A URL,
C<https://docs.docker.com/engine/extend/plugins/> in the swagger's example.

=cut

docker interface => 'Plugin::Config::Interface';

=attr interface

The interface between Docker and the plugin. See
L<API::Docker::Type::Plugin::Config::Interface>.

=cut

docker entrypoint => [Str];

=attr entrypoint

Undocumented upstream. The command the plugin's process is started with, one
string per argument: C<< ["/usr/bin/sample-volume-plugin", "/data"] >> in
the swagger's example.

=cut

docker work_dir => Str;

=attr work_dir

Undocumented upstream. The working directory that process starts in,
C<"/bin/"> in the swagger's example.

=cut

docker user => 'Plugin::Config::User';

=attr user

Undocumented upstream. Two C<uint32>s, both C<1000> in the swagger's
example. See L<API::Docker::Type::Plugin::Config::User>.

=cut

docker network => 'Plugin::Config::Network';

=attr network

Undocumented upstream. One field, a network mode; C<host> in the swagger's
example. See L<API::Docker::Type::Plugin::Config::Network>.

=cut

docker linux => 'Plugin::Config::Linux';

=attr linux

Undocumented upstream. The Linux capabilities the plugin needs, whether it
may use every device, and the devices it declares by hand. See
L<API::Docker::Type::Plugin::Config::Linux>.

=cut

docker propagated_mount => Str;

=attr propagated_mount

Undocumented upstream. A path, C<"/mnt/volumes"> in the swagger's example.
That example is all the swagger offers about it.

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

Undocumented upstream. The mounts the plugin declares.
L<API::Docker::Type::Plugin/settings> carries the same list as it stands
after a user has changed it. See L<API::Docker::Type::PluginMount>.

=cut

docker env => [ 'PluginEnv' ];

=attr env

Undocumented upstream. The environment variables the plugin declares, each
an object with its own description and value: the swagger's example is a
single C<DEBUG>, "if set, prints debug messages", currently C<"0">.
L<API::Docker::Type::Plugin::Settings/env> carries the same variables as
bare C<NAME=value> strings. See L<API::Docker::Type::PluginEnv>.

=cut

docker args => 'Plugin::Config::Args';

=attr args

Undocumented upstream. The plugin's command line as one named item --
C<args>, "command line arguments", in the swagger's example -- not one item
per argument. See L<API::Docker::Type::Plugin::Config::Args>.

=cut

docker rootfs => 'Plugin::Config::RootFS', wire => 'rootfs';

=attr rootfs

Undocumented upstream. A type and a list of layer digests, both spelled in
lower case upstream. See L<API::Docker::Type::Plugin::Config::RootFS>.
Serialised as C<rootfs> -- spelled out, because deriving it from the Perl
name would produce C<Rootfs>.

=cut

1;
