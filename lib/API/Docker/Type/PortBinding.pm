package API::Docker::Type::PortBinding;
# ABSTRACT: A binding between a host IP address and a host port
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<PortBinding> definition of C<spec/v1.51.yaml>. These
are the values of a C<PortMap>, whose keys -- C<"80/tcp"> and the like --
are the caller's data and are never translated; see
L<API::Docker::Type::HostConfig/port_bindings>.

=cut

docker host_ip => Str;

=attr host_ip

Host IP address that the container's port is mapped to. The swagger's
example is C<127.0.0.1>.

=cut

docker host_port => Str;

=attr host_port

Host port number that the container's port is mapped to. The swagger's
example is C<"4443">. A string on the wire, not a number.

=cut

1;
