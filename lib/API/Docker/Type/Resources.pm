package API::Docker::Type::Resources;
# ABSTRACT: A container's resources -- cgroups config, ulimits and the rest
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

Path to the C<cgroups> under which the container's C<cgroup> is created. If
the path is not absolute it is taken relative to the C<cgroups> path of the
init process. Cgroups are created if they do not already exist.

=cut

docker blkio_weight => Int;

=attr blkio_weight

Block IO weight, a relative weight between 0 and 1000.

=cut

docker blkio_weight_device => [ 'Resources::BlkioWeightDevice' ];

=attr blkio_weight_device

Block IO weight as a relative device weight, in the form C<< [{"Path":
"device_path", "Weight": weight}] >>. See
L<API::Docker::Type::Resources::BlkioWeightDevice>.

=cut

docker blkio_device_read_bps => [ 'ThrottleDevice' ];

=attr blkio_device_read_bps

Limit read rate in bytes per second from a device, in the form C<<
[{"Path": "device_path", "Rate": rate}] >>.

=cut

docker blkio_device_write_bps => [ 'ThrottleDevice' ];

=attr blkio_device_write_bps

Limit write rate in bytes per second to a device, in the form C<< [{"Path":
"device_path", "Rate": rate}] >>.

=cut

docker blkio_device_read_iops => [ 'ThrottleDevice' ], wire => 'BlkioDeviceReadIOps';

=attr blkio_device_read_iops

Limit read rate in IO per second from a device, in the form C<< [{"Path":
"device_path", "Rate": rate}] >>. Serialised as C<BlkioDeviceReadIOps> --
spelled out, because deriving it from the Perl name would produce
C<BlkioDeviceReadIops>.

=cut

docker blkio_device_write_iops => [ 'ThrottleDevice' ], wire => 'BlkioDeviceWriteIOps';

=attr blkio_device_write_iops

Limit write rate in IO per second to a device, in the form C<< [{"Path":
"device_path", "Rate": rate}] >>. Serialised as C<BlkioDeviceWriteIOps>,
see L</blkio_device_read_iops>.

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
no time to real-time tasks.

=cut

docker cpu_realtime_runtime => Int;

=attr cpu_realtime_runtime

The length of a CPU real-time runtime in microseconds. Set to 0 to allocate
no time to real-time tasks.

=cut

docker cpuset_cpus => Str;

=attr cpuset_cpus

CPUs in which to allow execution, C<0-3> or C<0,1>.

=cut

docker cpuset_mems => Str;

=attr cpuset_mems

Memory nodes (MEMs) in which to allow execution, C<0-3> or C<0,1>. Only
effective on NUMA systems.

=cut

docker devices => [ 'DeviceMapping' ];

=attr devices

A list of devices to add to the container. See
L<API::Docker::Type::DeviceMapping>.

=cut

docker device_cgroup_rules => [Str];

=attr device_cgroup_rules

A list of cgroup rules to apply to the container, C<"c 13:* rwm"> for
instance.

=cut

docker device_requests => [ 'DeviceRequest' ];

=attr device_requests

A list of requests for devices to be sent to device drivers. See
L<API::Docker::Type::DeviceRequest>.

=cut

docker kernel_memory_tcp => Int, wire => 'KernelMemoryTCP';

=attr kernel_memory_tcp

Hard limit for kernel TCP buffer memory, in bytes. Depending on the OCI
runtime in use this option may be ignored; the default C<runc> runtime no
longer supports it. Omitted when empty.

B<Deprecated> upstream: kernel 6.12 deprecated the C<memory.kmem.tcp.limit_in_bytes>
field for cgroups v1, and the swagger says the field will be removed in a
future release.

Serialised as C<KernelMemoryTCP> -- spelled out, because deriving it from
the Perl name would produce C<KernelMemoryTcp>.

=cut

docker memory_reservation => Int;

=attr memory_reservation

Memory soft limit in bytes.

=cut

docker memory_swap => Int;

=attr memory_swap

Total memory limit, memory plus swap. Set to C<-1> to enable unlimited
swap.

=cut

docker memory_swappiness => Int;

=attr memory_swappiness

Tune a container's memory swappiness behaviour. An integer between 0 and
100.

=cut

docker nano_cpus => Int;

=attr nano_cpus

CPU quota in units of 10^-9 CPUs.

=cut

docker oom_kill_disable => Bool;

=attr oom_kill_disable

Disable the OOM killer for the container.

=cut

docker init => Bool;

=attr init

Run an init inside the container that forwards signals and reaps processes.
Omitted if empty, in which case the default configured on the daemon is
used.

=cut

docker pids_limit => Int;

=attr pids_limit

Tune a container's PIDs limit. Set C<0> or C<-1> for unlimited; leaving the
attribute unset means "do not change", which is what the swagger's C<null>
says.

=cut

docker ulimits => [ 'Resources::Ulimit' ];

=attr ulimits

A list of resource limits to set in the container, C<< {"Name": "nofile",
"Soft": 1024, "Hard": 2048} >> for instance. See
L<API::Docker::Type::Resources::Ulimit>.

=cut

docker cpu_count => Int;

=attr cpu_count

The number of usable CPUs (Windows only).

On Windows Server containers the processor resource controls are mutually
exclusive; the order of precedence is C<CpuCount> first, then C<CpuShares>,
and C<CpuPercent> last.

=cut

docker cpu_percent => Int;

=attr cpu_percent

The usable percentage of the available CPUs (Windows only). See
L</cpu_count> for the order of precedence.

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
only). Serialised as C<IOMaximumBandwidth>, see L</io_maximum_iops>.

=cut

1;
