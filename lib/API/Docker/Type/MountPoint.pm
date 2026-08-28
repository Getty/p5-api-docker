package API::Docker::Type::MountPoint;
# ABSTRACT: A mount point configuration inside the container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<MountPoint> definition of C<spec/v1.51.yaml>.

This is used for reporting the mountpoints in use by a container.

=cut

docker type => Str, enum => [qw( bind cluster image npipe tmpfs volume )];

=attr type

The mount type:

=over 4

=item * C<bind> a mount of a file or directory from the host into the
container.

=item * C<cluster> a Swarm cluster volume.

=item * C<image> an OCI image.

=item * C<npipe> a named pipe from the host into the container.

=item * C<tmpfs> a C<tmpfs>.

=item * C<volume> a docker volume with the given C<Name>.

=back

The swagger types this field as an C<allOf> around a single C<$ref> to
C<MountType>, which is a string and not an object, so it is a plain Str
here.

=cut

docker name => Str;

=attr name

Name is the name reference to the underlying data defined by C<Source> e.g.,
the volume name.

=cut

docker source => Str;

=attr source

Source location of the mount.

For volumes, this contains the storage location of the volume (within
C</var/lib/docker/volumes/>). For bind-mounts, and C<npipe>, this contains
the source (host) part of the bind-mount. For C<tmpfs> mount points, this
field is empty.

=cut

docker destination => Str;

=attr destination

Destination is the path relative to the container root (C</>) where the
C<Source> is mounted inside the container.

=cut

docker driver => Str;

=attr driver

Driver is the volume driver used to create the volume (if it is a volume).

=cut

docker mode => Str;

=attr mode

Mode is a comma separated list of options supplied by the user when creating
the bind/volume mount.

The default is platform-specific (C<"z"> on Linux, empty on Windows).

=cut

docker rw => Bool, wire => 'RW';

=attr rw

Whether the mount is mounted writable (read-write). Serialised as C<RW> --
spelled out, because deriving it from the Perl name would produce C<Rw>.

=cut

docker propagation => Str;

=attr propagation

Propagation describes how mounts are propagated from the host into the mount
point, and vice-versa. Refer to the L<Linux kernel
documentation|https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt>
for details. This field is not used on Windows.

=cut

1;
