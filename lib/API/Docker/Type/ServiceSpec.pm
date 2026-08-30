package API::Docker::Type::ServiceSpec;
# ABSTRACT: User modifiable configuration for a service
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EndpointSpec;
use API::Docker::Type::NetworkAttachmentConfig;
use API::Docker::Type::ServiceSpec::Mode;
use API::Docker::Type::ServiceSpec::RollbackConfig;
use API::Docker::Type::ServiceSpec::UpdateConfig;
use API::Docker::Type::TaskSpec;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ServiceSpec> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

Name of the service.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker task_template => 'TaskSpec';

=attr task_template

User modifiable task configuration. See L<API::Docker::Type::TaskSpec>.

=cut

docker mode => 'ServiceSpec::Mode';

=attr mode

Scheduling mode for the service. See
L<API::Docker::Type::ServiceSpec::Mode>.

=cut

docker update_config => 'ServiceSpec::UpdateConfig';

=attr update_config

Specification for the update strategy of the service. See
L<API::Docker::Type::ServiceSpec::UpdateConfig>.

=cut

docker rollback_config => 'ServiceSpec::RollbackConfig';

=attr rollback_config

Specification for the rollback strategy of the service. See
L<API::Docker::Type::ServiceSpec::RollbackConfig>.

=cut

docker networks => [ 'NetworkAttachmentConfig' ];

=attr networks

Specifies which networks the service should attach to.

Deprecated: This field is deprecated since v1.44. The Networks field in
TaskSpec should be used instead. See
L<API::Docker::Type::NetworkAttachmentConfig>.

=cut

docker endpoint_spec => 'EndpointSpec';

=attr endpoint_spec

Properties that can be configured to access and load balance a service. See
L<API::Docker::Type::EndpointSpec>.

=cut

1;
