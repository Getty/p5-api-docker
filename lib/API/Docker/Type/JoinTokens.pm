package API::Docker::Type::JoinTokens;
# ABSTRACT: The tokens workers and managers need to join the swarm
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<JoinTokens> definition of C<spec/v1.51.yaml>.

=cut

docker worker => Str;

=attr worker

The token workers can use to join the swarm.

=cut

docker manager => Str;

=attr manager

The token managers can use to join the swarm.

=cut

1;
