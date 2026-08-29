package API::Docker::Type::ClusterVolumeSpec::AccessMode::Secret;
# ABSTRACT: One cluster volume secret entry
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<ClusterVolumeSpec.AccessMode.Secrets> in C<spec/v1.51.yaml>.

Defines a key-value pair that is passed to the plugin.

=cut

docker key => Str, since => '1.44';

=attr key

Key is the name of the key of the key-value pair passed to the plugin.

=cut

docker secret => Str, since => '1.44';

=attr secret

Secret is the swarm Secret object from which to read data. This can be a
Secret name or ID. The Secret data is retrieved by swarm and used as the
value of the key-value pair passed to the plugin.

=cut

1;
