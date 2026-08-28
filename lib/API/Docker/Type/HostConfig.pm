package API::Docker::Type::HostConfig;
# ABSTRACT: Container configuration that depends on the host we are running on
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::HostConfig::LogConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::PortBinding;
use API::Docker::Type::RestartPolicy;

=head1 DESCRIPTION

Generated from the C<HostConfig> definition of C<spec/v1.51.yaml>, which is
C<allOf [ $ref Resources, { 39 properties } ]>. The reference becomes a
superclass, so a C<HostConfig> carries the 31 fields of
L<API::Docker::Type::Resources> as well as the 39 declared here -- 70 in
all. See L<API::Docker::Type/C<allOf> becomes inheritance>.

=cut

docker_extends 'Resources';

docker binds => [Str];

=attr binds

A list of volume bindings for this container. Each binding is a string in
one of these forms:

=over 4

=item * C<host-src:container-dest[:options]> to bind-mount a host path into
the container. Both C<host-src> and C<container-dest> must be absolute
paths.

=item * C<volume-name:container-dest[:options]> to bind-mount a volume
managed by a volume driver into the container. C<container-dest> must be an
absolute path.

=back

C<options> is an optional, comma-delimited list of:

=over 4

=item * C<nocopy> disables automatic copying of data from the container path
to the volume. It only applies to named volumes.

=item * C<ro> or C<rw> mounts the volume read-only or read-write. If omitted
or set to C<rw>, volumes are mounted read-write.

=item * C<z> or C<Z> applies SELinux labels to allow or deny multiple
containers to read and write to the same volume. C<z> applies a shared
content label, so several containers can share the volume's content for
both reading and writing; C<Z> applies a private unshared label, so only the
current container can use the volume. Labeling systems such as SELinux
require proper labels on volume content mounted into a container -- without
one the security system can stop the container's processes from using it,
and the labels the host set are not modified by default.

=item * C<[r]shared>, C<[r]slave> or C<[r]private> specifies mount
propagation behaviour. This applies to bind-mounted volumes only, not to
internal or named volumes, and requires the source mount point on the host
to have the matching propagation properties: C<shared> for shared volumes,
either C<shared> or C<slave> for slave volumes.

=back

=cut

docker container_id_file => Str, wire => 'ContainerIDFile';

=attr container_id_file

Path to a file where the container ID is written. Serialised as
C<ContainerIDFile> -- spelled out, because deriving it from the Perl name
would produce C<ContainerIdFile>.

=cut

docker log_config => 'HostConfig::LogConfig';

=attr log_config

The logging configuration for this container. See
L<API::Docker::Type::HostConfig::LogConfig>.

=cut

docker network_mode => Str;

=attr network_mode

Network mode to use for this container. The standard values are C<bridge>,
C<host>, C<none> and C<< container:<name|id> >>; any other value is taken as
the name of a custom network to connect to.

=cut

docker port_bindings => { Str, [ 'PortBinding' ] };

=attr port_bindings

The mapping of container ports to host ports. In the swagger this is a
C<$ref> to C<PortMap>, a definition that is nothing but
C<additionalProperties>, so it becomes a hash here rather than a class of
its own.

B<The keys are the caller's data> and are never translated: they are the
container's port number and protocol in the form C<< <port>/<protocol> >>,
C<80/tcp> or C<53/udp>. Where a container's port is mapped for several
protocols, each gets its own entry. The values are ArrayRefs of
L<API::Docker::Type::PortBinding>, and the daemon does answer with C<null>
for a port that is exposed but not published.

=cut

docker restart_policy => 'RestartPolicy';

=attr restart_policy

The behavior to apply when the container exits. See
L<API::Docker::Type::RestartPolicy>.

=cut

docker auto_remove => Bool;

=attr auto_remove

Automatically remove the container when its process exits. This has no
effect if L</restart_policy> is set.

=cut

docker volume_driver => Str;

=attr volume_driver

Driver that this container uses to mount volumes.

=cut

docker volumes_from => [Str];

=attr volumes_from

A list of volumes to inherit from another container, in the form C<<
<container name>[:<ro|rw>] >>.

=cut

docker mounts => [ 'Mount' ];

=attr mounts

Specification for mounts to be added to the container. See
L<API::Docker::Type::Mount>.

=cut

docker console_size => [Int];

=attr console_size

Initial console size as a C<[height, width]> array -- exactly two
non-negative integers.

=cut

docker annotations => { Str, Str }, since => '1.44';

=attr annotations

Arbitrary non-identifying metadata attached to the container and handed to
the runtime when the container is started. B<The keys are the caller's
data> and are never translated.

=cut

docker cap_add => [Str];

=attr cap_add

A list of kernel capabilities to add to the container. Conflicts with the
C<Capabilities> option.

=cut

