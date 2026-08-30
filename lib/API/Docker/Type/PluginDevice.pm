package API::Docker::Type::PluginDevice;
# ABSTRACT: One entry of C<Plugin.Config.Linux.Devices>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PluginDevice> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Plugin.Config.Linux.Devices> and
C<Plugin.Settings.Devices>.

=cut

docker name => Str, required => 1;

=attr name

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker description => Str, required => 1;

=attr description

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker settable => [Str], required => 1;

=attr settable

Undocumented upstream. An array of strings, and the swagger never says what
they hold. What a user changes on an installed plugin goes in through C<POST
/plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker path => Str, required => 1;

=attr path

Undocumented upstream. The device node, C<"/dev/fuse"> in the swagger's
example. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=cut

1;
