package API::Docker::Type::ProgressDetail;
# ABSTRACT: The value of C<BuildInfo.progressDetail>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ProgressDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.progressDetail>,
C<CreateImageInfo.progressDetail> and C<PushImageInfo.progressDetail>. The
two numbers behind the C<progress> field of a build, pull or push event,
which the swagger describes as "a pre-formatted presentation of
progressDetail".

=cut

docker current => Int, wire => 'current';

=attr current

Undocumented upstream. How much is done. Absent from every event of
F<t/fixtures/images_pull_stream.ndjson>, where C<progressDetail> is an empty
object throughout. Serialised as C<current> -- spelled out, because deriving
it from the Perl name would produce C<Current>.

=cut

docker total => Int, wire => 'total';

=attr total

Undocumented upstream. How much there is to do, the other half of
L</current>. Serialised as C<total> -- spelled out, because deriving it from
the Perl name would produce C<Total>.

=cut

1;
