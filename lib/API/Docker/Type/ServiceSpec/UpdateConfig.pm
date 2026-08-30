package API::Docker::Type::ServiceSpec::UpdateConfig;
# ABSTRACT: Specification for the update strategy of the service
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<UpdateConfig> schema of the C<ServiceSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker parallelism => Int;

=attr parallelism

Maximum number of tasks to be updated in one iteration (0 means unlimited
parallelism).

=cut

docker delay => Int;

=attr delay

Amount of time between updates, in nanoseconds.

=cut

docker failure_action => Str, enum => [qw( continue pause rollback )];

=attr failure_action

Action to take if an updated task fails to run, or stops running during the
update. The swagger enumerates C<continue>, C<pause> and C<rollback>.

=cut

docker monitor => Int;

=attr monitor

Amount of time to monitor each updated task for failures, in nanoseconds.

=cut

docker max_failure_ratio => Num;

=attr max_failure_ratio

The fraction of tasks that may fail during an update before the failure
action is invoked, specified as a floating point number between 0 and 1. The
daemon defaults it to 0.

=cut

docker order => Str, enum => [qw( stop-first start-first )];

=attr order

The order of operations when rolling out an updated task. Either the old
task is shut down before the new task is started, or the new task is started
before the old task is shut down. The swagger enumerates C<stop-first> and
C<start-first>.

=cut

1;
