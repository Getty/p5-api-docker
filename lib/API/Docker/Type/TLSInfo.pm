package API::Docker::Type::TLSInfo;
# ABSTRACT: Information about the issuer of leaf TLS certificates and the trusted root CA certificate
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<TLSInfo> definition of C<spec/v1.51.yaml>.

=cut

docker trust_root => Str;

=attr trust_root

The root CA certificate(s) that are used to validate leaf TLS certificates.

=cut

docker cert_issuer_subject => Str;

=attr cert_issuer_subject

The base64-url-safe-encoded raw subject bytes of the issuer.

=cut

docker cert_issuer_public_key => Str;

=attr cert_issuer_public_key

The base64-url-safe-encoded raw public key bytes of the issuer.

=cut

1;
