package API::Docker::Type::RegistryServiceConfig;
# ABSTRACT: Daemon registry services configuration
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::IndexInfo;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<RegistryServiceConfig> definition of
C<spec/v1.51.yaml>.

=cut

docker insecure_registry_cidrs => [Str], wire => 'InsecureRegistryCIDRs';

=attr insecure_registry_cidrs

List of IP ranges of insecure registries, using the CIDR syntax (L<RFC
4632|https://tools.ietf.org/html/4632>). Insecure registries accept
un-encrypted (HTTP) and/or untrusted (HTTPS with certificates from unknown
CAs) communication.

By default, local registries (C<::1/128> and C<127.0.0.0/8>) are configured
as insecure. All other registries are secure. Communicating with an insecure
registry is not possible if the daemon assumes that registry is secure.

This configuration override this behavior, insecure communication with
registries whose resolved IP address is within the subnet described by the
CIDR syntax.

Registries can also be marked insecure by hostname. Those registries are
listed under C<IndexConfigs> and have their C<Secure> field set to C<false>.

> B<Warning>: Using this option can be useful when running a local >
registry, but introduces security vulnerabilities. This option > should
therefore ONLY be used for testing purposes. For increased > security, users
should add their CA to their system's list of trusted > CAs instead of
enabling this option. Serialised as C<InsecureRegistryCIDRs> -- spelled out,
because deriving it from the Perl name would produce
C<InsecureRegistryCidrs>.

=cut

docker index_configs => { Str, 'IndexInfo' };

=attr index_configs

Undocumented upstream. One L<API::Docker::Type::IndexInfo> per registry the
daemon knows, keyed by the registry's own name -- C<docker.io>,
C<127.0.0.1:5000> and C<< [2001:db8:a0b:12f0::1]:80 >> among the swagger's
examples. L</insecure_registry_cidrs> describes this map as where a registry
marked insecure by hostname is listed, with its C<Secure> set to false.
Measured against Podman 5.8.4 (API 1.44), C<GET /info> answers an empty map
here. See L<API::Docker::Type::IndexInfo>. B<The keys are the caller's data>
and are never translated.

=cut

docker mirrors => [Str];

=attr mirrors

List of registry URLs that act as a mirror for the official (C<docker.io>)
registry.

=cut

1;
