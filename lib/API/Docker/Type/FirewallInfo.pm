package API::Docker::Type::FirewallInfo;
# ABSTRACT: Information about the daemon's firewalling configuration
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<FirewallInfo> definition of C<spec/v1.51.yaml>.

This field is currently only used on Linux, and omitted on other platforms.

=cut

docker driver => Str, since => '1.51';

=attr driver

The name of the firewall backend driver.

=cut

docker info => [[Str]], since => '1.51';

=attr info

Information about the firewall backend, provided as "label" / "value" pairs.

> B<Note>: The information returned in this field, including the >
formatting of values and labels, should not be considered stable, > and may
change without notice.

=cut

1;
