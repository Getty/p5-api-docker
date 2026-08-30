package API::Docker::Type::SystemInfo::DefaultAddressPool;
# ABSTRACT: One entry of C<SystemInfo.DefaultAddressPools>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<SystemInfo.DefaultAddressPools> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker base => Str;

=attr base

The network address in CIDR format.

=cut

docker size => Int;

=attr size

The network pool size.

=cut

1;
