package API::Docker::Type::ContainerNetworkStats;
# ABSTRACT: Aggregates the network stats of one container
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerNetworkStats> definition of
C<spec/v1.51.yaml>.

=cut

docker rx_bytes => Int, wire => 'rx_bytes', since => '1.51';

=attr rx_bytes

Bytes received. Windows and Linux. Serialised as C<rx_bytes> -- spelled out,
because deriving it from the Perl name would produce C<RxBytes>.

=cut

docker rx_packets => Int, wire => 'rx_packets', since => '1.51';

=attr rx_packets

Packets received. Windows and Linux. Serialised as C<rx_packets> -- spelled
out, because deriving it from the Perl name would produce C<RxPackets>.

=cut

docker rx_errors => Int, wire => 'rx_errors', since => '1.51';

=attr rx_errors

Received errors. Not used on Windows.

This field is Linux-specific and always zero for Windows containers.
Serialised as C<rx_errors> -- spelled out, because deriving it from the Perl
name would produce C<RxErrors>.

=cut

docker rx_dropped => Int, wire => 'rx_dropped', since => '1.51';

=attr rx_dropped

Incoming packets dropped. Windows and Linux. Serialised as C<rx_dropped> --
spelled out, because deriving it from the Perl name would produce
C<RxDropped>.

=cut

docker tx_bytes => Int, wire => 'tx_bytes', since => '1.51';

=attr tx_bytes

Bytes sent. Windows and Linux. Serialised as C<tx_bytes> -- spelled out,
because deriving it from the Perl name would produce C<TxBytes>.

=cut

docker tx_packets => Int, wire => 'tx_packets', since => '1.51';

=attr tx_packets

Packets sent. Windows and Linux. Serialised as C<tx_packets> -- spelled out,
because deriving it from the Perl name would produce C<TxPackets>.

=cut

docker tx_errors => Int, wire => 'tx_errors', since => '1.51';

=attr tx_errors

Sent errors. Not used on Windows.

This field is Linux-specific and always zero for Windows containers.
Serialised as C<tx_errors> -- spelled out, because deriving it from the Perl
name would produce C<TxErrors>.

=cut

docker tx_dropped => Int, wire => 'tx_dropped', since => '1.51';

=attr tx_dropped

Outgoing packets dropped. Windows and Linux. Serialised as C<tx_dropped> --
spelled out, because deriving it from the Perl name would produce
C<TxDropped>.

=cut

docker endpoint_id => Str, wire => 'endpoint_id', since => '1.51';

=attr endpoint_id

Endpoint ID. Not used on Linux.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<endpoint_id> -- spelled out, because deriving it from the Perl name
would produce C<EndpointId>.

=cut

docker instance_id => Str, wire => 'instance_id', since => '1.51';

=attr instance_id

Instance ID. Not used on Linux.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<instance_id> -- spelled out, because deriving it from the Perl name
would produce C<InstanceId>.

=cut

1;
