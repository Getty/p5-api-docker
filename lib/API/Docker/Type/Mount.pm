package API::Docker::Type::Mount;
# ABSTRACT: One entry of a container's Mounts specification
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Mount::BindOptions;
use API::Docker::Type::Mount::ImageOptions;
use API::Docker::Type::Mount::TmpfsOptions;
use API::Docker::Type::Mount::VolumeOptions;

=head1 DESCRIPTION

Generated from the C<Mount> definition of C<spec/v1.51.yaml>, which gives
the definition itself no description. It is the element type of
L<API::Docker::Type::HostConfig/mounts>.

The four C<*Options> fields are objects the swagger writes inline rather
than referencing, so each becomes a class named after this one:
L<API::Docker::Type::Mount::BindOptions>,
L<API::Docker::Type::Mount::VolumeOptions>,
L<API::Docker::Type::Mount::ImageOptions> and
L<API::Docker::Type::Mount::TmpfsOptions>.

=cut

docker target => Str;

=attr target

Container path.

=cut

docker source => Str;

=attr source

Mount source: a volume name, a host path. The source cannot be specified
when using C<Type=tmpfs>. For C<Type=bind> the source path must either
exist, or C<create_mountpoint> must be set on L</bind_options> so the daemon
creates it on the host. For C<Type=npipe> the pipe must exist before the
container is created.

=cut

docker type => Str,
  enum => [qw( bind cluster image npipe tmpfs volume )];

=attr type

The mount type. In the swagger this field is an C<allOf> around a single
C<$ref> to C<MountType>, which is swagger's way of hanging a description on
a reference; C<MountType> is a string with six values, so this is a plain
string here and not an object reference.

=over 4

=item * C<bind> mounts a file or directory from the host into the
container. The source must exist before the container is created.

=item * C<cluster> a Swarm cluster volume.

=item * C<image> mounts an image.

=item * C<npipe> mounts a named pipe from the host into the container. The
source must exist before the container is created.

=item * C<tmpfs> creates a tmpfs with the given options. The source cannot
be specified.

=item * C<volume> creates a volume with the given name and options, or uses
a pre-existing volume with the same name and options. These are B<not>
removed when the container is removed.

=back

=cut

docker read_only => Bool;

=attr read_only

Whether the mount should be read-only.

=cut

docker consistency => Str;

=attr consistency

The consistency requirement for the mount: C<default>, C<consistent>,
C<cached> or C<delegated>.

=cut

docker bind_options => 'Mount::BindOptions';

=attr bind_options

Optional configuration for the C<bind> type. See
L<API::Docker::Type::Mount::BindOptions>.

=cut

docker volume_options => 'Mount::VolumeOptions';

=attr volume_options

Optional configuration for the C<volume> type. See
L<API::Docker::Type::Mount::VolumeOptions>.

=cut

docker image_options => 'Mount::ImageOptions', since => '1.51';

=attr image_options

Optional configuration for the C<image> type. See
L<API::Docker::Type::Mount::ImageOptions>.

=cut

docker tmpfs_options => 'Mount::TmpfsOptions';

=attr tmpfs_options

Optional configuration for the C<tmpfs> type. See
L<API::Docker::Type::Mount::TmpfsOptions>.

=cut

1;
