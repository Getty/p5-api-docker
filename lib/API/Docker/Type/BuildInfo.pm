package API::Docker::Type::BuildInfo;
# ABSTRACT: One event of the stream a C<POST /build> answers with
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ErrorDetail;
use API::Docker::Type::ImageID;
use API::Docker::Type::ProgressDetail;

=head1 DESCRIPTION

Generated from the C<BuildInfo> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing references it and no path names it as a
schema, because it is not a response body: C<POST /build> answers C<200> and
then writes one of these objects per line until the daemon closes the
connection. A failed build is still C<200>, and arrives as an event carrying
C<errorDetail>.

=cut

docker id => Str, wire => 'id';

=attr id

Undocumented upstream. Serialised as C<id> -- spelled out, because deriving
it from the Perl name would produce C<Id>.

=cut

docker stream => Str, wire => 'stream';

=attr stream

Undocumented upstream. Serialised as C<stream> -- spelled out, because
deriving it from the Perl name would produce C<Stream>.

=cut

docker error => Str, wire => 'error';

=attr error

Errors encountered during the operation.

> B<Deprecated>: This field is deprecated since API v1.4, and will be
omitted in a future API version. Use the information in errorDetail instead.
Serialised as C<error> -- spelled out, because deriving it from the Perl
name would produce C<Error>.

=cut

docker error_detail => 'ErrorDetail', wire => 'errorDetail';

=attr error_detail

Undocumented upstream. See L<API::Docker::Type::ErrorDetail>. Serialised as
C<errorDetail> -- spelled out, because deriving it from the Perl name would
produce C<ErrorDetail>.

=cut

docker status => Str, wire => 'status';

=attr status

Undocumented upstream. Serialised as C<status> -- spelled out, because
deriving it from the Perl name would produce C<Status>.

=cut

docker progress => Str, wire => 'progress';

=attr progress

Progress is a pre-formatted presentation of progressDetail.

> B<Deprecated>: This field is deprecated since API v1.8, and will be
omitted in a future API version. Use the information in progressDetail
instead. Serialised as C<progress> -- spelled out, because deriving it from
the Perl name would produce C<Progress>.

=cut

docker progress_detail => 'ProgressDetail', wire => 'progressDetail';

=attr progress_detail

Undocumented upstream. See L<API::Docker::Type::ProgressDetail>. Serialised
as C<progressDetail> -- spelled out, because deriving it from the Perl name
would produce C<ProgressDetail>.

=cut

docker aux => 'ImageID', wire => 'aux';

=attr aux

Image ID or Digest. See L<API::Docker::Type::ImageID>. Serialised as C<aux>
-- spelled out, because deriving it from the Perl name would produce C<Aux>.

=cut

1;
