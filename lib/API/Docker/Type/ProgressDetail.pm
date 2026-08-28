package API::Docker::Type::ProgressDetail;
# ABSTRACT: The value of C<BuildInfo.progressDetail>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ProgressDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.progressDetail>,
C<CreateImageInfo.progressDetail> and C<PushImageInfo.progressDetail>.

=cut

docker current => Int, wire => 'current';

=attr current

Undocumented upstream. Serialised as C<current> -- spelled out, because
deriving it from the Perl name would produce C<Current>.

=cut

docker total => Int, wire => 'total';

=attr total

Undocumented upstream. Serialised as C<total> -- spelled out, because
deriving it from the Perl name would produce C<Total>.

=cut

1;
