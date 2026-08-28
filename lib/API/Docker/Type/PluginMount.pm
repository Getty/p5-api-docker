package API::Docker::Type::PluginMount;
# ABSTRACT: One entry of C<Plugin.Config.Mounts>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<PluginMount> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Plugin.Config.Mounts> and C<Plugin.Settings.Mounts>.

=cut

docker name => Str, required => 1;

=attr name

Undocumented upstream. C<"some-mount"> in the swagger's example. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker description => Str, required => 1;

=attr description

Undocumented upstream. C<"This is a mount that's used by the plugin."> in
the swagger's example. The swagger lists this field as required; nothing
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

docker source => Str, required => 1;

=attr source

Undocumented upstream. Where the mount comes from on the host,
C<"/var/lib/docker/plugins/"> in the swagger's example -- what
L<API::Docker::Type::Mount/source> is for a container. The swagger lists
this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker destination => Str, required => 1;

=attr destination

Undocumented upstream. Where it appears inside the plugin, C<"/mnt/state">
in the swagger's example -- what L<API::Docker::Type::Mount/target> is for a
container. The swagger lists this field as required; nothing here enforces
that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker type => Str, required => 1;

=attr type

Undocumented upstream. C<"bind"> in the swagger's example. The
container-side field this mirrors, L<API::Docker::Type::Mount/type>, is an
enumeration the swagger describes value by value; this one is a bare string.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker options => [Str], required => 1;

=attr options

Undocumented upstream. Mount options, one string each: C<< ["rbind", "rw"]
>> in the swagger's example. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
