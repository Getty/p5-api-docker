package API::Docker::Type::SecretSpec;
# ABSTRACT: The body of a C<POST /secrets/create> request
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Driver;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<SecretSpec> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/secrets/create> request and a C<POST /secrets/{id}/update> request.

=cut

docker name => Str;

=attr name

User-defined name of the secret.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker data => Str;

=attr data

Data is the data to store as a secret, formatted as a standard
base64-encoded (L<RFC 4648|https://tools.ietf.org/html/rfc4648#section-4>)
string. It must be empty if the Driver field is set, in which case the data
is loaded from an external secret store. The maximum allowed size is 500KB,
as defined in
L<MaxSecretSize|https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0/api/validation#MaxSecretSize>.

This field is only used to I<create> a secret, and is not returned by other
endpoints.

=cut

docker driver => 'Driver';

=attr driver

Name of the secrets driver used to fetch the secret's value from an external
secret store. See L<API::Docker::Type::Driver>.

=cut

docker templating => 'Driver';

=attr templating

Templating driver, if applicable

Templating controls whether and how to evaluate the config payload as a
template. If no driver is set, no templating is used. See
L<API::Docker::Type::Driver>.

=cut

1;
