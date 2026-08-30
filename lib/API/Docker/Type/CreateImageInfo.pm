package API::Docker::Type::CreateImageInfo;
# ABSTRACT: One event of the stream a C<POST /images/create> answers with
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ErrorDetail;
use API::Docker::Type::ProgressDetail;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<CreateImageInfo> definition of C<spec/v1.51.yaml>,
which the swagger leaves undescribed. The pull progress stream: C<POST
/images/create> answers C<200> and then writes one of these objects per
line. Like a build, a failed pull is still C<200> and reports itself through
C<errorDetail>.

=cut

docker id => Str, wire => 'id';

=attr id

Undocumented upstream. Which layer the event is about: a short image ID,
repeated across every event for that layer.
F<t/fixtures/images_pull_stream.ndjson> carries C<55afa1ecc21d> once and
C<d529dd0c6e55> on three consecutive events. Serialised as C<id> -- spelled
out, because deriving it from the Perl name would produce C<Id>.

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

Undocumented upstream. The failure, structured; the C<error> field beside it
carries the same text and the swagger deprecates it in favour of this one. A
failed pull is still C<200>, so this is the verdict -- see
L<API::Docker::Error::Stream>. See L<API::Docker::Type::ErrorDetail>.
Serialised as C<errorDetail> -- spelled out, because deriving it from the
Perl name would produce C<ErrorDetail>.

=cut

docker status => Str, wire => 'status';

=attr status

Undocumented upstream. The phase the layer named by L</id> has reached, as
text. The captured pull in F<t/fixtures/images_pull_stream.ndjson> carries
C<"Already exists">, C<"Pulling fs layer"> and C<"Download complete">.
Serialised as C<status> -- spelled out, because deriving it from the Perl
name would produce C<Status>.

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

Undocumented upstream. The numbers behind L</progress>, which the swagger
describes as a pre-formatted presentation of this field. Empty in all four
events of F<t/fixtures/images_pull_stream.ndjson>, which had nothing left to
transfer. See L<API::Docker::Type::ProgressDetail>. Serialised as
C<progressDetail> -- spelled out, because deriving it from the Perl name
would produce C<ProgressDetail>.

=cut

1;
