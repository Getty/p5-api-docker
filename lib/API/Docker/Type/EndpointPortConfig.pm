package API::Docker::Type::EndpointPortConfig;
# ABSTRACT: One entry of C<EndpointSpec.Ports>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<EndpointPortConfig> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. Nothing in C<paths:> reaches it
either; it is one entry of C<EndpointSpec.Ports>, C<PortStatus.Ports> and
C<Service.Endpoint.Ports>.

=cut

docker name => Str;

=attr name

Undocumented upstream.

=cut

docker protocol => Str, enum => [qw( tcp udp sctp )];

=attr protocol

Undocumented upstream. The transport protocol of the published port, C<tcp>
in the swagger's C<Service> example. The same enumeration appears on a
container's own port list as L<API::Docker::Type::Port/type>. The swagger
enumerates C<tcp>, C<udp> and C<sctp>.

=cut

docker target_port => Int;

=attr target_port

The port inside the container.

=cut

docker published_port => Int;

=attr published_port

The port on the swarm hosts.

=cut

docker publish_mode => Str, enum => [qw( ingress host )];

=attr publish_mode

The mode in which port is published.

=over 4

=item * "ingress" makes the target port accessible on every node, regardless
of whether there is a task for the service running on that node or not.

=item * "host" bypasses the routing mesh and publish the port directly on
the swarm node where that service is running.

=back

The daemon defaults it to ingress.

=cut

1;
