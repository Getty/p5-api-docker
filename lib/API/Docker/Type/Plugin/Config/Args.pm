package API::Docker::Type::Plugin::Config::Args;
# ABSTRACT: The command-line arguments a plugin accepts
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Args> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker name => Str;

=attr name

Undocumented upstream. C<args> in the swagger's example -- the whole command
line is one named item, not one item per argument.

=cut

docker description => Str;

=attr description

Undocumented upstream. C<"command line arguments"> in the swagger's example.

=cut

docker settable => [Str];

=attr settable

Undocumented upstream. An array of strings, and the swagger never says what
they hold. What a user changes on an installed plugin goes in through C<POST
/plugins/{name}/set> and comes back out under
L<API::Docker::Type::Plugin/settings>.

=cut

docker value => [Str];

=attr value

Undocumented upstream. The arguments themselves, one string each.

=cut

1;
