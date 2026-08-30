package API::Docker::Type::Limit;
# ABSTRACT: An object describing a limit on resources which can be requested by a task
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Limit> definition of C<spec/v1.51.yaml>.

=cut

docker nano_cpus => Int, wire => 'NanoCPUs';

=attr nano_cpus

Undocumented upstream. A CPU quota in units of 10^-9 CPUs, which is how the
swagger describes the same measure under
L<API::Docker::Type::Resources/nano_cpus>. The example C<4000000000> is four
whole CPUs. Serialised as C<NanoCPUs> -- spelled out, because deriving it
from the Perl name would produce C<NanoCpus>.

=cut

docker memory_bytes => Int;

=attr memory_bytes

Undocumented upstream. A memory limit in bytes, the measure the swagger
describes under L<API::Docker::Type::Resources/memory>. The example
C<8272408576> is roughly 7.7 GiB.

=cut

docker pids => Int;

=attr pids

Limits the maximum number of PIDs in the container. Set C<0> for unlimited.
The daemon defaults it to 0.

=cut

1;
