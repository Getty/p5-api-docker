package API::Docker::Type::SwarmSpec::CAConfig;
# ABSTRACT: CA configuration
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::SwarmSpec::CAConfig::ExternalCA;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<CAConfig> schema of the C<SwarmSpec> definition
in C<spec/v1.51.yaml>.

=cut

docker node_cert_expiry => Int;

=attr node_cert_expiry

The duration node certificates are issued for.

=cut

docker external_cas => [ 'SwarmSpec::CAConfig::ExternalCA' ],
  wire => 'ExternalCAs';

=attr external_cas

Configuration for forwarding signing requests to an external certificate
authority. See L<API::Docker::Type::SwarmSpec::CAConfig::ExternalCA>.
Serialised as C<ExternalCAs> -- spelled out, because deriving it from the
Perl name would produce C<ExternalCas>.

=cut

docker signing_ca_cert => Str, wire => 'SigningCACert';

=attr signing_ca_cert

The desired signing CA certificate for all swarm node TLS leaf certificates,
in PEM format. Serialised as C<SigningCACert> -- spelled out, because
deriving it from the Perl name would produce C<SigningCaCert>.

=cut

docker signing_ca_key => Str, wire => 'SigningCAKey';

=attr signing_ca_key

The desired signing CA key for all swarm node TLS leaf certificates, in PEM
format. Serialised as C<SigningCAKey> -- spelled out, because deriving it
from the Perl name would produce C<SigningCaKey>.

=cut

docker force_rotate => Int;

=attr force_rotate

An integer whose purpose is to force swarm to generate a new signing CA
certificate and key, if none have been specified in C<SigningCACert> and
C<SigningCAKey>.

=cut

1;
