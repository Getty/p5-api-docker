package API::Docker::Type::IPAMConfig;
# ABSTRACT: One entry of C<IPAM.Config>
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<IPAMConfig> definition of C<spec/v1.51.yaml>, which the
swagger leaves undescribed. Nothing in C<paths:> reaches it either; it is
one entry of C<IPAM.Config>.

=cut

docker subnet => Str;

=attr subnet

Undocumented upstream.

=cut

docker ip_range => Str, wire => 'IPRange';

=attr ip_range

Undocumented upstream. Serialised as C<IPRange> -- spelled out, because
deriving it from the Perl name would produce C<IpRange>.

=cut

docker gateway => Str;

=attr gateway

Undocumented upstream.

=cut

docker auxiliary_addresses => { Str, Str };

=attr auxiliary_addresses

Undocumented upstream. B<The keys are the caller's data> and are never
translated.

=cut

1;
