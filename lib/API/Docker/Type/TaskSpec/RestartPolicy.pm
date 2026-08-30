package API::Docker::Type::TaskSpec::RestartPolicy;
# ABSTRACT: Specification for the restart policy which applies to containers created as part of this service
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<RestartPolicy> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker condition => Str, enum => [qw( none on-failure any )];

=attr condition

Condition for restart. The swagger enumerates C<none>, C<on-failure> and
C<any>.

=cut

docker delay => Int;

=attr delay

Delay between restart attempts.

=cut

docker max_attempts => Int;

=attr max_attempts

Maximum attempts to restart a given container before giving up (default
value is 0, which is ignored).

=cut

docker window => Int;

=attr window

Windows is the time window used to evaluate the restart policy (default
value is 0, which is unbounded).

=cut

1;
