package API::Docker::Type::Plugin::Config::Interface;
# ABSTRACT: The interface between Docker and the plugin
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::PluginInterfaceType;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Interface> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>.

=cut

docker types => [ 'PluginInterfaceType' ];

=attr types

Undocumented upstream. The plugin API contracts the plugin implements. The
swagger's example is the bare string C<docker.volumedriver/1.0> even though
the items are objects, and its three parts line up with the C<Prefix>,
C<Capability> and C<Version> of the class each item actually is, in that
order. See L<API::Docker::Type::PluginInterfaceType>.

=cut

docker socket => Str;

=attr socket

Undocumented upstream. The socket the engine reaches the plugin over,
C<plugins.sock> in the swagger's example -- a name, not a path.

=cut

docker protocol_scheme => Str, enum => [ '', 'moby.plugins.http/v1' ];

=attr protocol_scheme

Protocol to use for clients connecting to the plugin. The swagger enumerates
the empty string and C<moby.plugins.http/v1>.

=cut

1;
