package API::Docker::API::System;
# ABSTRACT: Docker Engine System API
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # System information
    my $info = $docker->system->info;
    say "Docker version: " . $info->{ServerVersion};

    # API version
    my $version = $docker->system->version;
    say "API version: " . $version->{ApiVersion};

    # Health check
    my $pong = $docker->system->ping;

    # Monitor events
    my $events = $docker->system->events(
        since => time() - 3600,
    );

    # Disk usage
    my $df = $docker->system->df;

=head1 DESCRIPTION

This module provides access to Docker system-level operations including daemon
information, version detection, health checks, and event monitoring.

Accessed via C<< $docker->system >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub info {
  my ($self) = @_;
  return $self->client->get('/info');
}

=method info

    my $info = $system->info;

Get system-wide information about the Docker daemon.

Returns hashref with keys including:

=over

=item * C<ServerVersion> - Docker version

=item * C<Containers> - Total number of containers

=item * C<Images> - Total number of images

=item * C<Driver> - Storage driver

=item * C<MemTotal> - Total memory

=back

=cut

sub version {
  my ($self) = @_;
  return $self->client->get('/version');
}

=method version

    my $version = $system->version;

Get version information about the Docker daemon and API.

Returns hashref with keys including C<ApiVersion>, C<Version>, C<GitCommit>,
C<GoVersion>, C<Os>, and C<Arch>.

=cut

sub ping {
  my ($self) = @_;
  return $self->client->get('/_ping');
}

=method ping

    my $pong = $system->ping;

Health check endpoint. Returns C<OK> string if daemon is responsive.

=cut

sub events {
  my ($self, %opts) = @_;
  my %params;
  $params{since}   = $opts{since}   if defined $opts{since};
  $params{until}   = $opts{until}   if defined $opts{until};
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->get('/events', params => \%params);
}

=method events

    my $events = $system->events(
        since   => 1234567890,
        until   => 1234567900,
        filters => { type => ['container'] },
    );

Get real-time events from the Docker daemon.

Options:

=over

=item * C<since> - Show events created since this timestamp

=item * C<until> - Show events created before this timestamp

=item * C<filters> - Hashref of filters (e.g., C<< { type => ['container', 'image'] } >>)

=back

=cut

sub df {
  my ($self) = @_;
  return $self->client->get('/system/df');
}

=method df

    my $usage = $system->df;

Get data usage information (disk usage by images, containers, and volumes).

Returns hashref with C<LayersSize>, C<Images>, C<Containers>, and C<Volumes> arrays.

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
