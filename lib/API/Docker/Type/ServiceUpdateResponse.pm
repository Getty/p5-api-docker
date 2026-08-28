package API::Docker::Type::ServiceUpdateResponse;
# ABSTRACT: The body of the C<200> response to C<POST /services/{id}/update>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ServiceUpdateResponse> definition of
C<spec/v1.51.yaml>, which the swagger leaves undescribed. C<paths:> says
what it is: the body of the C<200> response to C<POST
/services/{id}/update>.

=cut

docker warnings => [Str];

=attr warnings

Optional warning messages.

=cut

1;
