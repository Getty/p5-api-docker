package API::Docker::Type::RestartPolicy;
# ABSTRACT: The behavior to apply when a container exits
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<RestartPolicy> definition of C<spec/v1.51.yaml>.

The default is not to restart. An ever increasing delay -- double the
previous one, starting at 100ms -- is added before each restart to keep a
crash-looping container from flooding the daemon.

=cut

docker name => Str,
  enum => [ '', 'no', 'always', 'unless-stopped', 'on-failure' ];

=attr name

=over 4

=item * the empty string means not to restart

=item * C<no> do not automatically restart

=item * C<always> always restart

=item * C<unless-stopped> restart always, except when the user has manually
stopped the container

=item * C<on-failure> restart only when the container exit code is non-zero

=back

=cut

docker maximum_retry_count => Int;

=attr maximum_retry_count

If C<on-failure> is used, the number of times to retry before giving up.

=cut

1;
