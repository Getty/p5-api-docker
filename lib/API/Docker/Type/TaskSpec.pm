package API::Docker::Type::TaskSpec;
# ABSTRACT: User modifiable task configuration
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::NetworkAttachmentConfig;
use API::Docker::Type::TaskSpec::ContainerSpec;
use API::Docker::Type::TaskSpec::LogDriver;
use API::Docker::Type::TaskSpec::NetworkAttachmentSpec;
use API::Docker::Type::TaskSpec::Placement;
use API::Docker::Type::TaskSpec::PluginSpec;
use API::Docker::Type::TaskSpec::Resources;
use API::Docker::Type::TaskSpec::RestartPolicy;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<TaskSpec> definition of C<spec/v1.51.yaml>.

=cut

docker plugin_spec => 'TaskSpec::PluginSpec';

=attr plugin_spec

Plugin spec for the service. *(Experimental release only.)*

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::PluginSpec>.

=cut

docker container_spec => 'TaskSpec::ContainerSpec';

=attr container_spec

Container spec for the service.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::ContainerSpec>.

=cut

docker network_attachment_spec => 'TaskSpec::NetworkAttachmentSpec';

=attr network_attachment_spec

Read-only spec type for non-swarm containers attached to swarm overlay
networks.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>. See L<API::Docker::Type::TaskSpec::NetworkAttachmentSpec>.

=cut

docker resources => 'TaskSpec::Resources';

=attr resources

Resource requirements which apply to each individual container created as
part of the service. See L<API::Docker::Type::TaskSpec::Resources>.

=cut

docker restart_policy => 'TaskSpec::RestartPolicy';

=attr restart_policy

Specification for the restart policy which applies to containers created as
part of this service. See L<API::Docker::Type::TaskSpec::RestartPolicy>.

=cut

docker placement => 'TaskSpec::Placement';

=attr placement

Undocumented upstream. Empty (C<{}>) in both the C<Service> and the C<Task>
example, which restrict nothing. See
L<API::Docker::Type::TaskSpec::Placement>.

=cut

docker force_update => Int;

=attr force_update

A counter that triggers an update even if no relevant parameters have been
changed.

=cut

docker runtime => Str;

=attr runtime

Runtime is the type of runtime specified for the task executor.

=cut

docker networks => [ 'NetworkAttachmentConfig' ];

=attr networks

Specifies which networks the service should attach to. See
L<API::Docker::Type::NetworkAttachmentConfig>.

=cut

docker log_driver => 'TaskSpec::LogDriver';

=attr log_driver

Specifies the log driver to use for tasks created from this spec. If not
present, the default one for the swarm will be used, finally falling back to
the engine default if not specified. See
L<API::Docker::Type::TaskSpec::LogDriver>.

=cut

1;
