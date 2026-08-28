package API::Docker::Type::Mount::VolumeOptions;
# ABSTRACT: Optional configuration for a volume mount
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Mount::VolumeOptions::DriverConfig;

=head1 DESCRIPTION

Generated from the inline C<VolumeOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>.

=cut

docker no_copy => Bool;

=attr no_copy

Populate the volume with data from the target. Defaults to false on the
daemon side.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated: a label named C<com.example.Some-Label> reaches the daemon
spelled exactly that way.

=cut

docker driver_config => 'Mount::VolumeOptions::DriverConfig';

=attr driver_config

The volume driver to create the volume with, and its options. See
L<API::Docker::Type::Mount::VolumeOptions::DriverConfig>.

=cut

docker subpath => Str, since => '1.51';

=attr subpath

Source path inside the volume. Must be relative, without any back
traversals.

=cut

1;
