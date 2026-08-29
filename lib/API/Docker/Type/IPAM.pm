package API::Docker::Type::IPAM;
# ABSTRACT: The C<IPAM> field of the body of a C<POST /networks/create> request
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::IPAMConfig;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<IPAM> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. C<paths:> says what it is: the C<IPAM> field of
the body of a C<POST /networks/create> request.

=cut

docker driver => Str;

=attr driver

Name of the IPAM driver to use. The daemon defaults it to default.

=cut

docker config => [ 'IPAMConfig' ];

=attr config

List of IPAM configuration options, specified as a map:

    {"Subnet": <CIDR>, "IPRange": <CIDR>, "Gateway": <IP address>, "AuxAddress": <device_name:IP address>}

See L<API::Docker::Type::IPAMConfig>.

=cut

docker options => { Str, Str };

=attr options

Driver-specific options, specified as a map. B<The keys are the caller's
data> and are never translated.

=cut

1;
