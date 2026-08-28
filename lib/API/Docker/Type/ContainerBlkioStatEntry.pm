package API::Docker::Type::ContainerBlkioStatEntry;
# ABSTRACT: Blkio stats entry
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ContainerBlkioStatEntry> definition of
C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=cut

docker major => Int, wire => 'major', since => '1.51';

=attr major

Undocumented upstream. Serialised as C<major> -- spelled out, because
deriving it from the Perl name would produce C<Major>.

=cut

docker minor => Int, wire => 'minor', since => '1.51';

=attr minor

Undocumented upstream. Serialised as C<minor> -- spelled out, because
deriving it from the Perl name would produce C<Minor>.

=cut

docker op => Str, wire => 'op', since => '1.51';

=attr op

Undocumented upstream. Serialised as C<op> -- spelled out, because deriving
it from the Perl name would produce C<Op>.

=cut

docker value => Int, wire => 'value', since => '1.51';

=attr value

Undocumented upstream. Serialised as C<value> -- spelled out, because
deriving it from the Perl name would produce C<Value>.

=cut

1;
