package API::Docker::Type::Plugin::Config::Interface;
# ABSTRACT: The interface between Docker and the plugin
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::PluginInterfaceType;

=head1 DESCRIPTION

Generated from the inline C<Interface> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>.

=cut

docker types => [ 'PluginInterfaceType' ];

=attr types

Undocumented upstream. See L<API::Docker::Type::PluginInterfaceType>.

=cut

docker socket => Str;

=attr socket

Undocumented upstream.

=cut

docker protocol_scheme => Str, enum => [ '', 'moby.plugins.http/v1' ];

=attr protocol_scheme

Protocol to use for clients connecting to the plugin. The swagger enumerates
the empty string and C<moby.plugins.http/v1>.

=cut

1;
