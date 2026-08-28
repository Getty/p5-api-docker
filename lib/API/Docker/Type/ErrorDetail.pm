package API::Docker::Type::ErrorDetail;
# ABSTRACT: The value of C<BuildInfo.errorDetail>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ErrorDetail> definition of C<spec/v1.51.yaml>, which
the swagger leaves undescribed. Nothing in C<paths:> reaches it either; it
is the value of C<BuildInfo.errorDetail>, C<CreateImageInfo.errorDetail> and
C<PushImageInfo.errorDetail>.

=cut

docker code => Int, wire => 'code';

=attr code

Undocumented upstream. Serialised as C<code> -- spelled out, because
deriving it from the Perl name would produce C<Code>.

=cut

docker message => Str, wire => 'message';

=attr message

Undocumented upstream. Serialised as C<message> -- spelled out, because
deriving it from the Perl name would produce C<Message>.

=cut

1;
