package API::Docker::Type::HealthConfig;
# ABSTRACT: A test to perform to check that the container is healthy
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<HealthConfig> definition of C<spec/v1.51.yaml>.

Healthcheck commands should be side-effect free.

=cut

docker test => [Str];

=attr test

The test to perform. Possible values are:

=over 4

=item * C<[]> inherit healthcheck from image or parent image

=item * C<["NONE"]> disable healthcheck

=item * C<["CMD", args...]> exec arguments directly

=item * C<["CMD-SHELL", command]> run command with system's default shell

=back

A non-zero exit code indicates a failed healthcheck:

=over 4

=item * C<0> healthy

=item * C<1> unhealthy

=item * C<2> reserved (treated as unhealthy)

=item * other values: error running probe

=back

=cut

docker interval => Int;

=attr interval

The time to wait between checks in nanoseconds. It should be 0 or at least
1000000 (1 ms). 0 means inherit.

=cut

docker timeout => Int;

=attr timeout

The time to wait before considering the check to have hung. It should be 0
or at least 1000000 (1 ms). 0 means inherit.

If the health check command does not complete within this timeout, the check
is considered failed and the health check process is forcibly terminated
without a graceful shutdown.

=cut

docker retries => Int;

=attr retries

The number of consecutive failures needed to consider a container as
unhealthy. 0 means inherit.

=cut

docker start_period => Int;

=attr start_period

Start period for the container to initialize before starting health-retries
countdown in nanoseconds. It should be 0 or at least 1000000 (1 ms). 0 means
inherit.

=cut

docker start_interval => Int, since => '1.44';

=attr start_interval

The time to wait between checks in nanoseconds during the start period. It
should be 0 or at least 1000000 (1 ms). 0 means inherit.

=cut

1;
