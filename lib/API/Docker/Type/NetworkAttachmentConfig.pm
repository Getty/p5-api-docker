package API::Docker::Type::NetworkAttachmentConfig;
# ABSTRACT: Specifies how a service should be attached to a particular network
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<NetworkAttachmentConfig> definition of
C<spec/v1.51.yaml>.

=cut

docker target => Str;

=attr target

The target network for attachment. Must be a network name or ID.

=cut

docker aliases => [Str];

=attr aliases

Discoverable alternate names for the service on this network.

=cut

docker driver_opts => { Str, Str };

=attr driver_opts

Driver attachment options for the network target. B<The keys are the
caller's data> and are never translated.

=cut

1;
