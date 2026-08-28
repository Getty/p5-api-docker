package API::Docker::Type::DeviceRequest;
# ABSTRACT: A request for devices to be sent to device drivers
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<DeviceRequest> definition of C<spec/v1.51.yaml>.

=cut

docker driver => Str;

=attr driver

Undocumented upstream; C<"nvidia"> in the swagger's example.

=cut

docker count => Int;

=attr count

Undocumented upstream; C<-1> in the swagger's example.

=cut

docker device_ids => [Str], wire => 'DeviceIDs';

=attr device_ids

Undocumented upstream. The swagger's example is C<< ["0", "1",
"GPU-fef8089b-4820-abfc-e83e-94318197576e"] >>. Serialised as C<DeviceIDs>
-- spelled out, because deriving it from the Perl name would produce
C<DeviceIds>.

=cut

docker capabilities => [[Str]];

=attr capabilities

A list of capabilities; an OR list of AND lists of capabilities, so an
ArrayRef of ArrayRefs of strings. C<< [["gpu", "nvidia", "compute"]] >>
asks for a device that has all three.

=cut

docker options => { Str, Str };

=attr options

Driver-specific options as key/value pairs, passed straight to the driver.
B<The keys are the caller's data> and are never translated.

=cut

1;
