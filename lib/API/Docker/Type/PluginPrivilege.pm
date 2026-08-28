package API::Docker::Type::PluginPrivilege;
# ABSTRACT: Describes a permission the user has to accept upon installing the plugin
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<PluginPrivilege> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

Undocumented upstream.

=cut

docker description => Str;

=attr description

Undocumented upstream.

=cut

docker value => [Str];

=attr value

Undocumented upstream.

=cut

1;
