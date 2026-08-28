package API::Docker::Type::Mount::TmpfsOptions;
# ABSTRACT: Optional configuration for a tmpfs mount
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

The permission mode for the tmpfs mount, as an integer. The value must not
be in octal format (755) but the decimal representation of the octal value
(493).

=cut

docker options => [[Str]], since => '1.51';

=attr options

The options to be passed to the tmpfs mount: an array of arrays. Flag
options are 1-length arrays; everything else is a 2-length array whose first
item is the key and second the value -- C<< [["noexec"], ["size", "64m"]] >>.

=cut

1;
