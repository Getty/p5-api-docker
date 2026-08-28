package API::Docker::Type::DeviceMapping;
# ABSTRACT: A device mapping between the host and container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<DeviceMapping> definition of C<spec/v1.51.yaml>. None
of its three fields carries a description upstream; the example the swagger
gives is C<< { PathOnHost: "/dev/deviceName", PathInContainer:
"/dev/deviceName", CgroupPermissions: "mrw" } >>.

=cut

docker path_on_host => Str;

=attr path_on_host

Undocumented upstream. The device's path on the host, per the swagger's
example.

=cut

docker path_in_container => Str;

=attr path_in_container

Undocumented upstream. The path the device is to appear under inside the
container, per the swagger's example.

=cut

docker cgroup_permissions => Str;

=attr cgroup_permissions

Undocumented upstream. The cgroup device permissions, C<"mrw"> in the
swagger's example.

=cut

1;
