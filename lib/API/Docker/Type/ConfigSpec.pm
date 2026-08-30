package API::Docker::Type::ConfigSpec;
# ABSTRACT: The body of a C<POST /configs/create> request
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::Driver;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ConfigSpec> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/configs/create> request and a C<POST /configs/{id}/update> request.

=cut

docker name => Str;

=attr name

User-defined name of the config.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker data => Str;

=attr data

Data is the data to store as a config, formatted as a standard
base64-encoded (L<RFC 4648|https://tools.ietf.org/html/rfc4648#section-4>)
string. The maximum allowed size is 1000KB, as defined in
L<MaxConfigSize|https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0-20250103191802-8c1959736554/manager/controlapi#MaxConfigSize>.

=cut

docker templating => 'Driver';

=attr templating

Templating driver, if applicable

Templating controls whether and how to evaluate the config payload as a
template. If no driver is set, no templating is used. See
L<API::Docker::Type::Driver>.

=cut

1;
