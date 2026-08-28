package API::Docker::Type::SystemVersion::Platform;
# ABSTRACT: The name of the platform the daemon reports itself as
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Platform> schema of the C<SystemVersion>
definition in C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker name => Str;

=attr name

Undocumented upstream. What the engine calls itself, and the two answers are
nothing alike: F<t/fixtures/system_version.json>, captured from Docker
27.4.1, carries C<"Docker Engine - Community">, while Podman 5.8.4 (API
1.44) answers C<"linux/amd64/debian-13">. Free text, not a token to branch
on.

=cut

1;
