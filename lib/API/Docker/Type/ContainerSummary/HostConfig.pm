package API::Docker::Type::ContainerSummary::HostConfig;
# ABSTRACT: Summary of host-specific runtime information of the container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<HostConfig> schema of the C<ContainerSummary>
definition in C<spec/v1.51.yaml>.

This is a reduced set of information in the container's "HostConfig" as
available in the container "inspect" response.

=cut

docker network_mode => Str;

=attr network_mode

Networking mode (C<host>, C<none>, C<< container:<id> >>) or name of the
primary network the container is using.

This field is primarily for backward compatibility. The container can be
connected to multiple networks for which information can be found in the
C<NetworkSettings.Networks> field, which enumerates settings per network.

=cut

docker annotations => { Str, Str }, since => '1.51';

=attr annotations

Arbitrary key-value metadata attached to the container. B<The keys are the
caller's data> and are never translated.

=cut

1;
