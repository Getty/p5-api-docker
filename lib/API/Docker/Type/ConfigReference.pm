package API::Docker::Type::ConfigReference;
# ABSTRACT: The config-only network source to provide the configuration for this network
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ConfigReference> definition of C<spec/v1.51.yaml>.

=cut

docker network => Str;

=attr network

The name of the config-only network that provides the network's
configuration. The specified network must be an existing config-only
network. Only network names are allowed, not network IDs.

=cut

1;
