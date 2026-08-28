package API::Docker::Type::AuthConfig;
# ABSTRACT: The body of a C<POST /auth> request
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<AuthConfig> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/auth> request.

=cut

docker username => Str, wire => 'username';

=attr username

Undocumented upstream. Serialised as C<username> -- spelled out, because
deriving it from the Perl name would produce C<Username>.

=cut

docker password => Str, wire => 'password';

=attr password

Undocumented upstream. Serialised as C<password> -- spelled out, because
deriving it from the Perl name would produce C<Password>.

=cut

docker email => Str, wire => 'email';

=attr email

Email is an optional value associated with the username.

> B<Deprecated>: This field is deprecated since docker 1.11 (API v1.23) and
will be removed in a future release. Serialised as C<email> -- spelled out,
because deriving it from the Perl name would produce C<Email>.

=cut

docker serveraddress => Str, wire => 'serveraddress';

=attr serveraddress

Undocumented upstream. Serialised as C<serveraddress> -- spelled out,
because deriving it from the Perl name would produce C<Serveraddress>.

=cut

1;
