package API::Docker::Type::Plugin::Config::Network;
# ABSTRACT: The network mode a plugin runs in
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Network> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker type => Str;

=attr type

Undocumented upstream. The object's only field; C<host> in the swagger's
example.

=cut

1;
