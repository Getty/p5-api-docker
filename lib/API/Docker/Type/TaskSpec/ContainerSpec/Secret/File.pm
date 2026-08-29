package API::Docker::Type::TaskSpec::ContainerSpec::Secret::File;
# ABSTRACT: A specific target that is backed by a file
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<File> schema of
C<TaskSpec.ContainerSpec.Secrets> in C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

Name represents the final filename in the filesystem.

=cut

docker uid => Str, wire => 'UID';

=attr uid

UID represents the file UID. Serialised as C<UID> -- spelled out, because
deriving it from the Perl name would produce C<Uid>.

=cut

docker gid => Str, wire => 'GID';

=attr gid

GID represents the file GID. Serialised as C<GID> -- spelled out, because
deriving it from the Perl name would produce C<Gid>.

=cut

docker mode => Int;

=attr mode

Mode represents the FileMode of the file.

=cut

1;
