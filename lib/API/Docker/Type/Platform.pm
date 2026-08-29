package API::Docker::Type::Platform;
# ABSTRACT: The platform (Arch/OS)
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Platform> definition of C<spec/v1.51.yaml>.

=cut

docker architecture => Str;

=attr architecture

Architecture represents the hardware architecture (for example, C<x86_64>).

=cut

docker os => Str, wire => 'OS';

=attr os

OS represents the Operating System (for example, C<linux> or C<windows>).
Serialised as C<OS> -- spelled out, because deriving it from the Perl name
would produce C<Os>.

=cut

1;
