package API::Docker::Type::Health;
# ABSTRACT: Information about the container's healthcheck results
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::HealthcheckResult;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<Health> definition of C<spec/v1.51.yaml>.

=cut

docker status => Str, enum => [qw( none starting healthy unhealthy )];

=attr status

Status is one of C<none>, C<starting>, C<healthy> or C<unhealthy>

=over 4

=item * "none" Indicates there is no healthcheck

=item * "starting" Starting indicates that the container is not yet ready

=item * "healthy" Healthy indicates that the container is running correctly

=item * "unhealthy" Unhealthy indicates that the container has a problem

=back

=cut

docker failing_streak => Int;

=attr failing_streak

FailingStreak is the number of consecutive failures.

=cut

docker log => [ 'HealthcheckResult' ];

=attr log

Log contains the last few results (oldest first). See
L<API::Docker::Type::HealthcheckResult>.

=cut

1;
