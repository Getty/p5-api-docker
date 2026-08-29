package API::Docker::Type::Volume::UsageData;
# ABSTRACT: Usage details about the volume
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<UsageData> schema of the C<Volume> definition in
C<spec/v1.51.yaml>.

This information is used by the C<GET /system/df> endpoint, and omitted in
other endpoints.

=cut

docker size => Int;

=attr size

Amount of disk space used by the volume (in bytes). This information is only
available for volumes created with the C<"local"> volume driver. For volumes
created with other volume drivers, this field is set to C<-1> ("not
available"). The daemon defaults it to -1.

=cut

docker ref_count => Int;

=attr ref_count

The number of containers referencing this volume. This field is set to C<-1>
if the reference-count is not available. The daemon defaults it to -1.

=cut

1;
