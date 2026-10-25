package API::Docker::Type::NetworkStatus;
# ABSTRACT: provides runtime information about the network such as the number of allocated IPs
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::IPAMStatus;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<NetworkStatus> definition of C<spec/v1.55.yaml>.

=cut

docker ipam => 'IPAMStatus', wire => 'IPAM', since => '1.55';

=attr ipam

Undocumented upstream. See L<API::Docker::Type::IPAMStatus>. Serialised as
C<IPAM> -- spelled out, because deriving it from the Perl name would produce
C<Ipam>.

=cut

1;
