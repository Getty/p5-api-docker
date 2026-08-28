package API::Docker::API::Volumes;
# ABSTRACT: Docker Engine Volumes API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::Filters';
use API::Docker::Volume;
use Carp qw( croak );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create a volume
    my $volume = $docker->volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

    # List volumes
    my $volumes = $docker->volumes->list;

    # Inspect volume
    my $vol = $docker->volumes->inspect('my-volume');
    say $vol->Mountpoint;

    # Remove volume
    $docker->volumes->remove('my-volume');

=head1 DESCRIPTION

This module provides methods for managing Docker volumes including creation,
listing, inspection, and removal.

Accessed via C<< $docker->volumes >>.

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
  return API::Docker::Volume->new(
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
  my $result = $self->client->get('/volumes',
    params => \%params,
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
  return $self->_wrap_list($result->{Volumes} // []);
}

=method list

    my $volumes = $volumes->list;
    my $unused  = $volumes->list(filters => { dangling => ['true'] });

List volumes. Returns ArrayRef of L<API::Docker::Volume> objects.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<dangling>, C<driver>, C<label> and C<name> here.
Shape-checked and normalised by L<API::Docker::Role::Filters>

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

sub create {
  my ($self, %config) = @_;
  my $result = $self->client->post('/volumes/create', \%config);
  return $self->_wrap($result);
}

=method create

    my $volume = $volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

Create a volume. Returns L<API::Docker::Volume> object.

=cut

sub inspect {
  my ($self, $name, %opts) = @_;
  croak "Volume name required" unless $name;
  my $result = $self->client->get("/volumes/$name",
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
  return $self->_wrap($result);
}

=method inspect

    my $volume = $volumes->inspect('my-volume');

Get detailed information about a volume. Returns L<API::Docker::Volume> object.

Options:

=over

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

sub remove {
  my ($self, $name, %opts) = @_;
  croak "Volume name required" unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->delete_request("/volumes/$name",
    params => \%params,
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
}

=method remove

    $volumes->remove('my-volume', force => 1);

Remove a volume. Optional C<force> parameter.

Options:

=over

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/volumes/prune', undef,
    params => \%params,
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
}

=method prune

    my $result = $volumes->prune;
    my $result = $volumes->prune(filters => { label => ['stage=build'] });

Delete unused volumes. Returns hashref with C<VolumesDeleted> and C<SpaceReclaimed>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Volume> - Volume entity class

=back

=cut

1;
