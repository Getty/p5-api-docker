package API::Docker::Type::Volume;
# ABSTRACT: The body of the C<200> response to C<GET /volumes/{name}>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ClusterVolume;
use API::Docker::Type::Volume::UsageData;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Volume> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of the
C<200> response to C<GET /volumes/{name}>, the body of the C<201> response
to C<POST /volumes/create> and one entry of the C<Volumes> field of the
C<200> response to C<GET /system/df>.

=cut

docker name => Str, required => 1;

=attr name

Name of the volume. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker driver => Str, required => 1;

=attr driver

Name of the volume driver used by the volume. The swagger lists this field
as required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker mountpoint => Str, required => 1;

=attr mountpoint

Mount path of the volume on the host. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker created_at => Str;

=attr created_at

Date/Time the volume was created.

=cut

docker status => { Str, Any };

=attr status

Low-level details about the volume, provided by the volume driver. Details
are returned as a map with key/value pairs:
C<{"key":"value","key2":"value2"}>.

The C<Status> field is optional, and is omitted if the volume driver does
not support this feature. B<The keys are the caller's data> and are never
translated.

=cut

docker labels => { Str, Str }, required => 1;

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker scope => Str, required => 1, enum => [qw( local global )];

=attr scope

The level at which the volume exists. Either C<global> for cluster-wide, or
C<local> for machine level. The daemon defaults it to local. The swagger
lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

docker cluster_volume => 'ClusterVolume', since => '1.44';

=attr cluster_volume

Options and information specific to, and only present on, Swarm CSI cluster
volumes. See L<API::Docker::Type::ClusterVolume>.

=cut

docker options => { Str, Str }, required => 1;

=attr options

The driver specific options used when creating the volume. B<The keys are
the caller's data> and are never translated. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker usage_data => 'Volume::UsageData';

=attr usage_data

Usage details about the volume. This information is used by the C<GET
/system/df> endpoint, and omitted in other endpoints. See
L<API::Docker::Type::Volume::UsageData>.

=cut

1;
