package API::Docker::Type::PluginsInfo;
# ABSTRACT: Available plugins per type
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PluginsInfo> definition of C<spec/v1.51.yaml>.

> B<Note>: Only unmanaged (V1) plugins are included in this list. > V1
plugins are "lazily" loaded, and are not returned in this list > if there is
no resource using the plugin.

=cut

docker volume => [Str];

=attr volume

Names of available volume-drivers, and network-driver plugins.

=cut

docker network => [Str];

=attr network

Names of available network-drivers, and network-driver plugins.

=cut

docker authorization => [Str];

=attr authorization

Names of available authorization plugins.

=cut

docker log => [Str];

=attr log

Names of available logging-drivers, and logging-driver plugins.

=cut

1;
