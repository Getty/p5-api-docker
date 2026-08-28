package API::Docker::Type::Config;
# ABSTRACT: One entry of the C<200> response to C<GET /configs>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::ConfigSpec;
use API::Docker::Type::ObjectVersion;

=head1 DESCRIPTION

Generated from the C<Config> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: one entry of the
C<200> response to C<GET /configs> and the body of the C<200> response to
C<GET /configs/{id}>.

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

docker spec => 'ConfigSpec';

=attr spec

Undocumented upstream. See L<API::Docker::Type::ConfigSpec>.

=cut

1;
