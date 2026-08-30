package API::Docker::Type::ContainerdInfo::Namespaces;
# ABSTRACT: The namespaces that the daemon uses for running containers and plugins in containerd
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Namespaces> schema of the C<ContainerdInfo>
definition in C<spec/v1.51.yaml>.

These namespaces can be configured in the daemon configuration, and are
considered to be used exclusively by the daemon, Tampering with the
containerd instance may cause unexpected behavior.

As these namespaces are considered to be exclusively accessed by the daemon,
it is not recommended to change these values, or to change them to a value
that is used by other systems, such as cri-containerd.

=cut

docker containers => Str, since => '1.51';

=attr containers

The default containerd namespace used for containers managed by the daemon.

The default namespace for containers is "moby", but will be suffixed with
the C<< <uid>.<gid> >> of the remapped C<root> if user-namespaces are
enabled and the containerd image-store is used.

=cut

docker plugins => Str, since => '1.51';

=attr plugins

The default containerd namespace used for plugins managed by the daemon.

The default namespace for plugins is "plugins.moby", but will be suffixed
with the C<< <uid>.<gid> >> of the remapped C<root> if user-namespaces are
enabled and the containerd image-store is used.

=cut

1;
