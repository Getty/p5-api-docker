package API::Docker::Type::ContainerCPUUsage;
# ABSTRACT: All CPU stats aggregated since container inception
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerCPUUsage> definition of C<spec/v1.51.yaml>.

=cut

docker total_usage => Int, wire => 'total_usage', since => '1.51';

=attr total_usage

Total CPU time consumed in nanoseconds (Linux) or 100's of nanoseconds
(Windows). Serialised as C<total_usage> -- spelled out, because deriving it
from the Perl name would produce C<TotalUsage>.

=cut

docker percpu_usage => [Int], wire => 'percpu_usage', since => '1.51';

=attr percpu_usage

Total CPU time (in nanoseconds) consumed per core (Linux).

This field is Linux-specific when using cgroups v1. It is omitted when using
cgroups v2 and Windows containers. Serialised as C<percpu_usage> -- spelled
out, because deriving it from the Perl name would produce C<PercpuUsage>.

=cut

docker usage_in_kernelmode => Int,
  wire => 'usage_in_kernelmode', since => '1.51';

=attr usage_in_kernelmode

Time (in nanoseconds) spent by tasks of the cgroup in kernel mode (Linux),
or time spent (in 100's of nanoseconds) by all container processes in kernel
mode (Windows).

Not populated for Windows containers using Hyper-V isolation. Serialised as
C<usage_in_kernelmode> -- spelled out, because deriving it from the Perl
name would produce C<UsageInKernelmode>.

=cut

docker usage_in_usermode => Int, wire => 'usage_in_usermode', since => '1.51';

=attr usage_in_usermode

Time (in nanoseconds) spent by tasks of the cgroup in user mode (Linux), or
time spent (in 100's of nanoseconds) by all container processes in kernel
mode (Windows).

Not populated for Windows containers using Hyper-V isolation. Serialised as
C<usage_in_usermode> -- spelled out, because deriving it from the Perl name
would produce C<UsageInUsermode>.

=cut

1;
