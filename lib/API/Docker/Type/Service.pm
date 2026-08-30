package API::Docker::Type::Service;
# ABSTRACT: One entry of the C<200> response to C<GET /services>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::Service::Endpoint;
use API::Docker::Type::Service::JobStatus;
use API::Docker::Type::Service::ServiceStatus;
use API::Docker::Type::Service::UpdateStatus;
use API::Docker::Type::ServiceSpec;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Service> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /services> and the body of the C<200> response to
C<GET /services/{id}>.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. The service's ID, C<9mnpnzenvg8p8tdbtq4wvbkcz> in the
swagger's example -- the value that example's companion C<Task> repeats as
its C<ServiceID>. Serialised as C<ID> -- spelled out, because deriving it
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
C<2016-06-07T21:05:51.880065305Z> in the swagger's example.

=cut

docker updated_at => Str;

=attr updated_at

Undocumented upstream. The same format, and in that example some
ninety-eight seconds later than L</created_at>.

=cut

docker spec => 'ServiceSpec';

=attr spec

User modifiable configuration for a service. See
L<API::Docker::Type::ServiceSpec>.

=cut

docker endpoint => 'Service::Endpoint';

=attr endpoint

Undocumented upstream. The ports and virtual IPs the swarm actually gave the
service. What was asked for is the C<EndpointSpec> inside L</spec>, and the
endpoint repeats it as its own C<Spec> -- in the swagger's example all three
copies of the port entry agree. See L<API::Docker::Type::Service::Endpoint>.

=cut

docker update_status => 'Service::UpdateStatus';

=attr update_status

The status of a service update. See
L<API::Docker::Type::Service::UpdateStatus>.

=cut

docker service_status => 'Service::ServiceStatus';

=attr service_status

The status of the service's tasks. Provided only when requested as part of a
ServiceList operation. See L<API::Docker::Type::Service::ServiceStatus>.

=cut

docker job_status => 'Service::JobStatus';

=attr job_status

The status of the service when it is in one of ReplicatedJob or GlobalJob
modes. Absent on Replicated and Global mode services. The JobIteration is an
ObjectVersion, but unlike the Service's version, does not need to be sent
with an update request. See L<API::Docker::Type::Service::JobStatus>.

=cut

1;
