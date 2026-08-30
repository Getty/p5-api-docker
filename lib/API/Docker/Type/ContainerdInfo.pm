package API::Docker::Type::ContainerdInfo;
# ABSTRACT: Information for connecting to the containerd instance that is used by the daemon
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ContainerdInfo::Namespaces;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerdInfo> definition of C<spec/v1.51.yaml>.

This is included for debugging purposes only.

=cut

docker address => Str, since => '1.51';

=attr address

The address of the containerd socket.

=cut

docker namespaces => 'ContainerdInfo::Namespaces', since => '1.51';

=attr namespaces

The namespaces that the daemon uses for running containers and plugins in
containerd. These namespaces can be configured in the daemon configuration,
and are considered to be used exclusively by the daemon, Tampering with the
containerd instance may cause unexpected behavior.

As these namespaces are considered to be exclusively accessed by the daemon,
it is not recommended to change these values, or to change them to a value
that is used by other systems, such as cri-containerd. See
L<API::Docker::Type::ContainerdInfo::Namespaces>.

=cut

1;
