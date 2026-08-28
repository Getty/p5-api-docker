package API::Docker::Type::Task;
# ABSTRACT: One entry of the C<200> response to C<GET /tasks>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::GenericResource;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::TaskSpec;
use API::Docker::Type::TaskStatus;

=head1 DESCRIPTION

Generated from the C<Task> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /tasks> and the body of the C<200> response to
C<GET /tasks/{id}>.

=cut

docker id => Str, wire => 'ID';

=attr id

The ID of the task. Serialised as C<ID> -- spelled out, because deriving it
from the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Undocumented upstream. RFC 3339 with nanoseconds,
C<2016-06-07T21:07:31.171892745Z> in the swagger's example.

=cut

docker updated_at => Str;

=attr updated_at

Undocumented upstream. The same format, two hundred milliseconds later in
that example -- the task was created and then reported running.

=cut

docker name => Str;

=attr name

Name of the task.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker spec => 'TaskSpec';

=attr spec

User modifiable task configuration. See L<API::Docker::Type::TaskSpec>.

=cut

docker service_id => Str, wire => 'ServiceID';

=attr service_id

The ID of the service this task is part of. Serialised as C<ServiceID> --
spelled out, because deriving it from the Perl name would produce
C<ServiceId>.

=cut

docker slot => Int;

=attr slot

Undocumented upstream. C<1> in the swagger's example, whose C<ServiceID> is
the same C<9mnpnzenvg8p8tdbtq4wvbkcz> the C<Service> example carries, and
that service asks for one replica. Read it as which replica of the service
this task is.

=cut

docker node_id => Str, wire => 'NodeID';

=attr node_id

The ID of the node that this task is on. Serialised as C<NodeID> -- spelled
out, because deriving it from the Perl name would produce C<NodeId>.

=cut

docker assigned_generic_resources => [ 'GenericResource' ];

=attr assigned_generic_resources

User-defined resources can be either Integer resources (e.g, C<SSD=3>) or
String resources (e.g, C<GPU=UUID1>). See
L<API::Docker::Type::GenericResource>.

=cut

docker status => 'TaskStatus';

=attr status

Represents the status of a task. See L<API::Docker::Type::TaskStatus>.

=cut

docker desired_state => Str,
  enum => [qw(
    new allocated pending assigned accepted preparing ready starting running
    complete shutdown failed rejected remove orphaned
  )];

=attr desired_state

Undocumented upstream. Where the orchestrator wants the task, against
L<API::Docker::Type::TaskStatus/state> which is where it actually is. Both
are C<running> in the swagger's example. The swagger enumerates C<new>,
C<allocated>, C<pending>, C<assigned>, C<accepted>, C<preparing>, C<ready>,
C<starting>, C<running>, C<complete>, C<shutdown>, C<failed>, C<rejected>,
C<remove> and C<orphaned>.

=cut

docker job_iteration => 'ObjectVersion';

=attr job_iteration

If the Service this Task belongs to is a job-mode service, contains the
JobIteration of the Service this Task was created for. Absent if the Task
was created for a Replicated or Global Service. See
L<API::Docker::Type::ObjectVersion>.

=cut

1;
