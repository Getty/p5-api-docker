package API::Docker::Network;
# ABSTRACT: Docker network entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $networks = $docker->networks->list;
    my $network = $networks->[0];

    say $network->Name;
    say $network->Driver;

    $network->connect(Container => $container_id);
    $network->disconnect(Container => $container_id);
    $network->remove;

=head1 DESCRIPTION

This class represents a Docker network. Instances are returned by
L<API::Docker::API::Networks> methods.

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

has Id         => (is => 'ro');

=attr Id

Network ID.

=cut

has Name       => (is => 'ro');

=attr Name

Network name.

=cut

has Created    => (is => 'ro');

=attr Created

RFC3339 timestamp string of when the network was created, e.g.
C<2025-01-10T08:00:00.000000000Z> in F<t/fixtures/networks_list.json>.

=cut

has Scope      => (is => 'ro');

=attr Scope

The network's scope, C<local> in every fixture captured here.

=cut

has Driver     => (is => 'ro');

=attr Driver

Network driver (e.g., C<bridge>, C<overlay>).

=cut

has EnableIPv6 => (is => 'ro');

=attr EnableIPv6

Whether IPv6 is enabled on the network. A decoded JSON boolean, C<false> for
every network in F<t/fixtures/networks_list.json>.

=cut

has IPAM       => (is => 'ro');

=attr IPAM

HashRef of the network's IP address management: C<Driver>, C<Options> and an
ArrayRef C<Config> of C<< { Subnet => ..., Gateway => ... } >> entries -- see
F<t/fixtures/networks_list.json>.

=cut

has Internal   => (is => 'ro');

=attr Internal

Whether the network is restricted to internal connectivity (no default
gateway). C<false> for every network in F<t/fixtures/networks_list.json>.

=cut

has Attachable => (is => 'ro');

=attr Attachable

Whether a container can attach to this network manually. C<false> for every
network in F<t/fixtures/networks_list.json>.

=cut

has Ingress    => (is => 'ro');

=attr Ingress

Whether this is the ingress network for swarm routing-mesh traffic. C<false>
for every network in F<t/fixtures/networks_list.json>.

=cut

has Options    => (is => 'ro');

=attr Options

HashRef of driver-specific options, e.g. the bridge's
C<com.docker.network.bridge.*> keys in F<t/fixtures/networks_list.json>;
C<{}> when the network was created without any.

=cut

has Labels     => (is => 'ro');

=attr Labels

HashRef of the network's labels (C<{}> when there are none).

=cut

has Containers => (is => 'ro');

=attr Containers

Not present in F<t/fixtures/networks_list.json>, and not exercised anywhere
else in this distribution's tests or fixtures, so its shape and meaning are
not verified here.

=cut

has ConfigFrom => (is => 'ro');

=attr ConfigFrom

Not exercised anywhere in this distribution's tests or fixtures, so its
shape and meaning are not verified here.

=cut

has ConfigOnly => (is => 'ro');

=attr ConfigOnly

Not exercised anywhere in this distribution's tests or fixtures, so its
shape and meaning are not verified here.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->networks->inspect($self->Id);
}

=method inspect

    my $updated = $network->inspect;

Get fresh network information.

=cut

sub remove {
  my ($self) = @_;
  return $self->client->networks->remove($self->Id);
}

=method remove

    $network->remove;

Remove the network.

=cut

sub connect {
  my ($self, %opts) = @_;
  return $self->client->networks->connect($self->Id, %opts);
}

=method connect

    $network->connect(Container => $container_id);

Connect a container to this network.

=cut

sub disconnect {
  my ($self, %opts) = @_;
  return $self->client->networks->disconnect($self->Id, %opts);
}

=method disconnect

    $network->disconnect(Container => $container_id, Force => 1);

Disconnect a container from this network.

=cut

=seealso

=over

=item * L<API::Docker::API::Networks> - Network API operations

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
