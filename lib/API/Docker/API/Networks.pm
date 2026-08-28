package API::Docker::API::Networks;
# ABSTRACT: Docker Engine Networks API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using';
use API::Docker::Network;
use Carp qw( croak );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create a network
    my $result = $docker->networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

    # List networks
    my $networks = $docker->networks->list;

    # Connect/disconnect containers
    $docker->networks->connect($network_id, Container => $container_id);
    $docker->networks->disconnect($network_id, Container => $container_id);

    # Remove network
    $docker->networks->remove($network_id);

=head1 DESCRIPTION

This module provides methods for managing Docker networks including creation,
listing, connecting containers, and removal.

Accessed via C<< $docker->networks >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->networks->using(read_timeout => 5) >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub _wrap {
  my ($self, $data) = @_;
  return API::Docker::Network->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/networks',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list($result // []);
}

=method list

    my $networks = $networks->list;
    my $bridges  = $networks->list(filters => { driver => ['bridge'] });

List networks. Returns ArrayRef of L<API::Docker::Network> objects.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<dangling>, C<driver>, C<id>, C<label>, C<name>, C<scope> and
C<type> here. Shape-checked and normalised by L<API::Docker::Role::Filters>

=back

=cut

sub inspect {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  my $result = $self->client->get("/networks/$id",
    %{ $self->_request_options },
  );
  return $self->_wrap($result);
}

=method inspect

    my $network = $networks->inspect($id);

Get detailed information about a network. Returns L<API::Docker::Network> object.

=cut

sub create {
  my ($self, %config) = @_;
  croak "Network name required" unless $config{Name};
  my $result = $self->client->post('/networks/create', \%config);
  return $result;
}

=method create

    my $result = $networks->create(
        Name   => 'my-network',
        Driver => 'bridge',
    );

Create a network. Returns hashref with C<Id> and C<Warning>.

=cut

sub remove {
  my ($self, $id) = @_;
  croak "Network ID required" unless $id;
  return $self->client->delete_request("/networks/$id",
    %{ $self->_request_options },
  );
}

=method remove

    $networks->remove($id);

Remove a network.

=cut

sub connect {
  my ($self, $id, %opts) = @_;
  croak "Network ID required" unless $id;
  croak "Container required" unless $opts{Container};
  return $self->client->post("/networks/$id/connect", \%opts);
}

=method connect

    $networks->connect($network_id, Container => $container_id);

Connect a container to a network.

=cut

sub disconnect {
  my ($self, $id, %opts) = @_;
  croak "Network ID required" unless $id;
  croak "Container required" unless $opts{Container};
  return $self->client->post("/networks/$id/disconnect", \%opts);
}

=method disconnect

    $networks->disconnect($network_id, Container => $container_id, Force => 1);

Disconnect a container from a network. Optional C<Force> parameter.

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/networks/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}

=method prune

    my $result = $networks->prune;
    my $result = $networks->prune(filters => { until => ['24h'] });

Delete unused networks. Returns hashref with C<NetworksDeleted>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<until> and C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Network> - Network entity class

=back

=cut

1;
