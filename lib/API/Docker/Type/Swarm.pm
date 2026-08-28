package API::Docker::Type::Swarm;
# ABSTRACT: The body of the C<200> response to C<GET /swarm>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::JoinTokens;

=head1 DESCRIPTION

Generated from the C<Swarm> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of the
C<200> response to C<GET /swarm>, which is C<allOf [ $ref ClusterInfo, { 1
properties } ]>. The reference becomes a superclass, so a C<Swarm> carries
the 10 fields of L<API::Docker::Type::ClusterInfo> as well as the 1 declared
here -- 11 in all. See L<API::Docker::Type/C<allOf> becomes inheritance>.

=cut

docker_extends 'ClusterInfo';

docker join_tokens => 'JoinTokens';

=attr join_tokens

JoinTokens contains the tokens workers and managers need to join the swarm.
See L<API::Docker::Type::JoinTokens>.

=cut

1;
