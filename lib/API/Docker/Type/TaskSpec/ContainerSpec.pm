package API::Docker::Type::TaskSpec::ContainerSpec;
# ABSTRACT: Container spec for the service
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;
use API::Docker::Type::Mount;
use API::Docker::Type::TaskSpec::ContainerSpec::Config;
use API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges;
use API::Docker::Type::TaskSpec::ContainerSpec::Secret;
use API::Docker::Type::TaskSpec::ContainerSpec::Ulimit;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<ContainerSpec> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=cut

docker image => Str;

=attr image

The image name to use for the container.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value data. B<The keys are the caller's data> and are never
translated.

=cut

docker command => [Str];

=attr command

The command to be run in the image.

=cut

docker args => [Str];

=attr args

Arguments to the command.

=cut

docker hostname => Str;

=attr hostname

The hostname to use for the container, as a valid L<RFC
1123|https://tools.ietf.org/html/rfc1123> hostname.

=cut

docker env => [Str];

=attr env

A list of environment variables in the form C<VAR=value>.

=cut

docker dir => Str;

=attr dir

The working directory for commands to run in.

=cut

docker user => Str;

=attr user

The user inside the container.

=cut

docker groups => [Str];

=attr groups

A list of additional groups that the container process will run as.

=cut

docker privileges => 'TaskSpec::ContainerSpec::Privileges';

=attr privileges

Security options for the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges>.

=cut

docker tty => Bool, wire => 'TTY';

=attr tty

Whether a pseudo-TTY should be allocated. Serialised as C<TTY> -- spelled
out, because deriving it from the Perl name would produce C<Tty>.

=cut

docker open_stdin => Bool;

=attr open_stdin

Open C<stdin>.

=cut

docker read_only => Bool;

=attr read_only

Mount the container's root filesystem as read only.

=cut

docker mounts => [ 'Mount' ];

=attr mounts

Specification for mounts to be added to containers created as part of the
service. See L<API::Docker::Type::Mount>.

=cut

docker stop_signal => Str;

=attr stop_signal

Signal to stop the container.

=cut

docker stop_grace_period => Int;

=attr stop_grace_period

Amount of time to wait for the container to terminate before forcefully
killing it.

=cut

docker health_check => 'HealthConfig';

=attr health_check

A test to perform to check that the container is healthy. See
L<API::Docker::Type::HealthConfig>.

=cut

docker hosts => [Str];

=attr hosts

A list of hostname/IP mappings to add to the container's C<hosts> file. The
format of extra hosts is specified in the
L<hosts(5)|http://man7.org/linux/man-pages/man5/hosts.5.html> man page:

IP_address canonical_hostname [aliases...].

=cut

docker dns_config => 'TaskSpec::ContainerSpec::DNSConfig',
  wire => 'DNSConfig';

=attr dns_config

Specification for DNS related configurations in resolver configuration file
(C<resolv.conf>). See
L<API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig>. Serialised as
C<DNSConfig> -- spelled out, because deriving it from the Perl name would
produce C<DnsConfig>.

=cut

docker secrets => [ 'TaskSpec::ContainerSpec::Secret' ];

=attr secrets

Secrets contains references to zero or more secrets that will be exposed to
the service. See L<API::Docker::Type::TaskSpec::ContainerSpec::Secret>.

=cut

docker oom_score_adj => Int, since => '1.51';

=attr oom_score_adj

An integer value containing the score given to the container in order to
tune OOM killer preferences.

=cut

docker configs => [ 'TaskSpec::ContainerSpec::Config' ];

=attr configs

Configs contains references to zero or more configs that will be exposed to
the service. See L<API::Docker::Type::TaskSpec::ContainerSpec::Config>.

=cut

docker isolation => Str, enum => [ 'default', 'process', 'hyperv', '' ];

=attr isolation

Isolation technology of the containers running the service. (Windows only).
The swagger enumerates C<default>, C<process>, C<hyperv> and the empty
string.

=cut

docker init => Bool;

=attr init

Run an init inside the container that forwards signals and reaps processes.
This field is omitted if empty, and the default (as configured on the
daemon) is used.

=cut

docker sysctls => { Str, Str };

=attr sysctls

Set kernel namedspaced parameters (sysctls) in the container. The Sysctls
option on services accepts the same sysctls as the are supported on
containers. Note that while the same sysctls are supported, no guarantees or
checks are made about their suitability for a clustered environment, and
it's up to the user to determine whether a given sysctl will work properly
in a Service. B<The keys are the caller's data> and are never translated.

=cut

docker capability_add => [Str];

=attr capability_add

A list of kernel capabilities to add to the default set for the container.

=cut

docker capability_drop => [Str];

=attr capability_drop

A list of kernel capabilities to drop from the default set for the
container.

=cut

docker ulimits => [ 'TaskSpec::ContainerSpec::Ulimit' ];

=attr ulimits

A list of resource limits to set in the container. For example: C<{"Name":
"nofile", "Soft": 1024, "Hard": 2048}>". See
L<API::Docker::Type::TaskSpec::ContainerSpec::Ulimit>.

=cut

1;
