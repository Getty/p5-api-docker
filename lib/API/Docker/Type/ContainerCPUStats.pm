package API::Docker::Type::ContainerCPUStats;
# ABSTRACT: CPU related info of the container
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ContainerCPUUsage;
use API::Docker::Type::ContainerThrottlingData;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerCPUStats> definition of C<spec/v1.51.yaml>.

=cut

docker cpu_usage => 'ContainerCPUUsage', wire => 'cpu_usage', since => '1.51';

=attr cpu_usage

All CPU stats aggregated since container inception. See
L<API::Docker::Type::ContainerCPUUsage>. Serialised as C<cpu_usage> --
spelled out, because deriving it from the Perl name would produce
C<CpuUsage>.

=cut

docker system_cpu_usage => Int, wire => 'system_cpu_usage', since => '1.51';

=attr system_cpu_usage

System Usage.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<system_cpu_usage> -- spelled out, because deriving it from the Perl
name would produce C<SystemCpuUsage>.

=cut

docker online_cpus => Int, wire => 'online_cpus', since => '1.51';

=attr online_cpus

Number of online CPUs.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<online_cpus> -- spelled out, because deriving it from the Perl name
would produce C<OnlineCpus>.

=cut

docker throttling_data => 'ContainerThrottlingData',
  wire => 'throttling_data', since => '1.51';

=attr throttling_data

CPU throttling stats of the container. See
L<API::Docker::Type::ContainerThrottlingData>. Serialised as
C<throttling_data> -- spelled out, because deriving it from the Perl name
would produce C<ThrottlingData>.

=cut

1;
