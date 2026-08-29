package API::Docker::Type::IPAMConfig;
# ABSTRACT: One entry of C<IPAM.Config>
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<IPAMConfig> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<IPAM.Config>. Neither the definition nor any of its four
fields carries a description, but L<API::Docker::Type::IPAM/config> writes
out the map form an entry takes: C<< {"Subnet": <CIDR>, "IPRange": <CIDR>,
"Gateway": <IP address>, "AuxAddress": <device_name:IP address>} >>. That is
where the four sentences below come from.

=cut

docker subnet => Str;

=attr subnet

Undocumented upstream. A CIDR block. Measured against Podman 5.8.4 (API
1.44), the default bridge network answers C<10.88.0.0/16>; the swagger's
example is C<172.20.0.0/16>.

=cut

docker ip_range => Str, wire => 'IPRange';

=attr ip_range

Undocumented upstream. A CIDR block inside L</subnet>, C<172.20.10.0/24>
against a C<172.20.0.0/16> subnet in the swagger's examples. Serialised as
C<IPRange> -- spelled out, because deriving it from the Perl name would
produce C<IpRange>.

=cut

docker gateway => Str;

=attr gateway

Undocumented upstream. An IP address. Measured against Podman 5.8.4 (API
1.44), the default bridge network answers C<10.88.0.1>; the swagger's
example is C<172.20.10.11>.

=cut

docker auxiliary_addresses => { Str, Str };

=attr auxiliary_addresses

Undocumented upstream. A device name for each key and an IP address for each
value, which is what C<< "AuxAddress": <device_name:IP address> >> in
L<API::Docker::Type::IPAM/config> spells out. B<The keys are the caller's
data> and are never translated.

=cut

1;
