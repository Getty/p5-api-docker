package API::Docker::Type::NetworkingConfig;
# ABSTRACT: The container's networking configuration for each of its interfaces
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EndpointSettings;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<NetworkingConfig> definition of C<spec/v1.51.yaml>.

It is used for the networking configs specified in the C<docker create> and
C<docker network connect> commands.

=cut

docker endpoints_config => { Str, 'EndpointSettings' };

=attr endpoints_config

A mapping of network name to endpoint configuration for that network. The
endpoint configuration can be left empty to connect to that network with no
particular endpoint configuration. See
L<API::Docker::Type::EndpointSettings>. B<The keys are the caller's data>
and are never translated.

=cut

1;
