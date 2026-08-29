package API::Docker::Type::Address;
# ABSTRACT: An IPv4 or IPv6 IP address
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Address> definition of C<spec/v1.51.yaml>.

=cut

docker addr => Str;

=attr addr

IP address.

=cut

docker prefix_len => Int;

=attr prefix_len

Mask length of the IP address.

=cut

1;
