package API::Docker::Type::Mount::VolumeOptions::DriverConfig;
# ABSTRACT: The volume driver a mount's volume is to be created with
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<DriverConfig> schema of C<Mount.VolumeOptions>
in C<spec/v1.51.yaml>. where its description reads "Map of driver specific
options" -- which describes L</options>, not the object, whose two fields
are a driver name and that map.

=cut

docker name => Str;

=attr name

Name of the driver to use to create the volume.

=cut

docker options => { Str, Str };

=attr options

Key/value map of driver specific options. B<The keys are the caller's data>
and are never translated.

=cut

1;
