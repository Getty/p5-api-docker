package API::Docker::Type::Mount::BindOptions;
# ABSTRACT: Optional configuration for a bind mount
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<BindOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>. Upstream it has no name of its own -- it is an object
written straight into C<Mount>, and the class is named after the definition
that declares it.

=cut

docker propagation => Str,
  enum => [qw( private rprivate shared rshared slave rslave )];

=attr propagation

A propagation mode with the value C<[r]private>, C<[r]shared> or
C<[r]slave>.

=cut

docker non_recursive => Bool;

=attr non_recursive

Disable recursive bind mount. Defaults to false on the daemon side.

=cut

docker create_mountpoint => Bool, since => '1.44';

=attr create_mountpoint

Create the mount point on the host if it is missing. Defaults to false on
the daemon side.

=cut

docker read_only_non_recursive => Bool, since => '1.44';

=attr read_only_non_recursive

Make the mount non-recursively read-only, but still leave the mount
recursive -- unless C<non_recursive> is set to true as well.

Added in v1.44; before that version all read-only mounts were non-recursive
by default, and to match the earlier behaviour the daemon defaults this to
true for clients on versions prior to v1.44.

=cut

docker read_only_force_recursive => Bool, since => '1.44';

=attr read_only_force_recursive

Raise an error if the mount cannot be made recursively read-only. Defaults
to false on the daemon side.

=cut

1;
