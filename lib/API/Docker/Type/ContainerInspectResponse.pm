package API::Docker::Type::ContainerInspectResponse;
# ABSTRACT: The body of the C<200> response to C<GET /containers/{id}/json>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ContainerConfig;
use API::Docker::Type::ContainerState;
use API::Docker::Type::DriverData;
use API::Docker::Type::HostConfig;
use API::Docker::Type::MountPoint;
use API::Docker::Type::NetworkSettings;
use API::Docker::Type::OCIDescriptor;

=head1 DESCRIPTION

Generated from the C<ContainerInspectResponse> definition of
C<spec/v1.51.yaml>, which the swagger leaves undescribed. C<paths:> says
what it is: the body of the C<200> response to C<GET /containers/{id}/json>.

=cut

docker id => Str, since => '1.51';

=attr id

The ID of this container as a 128-bit (64-character) hexadecimal string (32
bytes).

=cut

docker created => Str, since => '1.51';

=attr created

Date and time at which the container was created, formatted in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker path => Str, since => '1.51';

=attr path

The path to the command being run.

=cut

docker args => [Str], since => '1.51';

=attr args

The arguments to the command being run.

=cut

docker state => 'ContainerState', since => '1.51';

=attr state

ContainerState stores container's running state. See
L<API::Docker::Type::ContainerState>.

=cut

docker image => Str, since => '1.51';

=attr image

The ID (digest) of the image that this container was created from.

=cut

docker resolv_conf_path => Str, since => '1.51';

=attr resolv_conf_path

Location of the C</etc/resolv.conf> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=cut

docker hostname_path => Str, since => '1.51';

=attr hostname_path

Location of the C</etc/hostname> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=cut

docker hosts_path => Str, since => '1.51';

=attr hosts_path

Location of the C</etc/hosts> generated for the container on the host.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=cut

docker log_path => Str, since => '1.51';

=attr log_path

Location of the file used to buffer the container's logs. Depending on the
logging-driver used for the container, this field may be omitted.

This file is managed through the docker daemon, and should not be accessed
or modified by other tools.

=cut

docker name => Str, since => '1.51';

=attr name

The name associated with this container.

For historic reasons, the name may be prefixed with a forward-slash (C</>).

=cut

docker restart_count => Int, since => '1.51';

=attr restart_count

Number of times the container was restarted since it was created, or since
daemon was started.

=cut

docker driver => Str, since => '1.51';

=attr driver

The storage-driver used for the container's filesystem (graph-driver or
snapshotter).

=cut

docker platform => Str, since => '1.51';

=attr platform

The platform (operating system) for which the container was created.

This field was introduced for the experimental "LCOW" (Linux Containers On
Windows) features, which has been removed. In most cases, this field is
equal to the host's operating system (C<linux> or C<windows>).

=cut

docker image_manifest_descriptor => 'OCIDescriptor', since => '1.51';

=attr image_manifest_descriptor

OCI descriptor of the platform-specific manifest of the image the container
was created from.

Note: Only available if the daemon provides a multi-platform image store.
See L<API::Docker::Type::OCIDescriptor>.

=cut

docker mount_label => Str, since => '1.51';

=attr mount_label

SELinux mount label set for the container.

=cut

docker process_label => Str, since => '1.51';

=attr process_label

SELinux process label set for the container.

=cut

docker app_armor_profile => Str, since => '1.51';

=attr app_armor_profile

The AppArmor profile set for the container.

=cut

docker exec_ids => [Str], wire => 'ExecIDs', since => '1.51';

=attr exec_ids

IDs of exec instances that are running in the container. Serialised as
C<ExecIDs> -- spelled out, because deriving it from the Perl name would
produce C<ExecIds>.

=cut

docker host_config => 'HostConfig', since => '1.51';

=attr host_config

Container configuration that depends on the host we are running on. See
L<API::Docker::Type::HostConfig>.

=cut

docker graph_driver => 'DriverData', since => '1.51';

=attr graph_driver

Information about the storage driver used to store the container's and
image's filesystem. See L<API::Docker::Type::DriverData>.

=cut

docker size_rw => Int, since => '1.51';

=attr size_rw

The size of files that have been created or changed by this container.

This field is omitted by default, and only set when size is requested in the
API request.

=cut

docker size_root_fs => Int, since => '1.51';

=attr size_root_fs

The total size of all files in the read-only layers from the image that the
container uses. These layers can be shared between containers.

This field is omitted by default, and only set when size is requested in the
API request.

=cut

docker mounts => [ 'MountPoint' ], since => '1.51';

=attr mounts

List of mounts used by the container. See L<API::Docker::Type::MountPoint>.

=cut

docker config => 'ContainerConfig', since => '1.51';

=attr config

Configuration for a container that is portable between hosts. See
L<API::Docker::Type::ContainerConfig>.

=cut

docker network_settings => 'NetworkSettings', since => '1.51';

=attr network_settings

NetworkSettings exposes the network settings in the API. See
L<API::Docker::Type::NetworkSettings>.

=cut

1;
