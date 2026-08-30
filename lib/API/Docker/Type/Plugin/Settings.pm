package API::Docker::Type::Plugin::Settings;
# ABSTRACT: Settings that can be modified by users
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::PluginDevice;
use API::Docker::Type::PluginMount;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Settings> schema of the C<Plugin> definition in
C<spec/v1.51.yaml>.

=cut

docker mounts => [ 'PluginMount' ];

=attr mounts

Undocumented upstream. The plugin's mounts as they now stand;
L<API::Docker::Type::Plugin::Config/mounts> is the same list as the plugin
declared it. See L<API::Docker::Type::PluginMount>.

=cut

docker env => [Str];

=attr env

Undocumented upstream. The environment as bare C<NAME=value> strings, C<<
["DEBUG=0"] >> in the swagger's example -- the shape C<POST
/plugins/{name}/set> takes in its body, whose own example is C<< ["DEBUG=1"]
>>. L<API::Docker::Type::Plugin::Config/env> carries the same variables as
objects with their descriptions.

=cut

docker args => [Str];

=attr args

Undocumented upstream. The command line as bare strings, against the single
named item L<API::Docker::Type::Plugin::Config/args> declares.

=cut

docker devices => [ 'PluginDevice' ];

=attr devices

Undocumented upstream. The plugin's devices as they now stand;
L<API::Docker::Type::Plugin::Config::Linux/devices> is the declared list.
See L<API::Docker::Type::PluginDevice>.

=cut

1;
