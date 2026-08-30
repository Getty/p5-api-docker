package API::Docker::Type::ServiceSpec::RollbackConfig;
# ABSTRACT: Specification for the rollback strategy of the service
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<RollbackConfig> schema of the C<ServiceSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker parallelism => Int;

=attr parallelism

Maximum number of tasks to be rolled back in one iteration (0 means
unlimited parallelism).

=cut

docker delay => Int;

=attr delay

Amount of time between rollback iterations, in nanoseconds.

=cut

docker failure_action => Str, enum => [qw( continue pause )];

=attr failure_action

Action to take if an rolled back task fails to run, or stops running during
the rollback. The swagger enumerates C<continue> and C<pause>.

=cut

docker monitor => Int;

=attr monitor

Amount of time to monitor each rolled back task for failures, in
nanoseconds.

=cut

docker max_failure_ratio => Num;

=attr max_failure_ratio

The fraction of tasks that may fail during a rollback before the failure
action is invoked, specified as a floating point number between 0 and 1. The
daemon defaults it to 0.

=cut

docker order => Str, enum => [qw( stop-first start-first )];

=attr order

The order of operations when rolling back a task. Either the old task is
shut down before the new task is started, or the new task is started before
the old task is shut down. The swagger enumerates C<stop-first> and
C<start-first>.

=cut

1;
