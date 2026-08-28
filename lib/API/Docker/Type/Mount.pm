package API::Docker::Type::Mount;
# ABSTRACT: One entry of a container's Mounts specification
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Mount::BindOptions;
use API::Docker::Type::Mount::ImageOptions;
use API::Docker::Type::Mount::TmpfsOptions;
use API::Docker::Type::Mount::VolumeOptions;

=head1 DESCRIPTION

Generated from the C<Mount> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<HostConfig.Mounts> and C<TaskSpec.ContainerSpec.Mounts>.

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

Mount source (e.g. a volume name, a host path). The source cannot be
specified when using C<Type=tmpfs>. For C<Type=bind>, the source path must
either exist, or the C<CreateMountpoint> must be set to C<true> to create
the source path on the host if missing.

For C<Type=npipe>, the pipe must exist prior to creating the container.

=cut

docker type => Str, enum => [qw( bind cluster image npipe tmpfs volume )];

=attr type

The mount type. Available types:

=over 4

=item * C<bind> Mounts a file or directory from the host into the container.
The C<Source> must exist prior to creating the container.

=item * C<cluster> a Swarm cluster volume

=item * C<image> Mounts an image.

=item * C<npipe> Mounts a named pipe from the host into the container. The
C<Source> must exist prior to creating the container.

=item * C<tmpfs> Create a tmpfs with the given options. The mount C<Source>
cannot be specified for tmpfs.

=item * C<volume> Creates a volume with the given name and options (or uses
a pre-existing volume with the same name and options). These are B<not>
removed when the container is removed.

=back

The swagger types this field as an C<allOf> around a single C<$ref> to
C<MountType>, which is a string and not an object, so it is a plain Str
here.

=cut

docker read_only => Bool;

=attr read_only

Whether the mount should be read-only.

=cut

docker consistency => Str;

=attr consistency

The consistency requirement for the mount: C<default>, C<consistent>,
C<cached>, or C<delegated>.

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
