package API::Docker::Type::SwarmSpec::Dispatcher;
# ABSTRACT: Dispatcher configuration
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Dispatcher> schema of the C<SwarmSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker heartbeat_period => Int;

=attr heartbeat_period

The delay for an agent to send a heartbeat to the dispatcher.

=cut

1;
