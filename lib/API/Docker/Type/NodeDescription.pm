package API::Docker::Type::NodeDescription;
# ABSTRACT: NodeDescription encapsulates the properties of the Node as reported by the agent
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::EngineDescription;
use API::Docker::Type::Platform;
use API::Docker::Type::ResourceObject;
use API::Docker::Type::TLSInfo;

=head1 DESCRIPTION

Generated from the C<NodeDescription> definition of C<spec/v1.51.yaml>.

=cut

docker hostname => Str;

=attr hostname

Undocumented upstream. The node's hostname, C<bf3067039e47> in the swagger's
example. As the definition above says, it is what the agent reports, not
what a manager was told.

=cut

docker platform => 'Platform';

=attr platform

Platform represents the platform (Arch/OS). See
L<API::Docker::Type::Platform>.

=cut

docker resources => 'ResourceObject';

=attr resources

An object describing the resources which can be advertised by a node and
requested by a task. See L<API::Docker::Type::ResourceObject>.

=cut

docker engine => 'EngineDescription';

=attr engine

EngineDescription provides information about an engine. See
L<API::Docker::Type::EngineDescription>.

=cut

docker tls_info => 'TLSInfo', wire => 'TLSInfo';

=attr tls_info

Information about the issuer of leaf TLS certificates and the trusted root
CA certificate. See L<API::Docker::Type::TLSInfo>. Serialised as C<TLSInfo>
-- spelled out, because deriving it from the Perl name would produce
C<TlsInfo>.

=cut

1;
