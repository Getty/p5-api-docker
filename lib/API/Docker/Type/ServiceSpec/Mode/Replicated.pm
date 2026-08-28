package API::Docker::Type::ServiceSpec::Mode::Replicated;
# ABSTRACT: The replicated mode of a service, and its replica count
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Replicated> schema of C<ServiceSpec.Mode> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker replicas => Int;

=attr replicas

Undocumented upstream. How many tasks the service should be running; C<1> in
the swagger's C<Service> example, whose one task carries
L<API::Docker::Type::Task/slot> C<1>.

=cut

1;
