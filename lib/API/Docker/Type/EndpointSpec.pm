package API::Docker::Type::EndpointSpec;
# ABSTRACT: Properties that can be configured to access and load balance a service
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EndpointPortConfig;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<EndpointSpec> definition of C<spec/v1.51.yaml>.

=cut

docker mode => Str, enum => [qw( vip dnsrr )];

=attr mode

The mode of resolution to use for internal load balancing between tasks. The
swagger enumerates C<vip> and C<dnsrr>. The daemon defaults it to vip.

=cut

docker ports => [ 'EndpointPortConfig' ];

=attr ports

List of exposed ports that this service is accessible on from the outside.
Ports can only be provided if C<vip> resolution mode is used. See
L<API::Docker::Type::EndpointPortConfig>.

=cut

1;
