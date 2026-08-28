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

Undocumented upstream. The swagger enumerates C<updating>, C<paused> and
C<completed>.

=cut

docker started_at => Str;

=attr started_at

Undocumented upstream.

=cut

docker completed_at => Str;

=attr completed_at

Undocumented upstream.

=cut

docker message => Str;

=attr message

Undocumented upstream.

=cut

1;
