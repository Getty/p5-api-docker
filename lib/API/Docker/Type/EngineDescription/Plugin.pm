package API::Docker::Type::EngineDescription::Plugin;
# ABSTRACT: One entry of C<EngineDescription.Plugins>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<EngineDescription.Plugins> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker type => Str;

=attr type

Undocumented upstream. What the plugin plugs into: C<Log>, C<Network> and
C<Volume> are the three the swagger's example uses.

=cut

docker name => Str;

=attr name

Undocumented upstream. Its name -- a bare word for the built-in drivers
(C<json-file>, C<overlay>, C<local>), and a full image reference for an
installed one: C<localhost:5000/vieux/sshfs:latest> in the same example.

=cut

1;
