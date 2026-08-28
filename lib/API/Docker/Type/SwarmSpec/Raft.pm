package API::Docker::Type::SwarmSpec::Raft;
# ABSTRACT: Raft configuration
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<Raft> schema of the C<SwarmSpec> definition in
C<spec/v1.51.yaml>.

=cut

docker snapshot_interval => Int;

=attr snapshot_interval

The number of log entries between snapshots.

=cut

docker keep_old_snapshots => Int;

=attr keep_old_snapshots

The number of snapshots to keep beyond the current snapshot.

=cut

docker log_entries_for_slow_followers => Int;

=attr log_entries_for_slow_followers

The number of log entries to keep around to sync up slow followers after a
snapshot is created.

=cut

docker election_tick => Int;

=attr election_tick

The number of ticks that a follower will wait for a message from the leader
before becoming a candidate and starting an election. C<ElectionTick> must
be greater than C<HeartbeatTick>.

A tick currently defaults to one second, so these translate directly to
seconds currently, but this is NOT guaranteed.

=cut

docker heartbeat_tick => Int;

=attr heartbeat_tick

The number of ticks between heartbeats. Every HeartbeatTick ticks, the
leader will send a heartbeat to the followers.

A tick currently defaults to one second, so these translate directly to
seconds currently, but this is NOT guaranteed.

=cut

1;
