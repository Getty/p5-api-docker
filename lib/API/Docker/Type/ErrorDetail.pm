package API::Docker::Type::ErrorDetail;
# ABSTRACT: The value of C<BuildInfo.errorDetail>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ErrorDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.errorDetail>, C<CreateImageInfo.errorDetail> and
C<PushImageInfo.errorDetail>. It is what a build, pull or push stream
reports a failure through, and what L<API::Docker::Error::Stream> is croaked
on; neither of its two fields is described either.

=cut

docker code => Int, wire => 'code';

=attr code

Undocumented upstream. An integer. No captured stream under F<t/fixtures/>
carries one -- the C<errorDetail> of
F<t/fixtures/images_build_error_stream.ndjson> has L</message> and nothing
else. Serialised as C<code> -- spelled out, because deriving it from the
Perl name would produce C<Code>.

=cut

docker message => Str, wire => 'message';

=attr message

Undocumented upstream. The reason, as text. It ends in a newline in
F<t/fixtures/images_build_error_stream.ndjson>, which is why
L<API::Docker::Error::Stream/message> strips trailing whitespace before Carp
sees it. Serialised as C<message> -- spelled out, because deriving it from
the Perl name would produce C<Message>.

=cut

1;
