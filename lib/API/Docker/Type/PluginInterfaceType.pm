package API::Docker::Type::PluginInterfaceType;
# ABSTRACT: One entry of C<Plugin.Config.Interface.Types>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<PluginInterfaceType> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one entry of C<Plugin.Config.Interface.Types>.

=cut

docker prefix => Str, required => 1;

=attr prefix

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker capability => Str, required => 1;

=attr capability

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker version => Str, required => 1;

=attr version

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

1;
