package API::Docker::Type::Mount::TmpfsOptions;
# ABSTRACT: Optional configuration for the C<tmpfs> type
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<TmpfsOptions> schema of the C<Mount> definition
in C<spec/v1.51.yaml>.

=cut

docker size_bytes => Int;

=attr size_bytes

The size for the tmpfs mount in bytes.

=cut

docker mode => Int;

=attr mode

The permission mode for the tmpfs mount in an integer. The value must not be
in octal format (e.g. 755) but rather the decimal representation of the
octal value (e.g. 493).

=cut

docker options => [[Str]], since => '1.51';

=attr options

The options to be passed to the tmpfs mount. An array of arrays. Flag
options should be provided as 1-length arrays. Other types should be
provided as as 2-length arrays, where the first item is the key and the
second the value. For example: C<< [["noexec"], ["size", "64m"]] >>.

=cut

1;
