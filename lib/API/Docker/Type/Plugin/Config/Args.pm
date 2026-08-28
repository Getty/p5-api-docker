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

Undocumented upstream.

=cut

docker description => Str;

=attr description

Undocumented upstream.

=cut

docker settable => [Str];

=attr settable

Undocumented upstream.

=cut

docker value => [Str];

=attr value

Undocumented upstream.

=cut

1;
