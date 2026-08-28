package API::Docker::Type::VolumeCreateOptions;
# ABSTRACT: Volume configuration
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ClusterVolumeSpec;

=head1 DESCRIPTION

Generated from the C<VolumeCreateOptions> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

The new volume's name. If not specified, Docker generates a name.

=cut

docker driver => Str;

=attr driver

Name of the volume driver to use. The daemon defaults it to local.

=cut

docker driver_opts => { Str, Str };

=attr driver_opts

A mapping of driver options and values. These options are passed directly to
the driver and are driver specific. B<The keys are the caller's data> and
are never translated.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker cluster_volume_spec => 'ClusterVolumeSpec', since => '1.44';

=attr cluster_volume_spec

Cluster-specific options used to create the volume. See
L<API::Docker::Type::ClusterVolumeSpec>.

=cut

1;