docker cap_drop => [Str];

=attr cap_drop

A list of kernel capabilities to drop from the container. Conflicts with
the C<Capabilities> option.

=cut

docker cgroupns_mode => Str, enum => [qw( private host )];

=attr cgroupns_mode

cgroup namespace mode for the container:

=over 4

=item * C<private> the container runs in its own private cgroup namespace

=item * C<host> use the host system's cgroup namespace

=back

If not specified the daemon default is used, which is either of the two
depending on daemon version, kernel support and configuration.

=cut

docker dns => [Str];

=attr dns

A list of DNS servers for the container to use.

=cut

docker dns_options => [Str];

=attr dns_options

A list of DNS options.

=cut

docker dns_search => [Str];

=attr dns_search

A list of DNS search domains.

=cut

docker extra_hosts => [Str];

=attr extra_hosts

A list of hostname/IP mappings to add to the container's C</etc/hosts>
file, in the form C<["hostname:IP"]>.

=cut

docker group_add => [Str];

=attr group_add

A list of additional groups that the container process will run as.

=cut

docker ipc_mode => Str;

=attr ipc_mode

IPC sharing mode for the container:

=over 4

=item * C<none> own private IPC namespace, with /dev/shm not mounted

=item * C<private> own private IPC namespace

=item * C<shareable> own private IPC namespace, with a possibility to share
it with other containers

=item * C<< container:<name|id> >> join another (shareable) container's IPC
namespace

=item * C<host> use the host system's IPC namespace

=back

If not specified the daemon default is used, which is either C<private> or
C<shareable> depending on daemon version and configuration.

=cut

docker cgroup => Str;

=attr cgroup

Cgroup to use for the container.

=cut

docker links => [Str];

=attr links

A list of links for the container, in the form C<container_name:alias>.

=cut

docker oom_score_adj => Int;

=attr oom_score_adj

An integer value containing the score given to the container in order to
tune OOM killer preferences.

=cut

docker pid_mode => Str;

=attr pid_mode

Set the PID (process) namespace mode for the container. It can be either
C<< container:<name|id> >>, which joins another container's PID namespace,
or C<host>, which uses the host's PID namespace inside the container.

=cut

docker privileged => Bool;

=attr privileged

Gives the container full access to the host.

=cut

docker publish_all_ports => Bool;

=attr publish_all_ports

Allocates an ephemeral host port for all of a container's exposed ports.

Ports are de-allocated when the container stops and allocated when it
starts, and the allocated port might change when the container is
restarted. The port is selected from the ephemeral port range the kernel
defines -- on Linux, C</proc/sys/net/ipv4/ip_local_port_range>.

=cut

docker readonly_rootfs => Bool;

=attr readonly_rootfs

Mount the container's root filesystem as read only.

=cut

docker security_opt => [Str];

=attr security_opt

A list of string values to customize labels for MLS systems such as
SELinux.

=cut

docker storage_opt => { Str, Str };

=attr storage_opt

Storage driver options for this container, in the form C<< {"size": "120G"}
>>. B<The keys are the caller's data> and are never translated.

=cut

docker tmpfs => { Str, Str };

=attr tmpfs

A map of container directories which should be replaced by tmpfs mounts,
and their corresponding mount options -- C<< { "/run":
"rw,noexec,nosuid,size=65536k" } >>. B<The keys are the caller's data>:
they are mount paths, and are never translated.

=cut

docker uts_mode => Str, wire => 'UTSMode';

=attr uts_mode

UTS namespace to use for the container. Serialised as C<UTSMode> -- spelled
out, because deriving it from the Perl name would produce C<UtsMode>.

=cut

docker userns_mode => Str;

=attr userns_mode

Sets the user namespace mode for the container when the user namespace
remapping option is enabled.

=cut

docker shm_size => Int;

=attr shm_size

Size of C</dev/shm> in bytes. If omitted, the daemon uses 64MB.

=cut

docker sysctls => { Str, Str };

=attr sysctls

A list of kernel parameters (sysctls) to set in the container, C<<
{"net.ipv4.ip_forward": "1"} >>. Omitted if not set. B<The keys are the
caller's data>: they are dotted kernel parameter names, and are never
translated.

=cut

docker runtime => Str;

=attr runtime

Runtime to use with this container.

=cut

docker isolation => Str, enum => [ 'default', 'process', 'hyperv', '' ];

=attr isolation

Isolation technology of the container (Windows only): C<default>,
C<process>, C<hyperv>, or the empty string.

=cut

docker masked_paths => [Str];

=attr masked_paths

The list of paths to be masked inside the container. Setting this overrides
the daemon's default set of paths.

=cut

docker readonly_paths => [Str];

=attr readonly_paths

The list of paths to be set as read-only inside the container. Setting this
overrides the daemon's default set of paths.

=cut

1;
