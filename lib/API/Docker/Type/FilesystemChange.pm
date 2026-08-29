package API::Docker::Type::FilesystemChange;
# ABSTRACT: Change in the container's filesystem
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<FilesystemChange> definition of C<spec/v1.51.yaml>.

=cut

docker path => Str, since => '1.44', required => 1;

=attr path

Path to file or directory that has changed. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker kind => Int, since => '1.44', required => 1, enum => [qw( 0 1 2 )];

=attr kind

Kind of change

Can be one of:

=over 4

=item * C<0>: Modified ("C")

=item * C<1>: Added ("A")

=item * C<2>: Deleted ("D")

=back

The swagger lists this field as required; nothing here enforces that, see
L<API::Docker::Type/C<since> is documentation>.

=cut

1;
