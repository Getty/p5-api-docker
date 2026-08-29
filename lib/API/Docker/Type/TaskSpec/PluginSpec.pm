package API::Docker::Type::TaskSpec::PluginSpec;
# ABSTRACT: Plugin spec for the service
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::PluginPrivilege;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<PluginSpec> schema of the C<TaskSpec> definition
in C<spec/v1.51.yaml>.

*(Experimental release only.)*

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=cut

docker name => Str;

=attr name

The name or 'alias' to use for the plugin.

=cut

docker remote => Str;

=attr remote

The plugin image reference to use.

=cut

docker disabled => Bool;

=attr disabled

Disable the plugin once scheduled.

=cut

docker plugin_privilege => [ 'PluginPrivilege' ];

=attr plugin_privilege

Undocumented upstream. The permissions installing the plugin requires the
user to accept, one entry per permission. The other three fields of this
spec -- C<Name>, C<Remote> and C<Disabled> -- are described upstream; this
one is not. See L<API::Docker::Type::PluginPrivilege>.

=cut

1;
