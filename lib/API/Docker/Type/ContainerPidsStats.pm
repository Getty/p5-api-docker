package API::Docker::Type::ContainerPidsStats;
# ABSTRACT: PidsStats contains Linux-specific stats of a container's process-IDs (PIDs)
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerPidsStats> definition of C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=cut

docker current => Int, wire => 'current', since => '1.51';

=attr current

Current is the number of PIDs in the cgroup. Serialised as C<current> --
spelled out, because deriving it from the Perl name would produce
C<Current>.

=cut

docker limit => Int, wire => 'limit', since => '1.51';

=attr limit

Limit is the hard limit on the number of pids in the cgroup. A "Limit" of 0
means that there is no limit. Serialised as C<limit> -- spelled out, because
deriving it from the Perl name would produce C<Limit>.

=cut

1;
