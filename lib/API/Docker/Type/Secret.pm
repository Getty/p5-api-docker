package API::Docker::Type::Secret;
# ABSTRACT: One entry of the C<200> response to C<GET /secrets>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ObjectVersion;
use API::Docker::Type::SecretSpec;

=head1 DESCRIPTION

Generated from the C<Secret> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /secrets> and the body of the C<200> response to
C<GET /secrets/{id}>.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. Serialised as C<ID> -- spelled out, because deriving
it from the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Undocumented upstream.

=cut

docker updated_at => Str;

=attr updated_at

Undocumented upstream.

=cut

docker spec => 'SecretSpec';

=attr spec

Undocumented upstream. See L<API::Docker::Type::SecretSpec>.

=cut

1;
