package API::Docker::Type::ContainerBlkioStatEntry;
# ABSTRACT: Blkio stats entry
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerBlkioStatEntry> definition of
C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=cut

docker major => Int, wire => 'major', since => '1.51';

=attr major

Undocumented upstream. With L</minor>, the pair identifying the block device
the entry counts for. The example L<API::Docker::Type::ContainerBlkioStats>
gives for a whole object holds two entries under
C<io_service_bytes_recursive>, one read and one write, and both carry C<254>
here. Serialised as C<major> -- spelled out, because deriving it from the
Perl name would produce C<Major>.

=cut

docker minor => Int, wire => 'minor', since => '1.51';

=attr minor

Undocumented upstream. The other half of that pair, C<0> on both of those
entries. Serialised as C<minor> -- spelled out, because deriving it from the
Perl name would produce C<Minor>.

=cut

docker op => Str, wire => 'op', since => '1.51';

=attr op

Undocumented upstream. The operation counted, C<"read"> on one of those two
entries and C<"write"> on the other. The type holding them describes itself
as storing all IO service stats for data read and write. Serialised as C<op>
-- spelled out, because deriving it from the Perl name would produce C<Op>.

=cut

docker value => Int, wire => 'value', since => '1.51';

=attr value

Undocumented upstream. The count itself. What it counts depends on which of
the eight arrays of L<API::Docker::Type::ContainerBlkioStats> the entry sits
in; under C<io_service_bytes_recursive> it is bytes, C<7593984> on the read
entry of that object's example and C<100> on the write one. Serialised as
C<value> -- spelled out, because deriving it from the Perl name would
produce C<Value>.

=cut

1;
