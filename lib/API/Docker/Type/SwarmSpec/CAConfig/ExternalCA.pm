package API::Docker::Type::SwarmSpec::CAConfig::ExternalCA;
# ABSTRACT: One entry of C<SwarmSpec.CAConfig.ExternalCAs>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<SwarmSpec.CAConfig.ExternalCAs> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker protocol => Str, enum => [qw( cfssl )];

=attr protocol

Protocol for communication with the external CA (currently only C<cfssl> is
supported). The daemon defaults it to cfssl.

=cut

docker url => Str, wire => 'URL';

=attr url

URL where certificate signing requests should be sent. Serialised as C<URL>
-- spelled out, because deriving it from the Perl name would produce C<Url>.

=cut

docker options => { Str, Str };

=attr options

An object with key/value pairs that are interpreted as protocol-specific
options for the external CA driver. B<The keys are the caller's data> and
are never translated.

=cut

docker ca_cert => Str, wire => 'CACert';

=attr ca_cert

The root CA certificate (in PEM format) this external CA uses to issue TLS
certificates (assumed to be to the current swarm root CA certificate if not
provided). Serialised as C<CACert> -- spelled out, because deriving it from
the Perl name would produce C<CaCert>.

=cut

1;
