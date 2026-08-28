package API::Docker::Volume;
# ABSTRACT: Docker volume entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $volumes = $docker->volumes->list;
    my $volume = $volumes->[0];

    say $volume->Name;
    say $volume->Driver;
    say $volume->Mountpoint;

    $volume->remove;

=head1 DESCRIPTION

This class represents a Docker volume. Instances are returned by
L<API::Docker::API::Volumes> methods.

Every field below carries an C<=attr> block, and that list is also the
object's whole field surface: Moo's default constructor silently drops any
key in the daemon's response that has no matching C<has>, so there is no
additional, undocumented attribute waiting on the instance -- only daemon
fields this class does not keep at all.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client.

=cut

has Name       => (is => 'ro');

=attr Name

Volume name.

=cut

has Driver     => (is => 'ro');

=attr Driver

Volume driver (usually C<local>).

=cut

has Mountpoint => (is => 'ro');

=attr Mountpoint

Filesystem path where the volume is mounted on the host.

=cut

has CreatedAt  => (is => 'ro');

=attr CreatedAt

RFC3339 timestamp string of when the volume was created, e.g.
C<2025-01-10T08:00:00Z> as captured in F<t/fixtures/volumes_list.json>.

=cut

has Status     => (is => 'ro');

=attr Status

HashRef of driver-specific status information. Every volume in
F<t/fixtures/volumes_list.json> uses the C<local> driver and reports an empty
HashRef here; a driver that tracks more is expected to fill it in, but no
fixture captured here shows that case.

=cut

has Labels     => (is => 'ro');

=attr Labels

HashRef of the volume's user-defined labels, keyed by label name -- C<{}>
when the volume carries none.

=cut

has Scope      => (is => 'ro');

=attr Scope

The volume's scope, C<local> in every fixture captured here.

=cut

has Options    => (is => 'ro');

=attr Options

HashRef of driver-specific options the volume was created with. Empty
(C<{}>) for every volume in F<t/fixtures/volumes_list.json>.

=cut

has UsageData  => (is => 'ro');

=attr UsageData

HashRef of driver-reported usage information (e.g. C<Size> in bytes) when the
daemon supplies it. No fixture under F<t/fixtures/> shows a volume with this
populated, and neither L<API::Docker::API::Volumes/list> nor
L<API::Docker::API::Volumes/inspect> asks the daemon for it, so expect
C<undef> in practice.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->volumes->inspect($self->Name);
}

=method inspect

    my $updated = $volume->inspect;

Get fresh volume information.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->volumes->remove($self->Name, %opts);
}

=method remove

    $volume->remove(force => 1);

Remove the volume.

=cut

=seealso

=over

=item * L<API::Docker::API::Volumes> - Volume API operations

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
