package API::Docker::Type::ContainerThrottlingData;
# ABSTRACT: CPU throttling stats of the container
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerThrottlingData> definition of
C<spec/v1.51.yaml>.

This type is Linux-specific and omitted for Windows containers.

=cut

docker periods => Int, wire => 'periods', since => '1.51';

=attr periods

Number of periods with throttling active. Serialised as C<periods> --
spelled out, because deriving it from the Perl name would produce
C<Periods>.

=cut

docker throttled_periods => Int, wire => 'throttled_periods', since => '1.51';

=attr throttled_periods

Number of periods when the container hit its throttling limit. Serialised as
C<throttled_periods> -- spelled out, because deriving it from the Perl name
would produce C<ThrottledPeriods>.

=cut

docker throttled_time => Int, wire => 'throttled_time', since => '1.51';

=attr throttled_time

Aggregated time (in nanoseconds) the container was throttled for. Serialised
as C<throttled_time> -- spelled out, because deriving it from the Perl name
would produce C<ThrottledTime>.

=cut

1;
