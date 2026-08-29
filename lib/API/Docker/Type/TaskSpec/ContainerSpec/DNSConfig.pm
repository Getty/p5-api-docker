package API::Docker::Type::TaskSpec::ContainerSpec::DNSConfig;
# ABSTRACT: Specification for DNS related configurations in resolver configuration file (C<resolv.conf>)
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<DNSConfig> schema of C<TaskSpec.ContainerSpec>
in C<spec/v1.51.yaml>.

=cut

docker nameservers => [Str];

=attr nameservers

The IP addresses of the name servers.

=cut

docker search => [Str];

=attr search

A search list for host-name lookup.

=cut

docker options => [Str];

=attr options

A list of internal resolver variables to be modified (e.g., C<debug>,
C<ndots:3>, etc.).

=cut

1;
