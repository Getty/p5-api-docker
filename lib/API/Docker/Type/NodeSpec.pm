package API::Docker::Type::NodeSpec;
# ABSTRACT: The body of a C<POST /nodes/{id}/update> request
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<NodeSpec> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the body of a C<POST
/nodes/{id}/update> request.

=cut

docker name => Str;

=attr name

Name for the node.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker role => Str, enum => [qw( worker manager )];

=attr role

Role of the node. The swagger enumerates C<worker> and C<manager>.

=cut

docker availability => Str, enum => [qw( active pause drain )];

=attr availability

Availability of the node. The swagger enumerates C<active>, C<pause> and
C<drain>.

=cut

1;
