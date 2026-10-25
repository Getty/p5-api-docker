package API::Docker::Type::SubnetStatus;
# ABSTRACT: One value of C<IPAMStatus.Subnets>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<SubnetStatus> definition of C<spec/v1.55.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one value of C<IPAMStatus.Subnets>.

=cut

docker ips_in_use => Int, wire => 'IPsInUse', since => '1.55';

=attr ips_in_use

Number of IP addresses in the subnet that are in use or reserved and are
therefore unavailable for allocation, saturating at 2^64 - 1. Serialised as
C<IPsInUse> -- spelled out, because deriving it from the Perl name would
produce C<IpsInUse>.

=cut

docker dynamic_ips_available => Int,
  wire => 'DynamicIPsAvailable', since => '1.55';

=attr dynamic_ips_available

Number of IP addresses within the network's IPRange for the subnet that are
available for allocation, saturating at 2^64 - 1. Serialised as
C<DynamicIPsAvailable> -- spelled out, because deriving it from the Perl
name would produce C<DynamicIpsAvailable>.

=cut

1;
