package API::Docker::Type::ContainerSummary::NetworkSettings;
# ABSTRACT: Summary of the container's network settings
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::EndpointSettings;

=head1 DESCRIPTION

Generated from the inline C<NetworkSettings> schema of the
C<ContainerSummary> definition in C<spec/v1.51.yaml>.

=cut

docker networks => { Str, 'EndpointSettings' };

=attr networks

Summary of network-settings for each network the container is attached to.
See L<API::Docker::Type::EndpointSettings>. B<The keys are the caller's
data> and are never translated.

=cut

1;
