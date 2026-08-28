package API::Docker::Type::PushImageInfo;
# ABSTRACT: One event of the stream a C<POST /images/{name}/push> answers with
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ErrorDetail;
use API::Docker::Type::ProgressDetail;

=head1 DESCRIPTION

Generated from the C<PushImageInfo> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. The push progress stream, the same shape as
a pull's. A failed push is C<200> with an C<errorDetail> event, so the
status line is not the verdict.

=cut

docker error => Str, wire => 'error';

=attr error

Errors encountered during the operation.

> B<Deprecated>: This field is deprecated since API v1.4, and will be
omitted in a future API version. Use the information in errorDetail instead.
Serialised as C<error> -- spelled out, because deriving it from the Perl
name would produce C<Error>.

=cut

docker error_detail => 'ErrorDetail', wire => 'errorDetail', since => '1.51';

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

1;
