package API::Docker::Type::Service::JobStatus;
# ABSTRACT: The status of the service when it is in one of ReplicatedJob or GlobalJob modes
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<JobStatus> schema of the C<Service> definition
in C<spec/v1.51.yaml>.

Absent on Replicated and Global mode services. The JobIteration is an
ObjectVersion, but unlike the Service's version, does not need to be sent
with an update request.

=cut

docker job_iteration => 'ObjectVersion';

=attr job_iteration

JobIteration is a value increased each time a Job is executed, successfully
or otherwise. "Executed", in this case, means the job as a whole has been
started, not that an individual Task has been launched. A job is "Executed"
when its ServiceSpec is updated. JobIteration can be used to disambiguate
Tasks belonging to different executions of a job. Though JobIteration will
increase with each subsequent execution, it may not necessarily increase by
1, and so JobIteration should not be used to. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker last_execution => Str;

=attr last_execution

The last time, as observed by the server, that this job was started.

=cut

1;
