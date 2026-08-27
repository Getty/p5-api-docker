package API::Docker::Secret;
# ABSTRACT: Docker secret entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $secrets = $docker->secrets->list;
    my $secret = $secrets->[0];

    say $secret->ID;
    say $secret->Spec->{Name};
    say $secret->version_index;

    $secret->update(%spec);
    $secret->remove;

=head1 DESCRIPTION

This class represents a Docker secret. Instances are returned by
L<API::Docker::API::Secrets> methods.

=head2 There is no accessor for the value

A secret carries no payload on this API at all. The daemon hands the value to
containers, never back over C</secrets>: neither C<list> nor C<inspect>
returns a C<< Spec->{Data} >>, so there is nothing here to decode. That is why
this class has no C<decoded_data>, where L<API::Docker::Config> does -- the
difference is in what the engine sends, not in what the two classes choose to
offer. In the C<GET /secrets> response captured from Podman 5.4.2 (API 1.41)
in F<t/fixtures/secrets_list.json>, each object carries C<ID>, C<CreatedAt>,
C<UpdatedAt>, C<Spec> and C<Version>, and the C<Spec> has C<Name>, C<Driver>
and C<Labels> but no C<Data> key whatsoever.

If you need to read a value back, a secret is the wrong storage -- put it in
an L<API::Docker::Config>.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client.

=cut

has ID        => (is => 'ro');

=attr ID

The secret's ID, which is what L</inspect>, L</update> and L</remove> address
it by.

=cut

has Spec      => (is => 'ro');

=attr Spec

HashRef holding the secret's specification exactly as the daemon sent it:
C<Name>, and optionally C<Labels>, C<Driver> and C<Templating>. Never a
C<Data>.

=cut

has Version   => (is => 'ro');

=attr Version

HashRef C<< { Index => ... } >>. The C<Index> is the optimistic-concurrency
token L</update> needs; L</version_index> reaches it directly.

=cut

has CreatedAt => (is => 'ro');
has UpdatedAt => (is => 'ro');

sub version_index {
  my ($self) = @_;
  my $version = $self->Version;
  return unless ref $version eq 'HASH';
  return $version->{Index};
}

=method version_index

    my $index = $secret->version_index;

The C<Index> out of L</Version>, which is what the daemon wants as the
C<version> query parameter on an update. Returns nothing when the object
carries no C<Version>.

It is the version as of the moment this object was fetched, which is exactly
the token's meaning: an update built on a stale entity is refused by the
daemon rather than silently overwriting whatever changed in between.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->secrets->inspect($self->ID);
}

=method inspect

    my $fresh = $secret->inspect;

Get fresh secret information. Returns a new L<API::Docker::Secret>.

=cut

sub update {
  my ($self, %opts) = @_;
  my $version = exists $opts{version} ? delete $opts{version} : $self->version_index;
  return $self->client->secrets->update($self->ID, $version, %opts);
}

=method update

    my %spec = %{ $secret->Spec };
    $spec{Labels} = { env => 'staging' };
    $secret->update(%spec);

Update the secret. Passes L</ID> and, by default, L</version_index> to
L<API::Docker::API::Secrets/update>; everything else is the spec and becomes
the request body.

The default is only a default. A C<version> key in the arguments is used
verbatim and removed before the spec goes out -- the spec's own fields are all
capitalised (C<Name>, C<Labels>, C<Data>, ...), so a lowercase C<version>
cannot collide with one:

    $secret->update(version => $index, %spec);

Send the whole spec back with the one key edited; the Engine API accepts a
change to C<Labels> only and wants every other field unchanged. Podman does
not implement this endpoint and answers 501.

=cut

sub remove {
  my ($self) = @_;
  return $self->client->secrets->remove($self->ID);
}

=method remove

    $secret->remove;

Remove the secret. The daemon answers 204 with no body, so this returns
nothing.

=cut

=seealso

=over

=item * L<API::Docker::API::Secrets> - Secret API operations

=item * L<API::Docker::Config> - Config entity, the same shape with a readable
value

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
