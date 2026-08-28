package API::Docker::Type::Service::ServiceStatus;
# ABSTRACT: The status of the service's tasks
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<ServiceStatus> schema of the C<Service>
definition in C<spec/v1.51.yaml>.

Provided only when requested as part of a ServiceList operation.

=cut

docker running_tasks => Int;

=attr running_tasks

The number of tasks for the service currently in the Running state.

=cut

docker desired_tasks => Int;

=attr desired_tasks

The number of tasks for the service desired to be running. For replicated
services, this is the replica count from the service spec. For global
services, this is computed by taking count of all tasks for the service with
a Desired State other than Shutdown.

=cut

docker completed_tasks => Int;

=attr completed_tasks

The number of tasks for a job that are in the Completed state. This field
must be cross-referenced with the service type, as the value of 0 may mean
the service is not in a job mode, or it may mean the job-mode service has no
tasks yet Completed.

=cut

1;
