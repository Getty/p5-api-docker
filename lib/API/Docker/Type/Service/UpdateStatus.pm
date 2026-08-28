package API::Docker::Type::Service::UpdateStatus;
# ABSTRACT: The status of a service update
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<UpdateStatus> schema of the C<Service>
definition in C<spec/v1.51.yaml>.

=cut

docker state => Str, enum => [qw( updating paused completed )];

=attr state

Undocumented upstream. How far the rolling update has got. L</started_at>
and L</completed_at> bracket it in time and L</message> says in words what
it is doing. The swagger enumerates C<updating>, C<paused> and C<completed>.

=cut

docker started_at => Str;

=attr started_at

Undocumented upstream. RFC 3339, with no example given.

=cut

docker completed_at => Str;

=attr completed_at

Undocumented upstream. The other end of L</started_at>, in the same format.

=cut

docker message => Str;

=attr message

Undocumented upstream. Free text about the update, the human-readable half
of L</state>.

=cut

1;
