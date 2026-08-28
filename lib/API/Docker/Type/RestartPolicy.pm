package API::Docker::Type::RestartPolicy;
# ABSTRACT: The behavior to apply when the container exits
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<RestartPolicy> definition of C<spec/v1.51.yaml>.

The default is not to restart.

An ever increasing delay (double the previous delay, starting at 100ms) is
added before each restart to prevent flooding the server.

=cut

docker name => Str,
  enum => [ '', 'no', 'always', 'unless-stopped', 'on-failure' ];

=attr name

=over 4

=item * Empty string means not to restart

=item * C<no> Do not automatically restart

=item * C<always> Always restart

=item * C<unless-stopped> Restart always except when the user has manually
stopped the container

=item * C<on-failure> Restart only when the container exit code is non-zero

=back

=cut

docker maximum_retry_count => Int;

=attr maximum_retry_count

If C<on-failure> is used, the number of times to retry before giving up.

=cut

1;
