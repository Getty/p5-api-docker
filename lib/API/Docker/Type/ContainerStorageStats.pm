package API::Docker::Type::ContainerStorageStats;
# ABSTRACT: StorageStats is the disk I/O stats for read/write on Windows
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerStorageStats> definition of
C<spec/v1.51.yaml>.

This type is Windows-specific and omitted for Linux containers. None of its
four fields is described. They are two counts and two byte totals, one pair
per direction, every one of them nullable and every one of them given
C<7593984> as its example.

=cut

docker read_count_normalized => Int,
  wire => 'read_count_normalized', since => '1.51';

=attr read_count_normalized

Undocumented upstream. The count of the read pair, beside the byte total in
L</read_size_bytes>. Serialised as C<read_count_normalized> -- spelled out,
because deriving it from the Perl name would produce C<ReadCountNormalized>.

=cut

docker read_size_bytes => Int, wire => 'read_size_bytes', since => '1.51';

=attr read_size_bytes

Undocumented upstream. The bytes read, the other half of that pair.
Serialised as C<read_size_bytes> -- spelled out, because deriving it from
the Perl name would produce C<ReadSizeBytes>.

=cut

docker write_count_normalized => Int,
  wire => 'write_count_normalized', since => '1.51';

=attr write_count_normalized

Undocumented upstream. The write counterpart of L</read_count_normalized>.
Serialised as C<write_count_normalized> -- spelled out, because deriving it
from the Perl name would produce C<WriteCountNormalized>.

=cut

docker write_size_bytes => Int, wire => 'write_size_bytes', since => '1.51';

=attr write_size_bytes

Undocumented upstream. The write counterpart of L</read_size_bytes>.
Serialised as C<write_size_bytes> -- spelled out, because deriving it from
the Perl name would produce C<WriteSizeBytes>.

=cut

1;
