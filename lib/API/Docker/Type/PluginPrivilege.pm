package API::Docker::Type::PluginPrivilege;
# ABSTRACT: Describes a permission the user has to accept upon installing the plugin
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<PluginPrivilege> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

Undocumented upstream. What the permission is over, C<network> in the
swagger's example.

=cut

docker description => Str;

=attr description

Undocumented upstream.

=cut

docker value => [Str];

=attr value

Undocumented upstream. What is being asked for, one string each: C<<
["host"] >> beside that C<network> in the swagger's example.

=cut

1;
