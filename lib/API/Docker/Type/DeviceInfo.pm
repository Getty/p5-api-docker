package API::Docker::Type::DeviceInfo;
# ABSTRACT: A device that can be used by a container
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<DeviceInfo> definition of C<spec/v1.51.yaml>.

=cut

docker source => Str, since => '1.51';

=attr source

The origin device driver.

=cut

docker id => Str, wire => 'ID', since => '1.51';

=attr id

The unique identifier for the device within its source driver. For CDI
devices, this would be an FQDN like "vendor.com/gpu=0". Serialised as C<ID>
-- spelled out, because deriving it from the Perl name would produce C<Id>.

=cut

1;
