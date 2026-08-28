package API::Docker::Type::ProcessConfig;
# ABSTRACT: The C<ProcessConfig> field of the C<200> response to C<GET /exec/{id}/json>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ProcessConfig> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. C<paths:> says what it is: the
C<ProcessConfig> field of the C<200> response to C<GET /exec/{id}/json>.

=cut

docker privileged => Bool, wire => 'privileged';

=attr privileged

Undocumented upstream. Serialised as C<privileged> -- spelled out, because
deriving it from the Perl name would produce C<Privileged>.

=cut

docker user => Str, wire => 'user';

=attr user

Undocumented upstream. Serialised as C<user> -- spelled out, because
deriving it from the Perl name would produce C<User>.

=cut

docker tty => Bool, wire => 'tty';

=attr tty

Undocumented upstream. Serialised as C<tty> -- spelled out, because deriving
it from the Perl name would produce C<Tty>.

=cut

docker entrypoint => Str, wire => 'entrypoint';

=attr entrypoint

Undocumented upstream. Serialised as C<entrypoint> -- spelled out, because
deriving it from the Perl name would produce C<Entrypoint>.

=cut

docker arguments => [Str], wire => 'arguments';

=attr arguments

Undocumented upstream. Serialised as C<arguments> -- spelled out, because
deriving it from the Perl name would produce C<Arguments>.

=cut

1;
