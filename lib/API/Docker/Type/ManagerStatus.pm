package API::Docker::Type::ManagerStatus;
# ABSTRACT: The status of a manager
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ManagerStatus> definition of C<spec/v1.51.yaml>.

It provides the current status of a node's manager component, if the node is
a manager.

=cut

docker leader => Bool;

=attr leader

Undocumented upstream. Of the manager component this class describes:
whether it is the one leading. Defaulted to C<false> upstream and C<true> in
the example.

=cut

docker reachability => Str, enum => [qw( unknown unreachable reachable )];

=attr reachability

Reachability represents the reachability of a node. The swagger enumerates
C<unknown>, C<unreachable> and C<reachable>.

=cut

docker addr => Str;

=attr addr

The IP address and port at which the manager is reachable.

=cut

1;
