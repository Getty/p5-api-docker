package API::Docker::Type::Plugin;
# ABSTRACT: A plugin for the Engine API
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::Plugin::Config;
use API::Docker::Type::Plugin::Settings;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Plugin> definition of C<spec/v1.51.yaml>. Nothing in
this class or in the ones hanging off it is backed by a measurement.
Rootless Podman serves no plugin route at all, so on the engine this
distribution measures against there is nothing here to observe; see
L<API::Docker::API::Plugins/"Not available on Podman">. Everything below is
read off the swagger's own examples.

=cut

docker id => Str;

=attr id

Undocumented upstream. The plugin's own ID, a 64-character hex digest in the
swagger's example. The C</plugins/{name}/...> endpoints address a plugin by
L</name>, not by this.

=cut

docker name => Str, required => 1;

=attr name

Undocumented upstream. The plugin's reference,
C<tiborvass/sample-volume-plugin> in the swagger's example, and what the
C</plugins/{name}/...> endpoints take in their path -- where the swagger
notes the C<:latest> tag is optional and the default when omitted.
L</plugin_reference> is the full remote reference the plugin was pushed or
pulled under. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker enabled => Bool, required => 1;

=attr enabled

True if the plugin is running. False if the plugin is not running, only
installed. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker settings => 'Plugin::Settings', required => 1;

=attr settings

Settings that can be modified by users. See
L<API::Docker::Type::Plugin::Settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker plugin_reference => Str;

=attr plugin_reference

Plugin remote reference used to push/pull the plugin.

=cut

docker config => 'Plugin::Config', required => 1;

=attr config

The config of a plugin. See L<API::Docker::Type::Plugin::Config>. The
swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
