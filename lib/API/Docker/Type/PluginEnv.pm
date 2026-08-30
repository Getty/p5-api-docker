package API::Docker::Type::PluginEnv;
# ABSTRACT: One entry of C<Plugin.Config.Env>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PluginEnv> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<Plugin.Config.Env>. None of its four fields is described, but
the example the swagger gives for that field shows all four at once: C<Name>
C<"DEBUG">, C<Description> C<"If set, prints debug messages">, C<Settable>
C<null> and C<Value> C<"0">.

=cut

docker name => Str, required => 1;

=attr name

Undocumented upstream. The variable's name, C<"DEBUG"> in that example. The
swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker description => Str, required => 1;

=attr description

Undocumented upstream. What setting it does, C<"If set, prints debug
messages"> in that example. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker settable => [Str], required => 1;

=attr settable

Undocumented upstream. An array of strings, C<null> in that example, and the
swagger never says what they hold. What a user changes on an installed
plugin goes in through C<POST /plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker value => Str, required => 1;

=attr value

Undocumented upstream. The value it currently has, C<"0"> in that example --
a string, even where it reads as a number. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
