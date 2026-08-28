package API::Docker::Type::Commit;
# ABSTRACT: Commit holds the Git-commit (SHA1) that a binary was built from, as reported in the version-string of external tools, such as C<containerd>, or C<runC>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<Commit> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID';

=attr id

Actual commit ID of external tool. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=cut

1;
