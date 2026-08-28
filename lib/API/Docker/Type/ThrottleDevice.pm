package API::Docker::Type::ThrottleDevice;
# ABSTRACT: A per-device block IO rate limit
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ThrottleDevice> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is one entry of C<Resources.BlkioDeviceReadBps>,
C<Resources.BlkioDeviceReadIOps>, C<Resources.BlkioDeviceWriteBps> and
C<Resources.BlkioDeviceWriteIOps>.

=cut

docker path => Str;

=attr path

Device path.

=cut

docker rate => Int;

=attr rate

Rate. What it counts depends on the field this device sits in: bytes per
second under C<blkio_device_read_bps> and C<blkio_device_write_bps>, IO
operations per second under C<blkio_device_read_iops> and
C<blkio_device_write_iops>.

=cut

1;
