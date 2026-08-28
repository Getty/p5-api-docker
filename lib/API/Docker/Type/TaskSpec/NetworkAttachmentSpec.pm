package API::Docker::Type::TaskSpec::NetworkAttachmentSpec;
# ABSTRACT: Read-only spec type for non-swarm containers attached to swarm overlay networks
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<NetworkAttachmentSpec> schema of the C<TaskSpec>
definition in C<spec/v1.51.yaml>.

> B<Note>: ContainerSpec, NetworkAttachmentSpec, and PluginSpec are >
mutually exclusive. PluginSpec is only used when the Runtime field > is set
to C<plugin>. NetworkAttachmentSpec is used when the Runtime > field is set
to C<attachment>.

=cut

docker container_id => Str, wire => 'ContainerID';

=attr container_id

ID of the container represented by this task. Serialised as C<ContainerID>
-- spelled out, because deriving it from the Perl name would produce
C<ContainerId>.

=cut

1;
