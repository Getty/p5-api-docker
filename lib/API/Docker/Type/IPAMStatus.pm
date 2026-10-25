package API::Docker::Type::IPAMStatus;
# ABSTRACT: The value of C<NetworkStatus.IPAM>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::SubnetStatus;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<IPAMStatus> definition of C<spec/v1.55.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
the value of C<NetworkStatus.IPAM>.

=cut

docker subnets => { Str, 'SubnetStatus' }, since => '1.55';

=attr subnets

Undocumented upstream. See L<API::Docker::Type::SubnetStatus>. B<The keys
are the caller's data> and are never translated.

=cut

1;
