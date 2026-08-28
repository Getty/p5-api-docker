package API::Docker::Type::PluginEnv;
# ABSTRACT: One entry of C<Plugin.Config.Env>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<PluginEnv> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<Plugin.Config.Env>.

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

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker value => Str, required => 1;

=attr value

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

1;
