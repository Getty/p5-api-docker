package API::Docker::Type::ClusterInfo;
# ABSTRACT: Information about the swarm as is returned by the "/info" endpoint
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::SwarmSpec;
use API::Docker::Type::TLSInfo;

=head1 DESCRIPTION

Generated from the C<ClusterInfo> definition of C<spec/v1.51.yaml>.

Join-tokens are not included.

=cut

docker id => Str, wire => 'ID';

=attr id

The ID of the swarm. Serialised as C<ID> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Date and time at which the swarm was initialised in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker updated_at => Str;

=attr updated_at

Date and time at which the swarm was last updated in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker spec => 'SwarmSpec';

=attr spec

User modifiable swarm configuration. See L<API::Docker::Type::SwarmSpec>.

=cut

docker tls_info => 'TLSInfo', wire => 'TLSInfo';

=attr tls_info

Information about the issuer of leaf TLS certificates and the trusted root
CA certificate. See L<API::Docker::Type::TLSInfo>. Serialised as C<TLSInfo>
-- spelled out, because deriving it from the Perl name would produce
C<TlsInfo>.

=cut

docker root_rotation_in_progress => Bool;

=attr root_rotation_in_progress

Whether there is currently a root CA rotation in progress for the swarm.

=cut

docker data_path_port => Int;

=attr data_path_port

DataPathPort specifies the data path port number for data traffic.
Acceptable port range is 1024 to 49151. If no port is set or is set to 0,
the default port (4789) is used.

=cut

docker default_addr_pool => [Str];

=attr default_addr_pool

Default Address Pool specifies default subnet pools for global scope
networks.

=cut

docker subnet_size => Int;

=attr subnet_size

SubnetSize specifies the subnet size of the networks created from the
default subnet pool.

=cut

1;
