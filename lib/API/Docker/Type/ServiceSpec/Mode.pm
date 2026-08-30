package API::Docker::Type::ServiceSpec::Mode;
# ABSTRACT: Scheduling mode for the service
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ServiceSpec::Mode::Replicated;
use API::Docker::Type::ServiceSpec::Mode::ReplicatedJob;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Mode> schema of the C<ServiceSpec> definition in
C<spec/v1.51.yaml>.

=cut

docker replicated => 'ServiceSpec::Mode::Replicated';

=attr replicated

Undocumented upstream. The mode for a service with a fixed number of tasks;
the count is L<API::Docker::Type::ServiceSpec::Mode::Replicated/replicas>,
and the swagger's C<Service> example carries C<< {"Replicated": {"Replicas":
1}} >>. Of the four modes only C<ReplicatedJob> and C<GlobalJob> are
described upstream. See L<API::Docker::Type::ServiceSpec::Mode::Replicated>.

=cut

docker global => Any;

=attr global

Undocumented upstream. One task on every valid node: the same reach the
swagger gives C<GlobalJob>, which it describes as running a task to the
completed state on each valid node, without the running-to-completion part.
An empty object -- naming the mode is the whole of it.

=cut

docker replicated_job => 'ServiceSpec::Mode::ReplicatedJob';

=attr replicated_job

The mode used for services with a finite number of tasks that run to a
completed state. See L<API::Docker::Type::ServiceSpec::Mode::ReplicatedJob>.

=cut

docker global_job => Any;

=attr global_job

The mode used for services which run a task to the completed state on each
valid node.

=cut

1;
