package API::Docker::Type::HealthcheckResult;
# ABSTRACT: Information about a single run of a healthcheck probe
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<HealthcheckResult> definition of C<spec/v1.51.yaml>.

=cut

docker start => Str;

=attr start

Date and time at which this check started in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker end => Str;

=attr end

Date and time at which this check ended in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker exit_code => Int;

=attr exit_code

ExitCode meanings:

=over 4

=item * C<0> healthy

=item * C<1> unhealthy

=item * C<2> reserved (considered unhealthy)

=item * other values: error running probe

=back

=cut

docker output => Str;

=attr output

Output from last check.

=cut

1;
