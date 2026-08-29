package API::Docker::Type::Plugin::Config::User;
# ABSTRACT: The user and group a plugin's process runs as
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<User> schema of C<Plugin.Config> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker uid => Int, wire => 'UID';

=attr uid

Undocumented upstream. A C<uint32>; the swagger's example is C<1000>.
Serialised as C<UID> -- spelled out, because deriving it from the Perl name
would produce C<Uid>.

=cut

docker gid => Int, wire => 'GID';

=attr gid

Undocumented upstream. A C<uint32> too, C<1000> in the same example.
Serialised as C<GID> -- spelled out, because deriving it from the Perl name
would produce C<Gid>.

=cut

1;
