package API::Docker::Type::AuthConfig;
# ABSTRACT: The body of a C<POST /auth> request
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<AuthConfig> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/auth> request.

=cut

docker username => Str, wire => 'username';

=attr username

Undocumented upstream. The registry account name, C<hannibal> in the
definition's own example. Serialised as C<username> -- spelled out, because
deriving it from the Perl name would produce C<Username>.

=cut

docker password => Str, wire => 'password';

=attr password

Undocumented upstream. Its password, C<xxxx> in the definition's own
example. The swagger's introduction gives the same three keys as the
structure that travels base64url-encoded in C<X-Registry-Auth>, and notes
that an identity token from C<POST /auth> can be sent instead of a username
and password; see L<API::Docker::Role::RegistryAuth>. Serialised as
C<password> -- spelled out, because deriving it from the Perl name would
produce C<Password>.

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

Undocumented upstream. The registry to authenticate against. The swagger's
introduction says of this key that it is "a domain/IP without a protocol",
while the definition's own example gives C<https://index.docker.io/v1/> --
which has one. The spec contradicts itself here; this distribution forwards
whatever the caller wrote. Serialised as C<serveraddress> -- spelled out,
because deriving it from the Perl name would produce C<Serveraddress>.

=cut

1;
