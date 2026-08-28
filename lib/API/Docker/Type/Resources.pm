package API::Docker::Type::Resources;
# ABSTRACT: A container's resources (cgroups config, ulimits, etc)
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::DeviceMapping;
use API::Docker::Type::DeviceRequest;
use API::Docker::Type::Resources::BlkioWeightDevice;
use API::Docker::Type::Resources::Ulimit;
use API::Docker::Type::ThrottleDevice;

=head1 DESCRIPTION

Generated from the C<Resources> definition of C<spec/v1.51.yaml>.

L<API::Docker::Type::HostConfig> is C<allOf [ $ref Resources, ... ]> in the
swagger and therefore inherits from this class, which is why every field
below is also a field of a C<HostConfig>. C<TaskSpec> references the
definition directly.

=cut

docker cpu_shares => Int;

=attr cpu_shares

An integer value representing this container's relative CPU weight versus
other containers.

=cut

docker memory => Int;

=attr memory

Memory limit in bytes. The daemon defaults it to 0.

=cut

docker cgroup_parent => Str;

=attr cgroup_parent

Path to C<cgroups> under which the container's C<cgroup> is created. If the
path is not absolute, the path is considered to be relative to the
C<cgroups> path of the init process. Cgroups are created if they do not
already exist.

=cut

docker blkio_weight => Int;

=attr blkio_weight

Block IO weight (relative weight).

=cut

docker blkio_weight_device => [ 'Resources::BlkioWeightDevice' ];

=attr blkio_weight_device

Block IO weight (relative device weight) in the form:

    [{"Path": "device_path", "Weight": weight}]

See L<API::Docker::Type::Resources::BlkioWeightDevice>.

=cut

docker blkio_device_read_bps => [ 'ThrottleDevice' ];

=attr blkio_device_read_bps

Limit read rate (bytes per second) from a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>.

=cut

docker blkio_device_write_bps => [ 'ThrottleDevice' ];

=attr blkio_device_write_bps

Limit write rate (bytes per second) to a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>.

=cut

docker blkio_device_read_iops => [ 'ThrottleDevice' ],
  wire => 'BlkioDeviceReadIOps';

=attr blkio_device_read_iops

Limit read rate (IO per second) from a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>. Serialised as
C<BlkioDeviceReadIOps> -- spelled out, because deriving it from the Perl
name would produce C<BlkioDeviceReadIops>.

=cut

docker blkio_device_write_iops => [ 'ThrottleDevice' ],
  wire => 'BlkioDeviceWriteIOps';

=attr blkio_device_write_iops

Limit write rate (IO per second) to a device, in the form:

    [{"Path": "device_path", "Rate": rate}]

See L<API::Docker::Type::ThrottleDevice>. Serialised as
C<BlkioDeviceWriteIOps> -- spelled out, because deriving it from the Perl
name would produce C<BlkioDeviceWriteIops>.

=cut

docker cpu_period => Int;

=attr cpu_period

The length of a CPU period in microseconds.

=cut

docker cpu_quota => Int;

=attr cpu_quota

Microseconds of CPU time that the container can get in a CPU period.

=cut

docker cpu_realtime_period => Int;

=attr cpu_realtime_period

The length of a CPU real-time period in microseconds. Set to 0 to allocate
no time allocated to real-time tasks.

=cut

docker cpu_realtime_runtime => Int;

=attr cpu_realtime_runtime

The length of a CPU real-time runtime in microseconds. Set to 0 to allocate
no time allocated to real-time tasks.

=cut

docker cpuset_cpus => Str;

=attr cpuset_cpus

CPUs in which to allow execution (e.g., C<0-3>, C<0,1>).

=cut

docker cpuset_mems => Str;

=attr cpuset_mems

Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective
on NUMA systems.

=cut

docker devices => [ 'DeviceMapping' ];

=attr devices

A list of devices to add to the container. See
L<API::Docker::Type::DeviceMapping>.

=cut

docker device_cgroup_rules => [Str];

=attr device_cgroup_rules

A list of cgroup rules to apply to the container.

=cut

docker device_requests => [ 'DeviceRequest' ];

=attr device_requests

A list of requests for devices to be sent to device drivers. See
L<API::Docker::Type::DeviceRequest>.

=cut

docker kernel_memory_tcp => Int, wire => 'KernelMemoryTCP';

=attr kernel_memory_tcp

Hard limit for kernel TCP buffer memory (in bytes). Depending on the OCI
runtime in use, this option may be ignored. It is no longer supported by the
default (runc) runtime.

This field is omitted when empty.

B<Deprecated>: This field is deprecated as kernel 6.12 has deprecated
C<memory.kmem.tcp.limit_in_bytes> field for cgroups v1. This field will be
removed in a future release. Serialised as C<KernelMemoryTCP> -- spelled
out, because deriving it from the Perl name would produce
C<KernelMemoryTcp>.

=cut

docker memory_reservation => Int;

=attr memory_reservation

Memory soft limit in bytes.

=cut

docker memory_swap => Int;

=attr memory_swap

Total memory limit (memory + swap). Set as C<-1> to enable unlimited swap.

=cut

docker memory_swappiness => Int;

=attr memory_swappiness

Tune a container's memory swappiness behavior. Accepts an integer between 0
and 100.

=cut

docker nano_cpus => Int;

=attr nano_cpus

CPU quota in units of 10^-9 CPUs.

=cut

docker oom_kill_disable => Bool;

=attr oom_kill_disable

Disable OOM Killer for the container.

=cut

docker init => Bool;

=attr init

Run an init inside the container that forwards signals and reaps processes.
This field is omitted if empty, and the default (as configured on the
daemon) is used.

=cut

docker pids_limit => Int;

=attr pids_limit

Tune a container's PIDs limit. Set C<0> or C<-1> for unlimited, or C<null>
to not change.

=cut

docker ulimits => [ 'Resources::Ulimit' ];

=attr ulimits

A list of resource limits to set in the container. For example:

    {"Name": "nofile", "Soft": 1024, "Hard": 2048}

See L<API::Docker::Type::Resources::Ulimit>.

=cut

docker cpu_count => Int;

=attr cpu_count

The number of usable CPUs (Windows only).

On Windows Server containers, the processor resource controls are mutually
exclusive. The order of precedence is C<CPUCount> first, then C<CPUShares>,
and C<CPUPercent> last.

=cut

docker cpu_percent => Int;

=attr cpu_percent

The usable percentage of the available CPUs (Windows only).

On Windows Server containers, the processor resource controls are mutually
exclusive. The order of precedence is C<CPUCount> first, then C<CPUShares>,
and C<CPUPercent> last.

=cut

docker io_maximum_iops => Int, wire => 'IOMaximumIOps';

=attr io_maximum_iops

Maximum IOps for the container system drive (Windows only). Serialised as
C<IOMaximumIOps> -- spelled out, because deriving it from the Perl name
would produce C<IoMaximumIops>.

=cut

docker io_maximum_bandwidth => Int, wire => 'IOMaximumBandwidth';

=attr io_maximum_bandwidth

Maximum IO in bytes per second for the container system drive (Windows
only). Serialised as C<IOMaximumBandwidth> -- spelled out, because deriving
it from the Perl name would produce C<IoMaximumBandwidth>.

=cut

1;
