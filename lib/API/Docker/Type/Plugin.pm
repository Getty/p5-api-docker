package API::Docker::Type::Plugin;
# ABSTRACT: A plugin for the Engine API
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Plugin::Config;
use API::Docker::Type::Plugin::Settings;

=head1 DESCRIPTION

Generated from the C<Plugin> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str;

=attr id

Undocumented upstream.

=cut

docker name => Str, required => 1;

=attr name

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

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
