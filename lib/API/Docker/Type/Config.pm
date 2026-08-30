package API::Docker::Type::Config;
# ABSTRACT: One entry of the C<200> response to C<GET /configs>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::ConfigSpec;
use API::Docker::Type::ObjectVersion;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Config> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /configs> and the body of the C<200> response to
C<GET /configs/{id}>. The same four fields and the same C<Version> a secret
carries, and the swagger gives an example for none of them;
L<API::Docker::Type::Secret> is where the shapes are written down.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. The config's ID, as L<API::Docker::Type::Secret/id>
is a secret's. Serialised as C<ID> -- spelled out, because deriving it from
the Perl name would produce C<Id>.

=cut

docker version => 'ObjectVersion';

=attr version

The version number of the object such as node, service, etc. See
L<API::Docker::Type::ObjectVersion>.

=cut

docker created_at => Str;

=attr created_at

Undocumented upstream. RFC 3339, as L<API::Docker::Type::Secret/created_at>
is.

=cut

docker updated_at => Str;

=attr updated_at

Undocumented upstream. The same format as L</created_at>.

=cut

docker spec => 'ConfigSpec';

=attr spec

Undocumented upstream. The config's name, labels, templating and -- unlike a
secret's -- its actual data, which the daemon does hand back.
L<API::Docker::Role::Entity::Config/decoded_data> is the accessor that
base64-decodes it. See L<API::Docker::Type::ConfigSpec>.

=cut

1;
