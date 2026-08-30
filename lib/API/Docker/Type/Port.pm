package API::Docker::Type::Port;
# ABSTRACT: An open port on a container
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Port> definition of C<spec/v1.51.yaml>. One entry of
the C<Ports> array a container list answers with.

=cut

docker ip => Str, wire => 'IP';

=attr ip

Host IP address that the container's port is mapped to. Serialised as C<IP>
-- spelled out, because deriving it from the Perl name would produce C<Ip>.

=cut

docker private_port => Int, required => 1;

=attr private_port

Port on the container. A C<uint16>. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker public_port => Int;

=attr public_port

Port exposed on the host. A C<uint16>.

=cut

docker type => Str, required => 1, enum => [qw( tcp udp sctp )];

=attr type

Undocumented upstream. The protocol the port speaks, C<tcp> in the swagger's
example for this object. The swagger enumerates C<tcp>, C<udp> and C<sctp>.
The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
