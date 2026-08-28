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

Undocumented upstream. The secret's ID. The swagger's example is a
25-character Swarm ID, C<blt1owaxmitz71s9v5zh81zun>; the C<GET /secrets>
capture in F<t/fixtures/secrets_list.json>, from Podman 5.4.2 (API 1.41),
answers 25 hex characters instead. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Undocumented upstream. RFC 3339 with nanoseconds,
C<2017-07-20T13:55:28.678958722Z> in the swagger's example.

=cut

docker updated_at => Str;

=attr updated_at

Undocumented upstream. The same format as L</created_at>, and identical to
it on a secret that has never been updated -- both captured secrets in
F<t/fixtures/secrets_list.json> carry the same instant in both fields.

=cut

docker spec => 'SecretSpec';

=attr spec

Undocumented upstream. The secret's name, driver and labels. Not its value:
the daemon hands that to containers and never back over C</secrets>, so C<<
$secret->spec->data >> reads C<undef> on anything an engine sent;
L<API::Docker::Role::Entity::Secret> says why. See
L<API::Docker::Type::SecretSpec>.

=cut

1;
