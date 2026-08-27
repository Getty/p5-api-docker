package API::Docker::Config;
# ABSTRACT: Docker config entity
our $VERSION = '0.004';
use Moo;
use MIME::Base64 qw( decode_base64 );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $configs = $docker->configs->list;
    my $config = $configs->[0];

    say $config->ID;
    say $config->Spec->{Name};
    say $config->Spec->{Data};      # still base64, as the daemon sent it
    say $config->decoded_data;      # the bytes

    $config->update(%spec);
    $config->remove;

=head1 DESCRIPTION

This class represents a Docker config. Instances are returned by
L<API::Docker::API::Configs> methods.

A config is an L<API::Docker::Secret> whose value can be read back: the daemon
returns it in C<< Spec->{Data} >> as base64, where a secret returns no payload
at all. L</decoded_data> is the accessor for it.

=head2 Decoding is offered here, not in the API class

L<API::Docker::API::Configs> hands back the daemon's response with nothing
rewritten, which is the rule the whole distribution follows -- so C<< $config
->Spec->{Data} >> is the base64 string the engine sent, unchanged, and stays
that way. L</decoded_data> does not touch it either: it decodes on demand and
returns the bytes, leaving L</Spec> verbatim for anyone who wants to compare
it against the wire or hand it back.

That is the whole reason the accessor belongs on the entity rather than on the
API class: an entity may offer a derived view of a response, an API method may
not silently replace one.

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

The config's ID, which is what L</inspect>, L</update> and L</remove> address
it by.

=cut

has Spec      => (is => 'ro');

=attr Spec

HashRef holding the config's specification exactly as the daemon sent it:
C<Name>, C<Data>, and optionally C<Labels> and C<Templating>. C<Data> is
base64 here and is not decoded -- L</decoded_data> is.

=cut

has Version   => (is => 'ro');

=attr Version

HashRef C<< { Index => ... } >>. The C<Index> is the optimistic-concurrency
token L</update> needs; L</version_index> reaches it directly.

=cut

has CreatedAt => (is => 'ro');

=attr CreatedAt

RFC3339 timestamp string of when the config was created.

=cut

has UpdatedAt => (is => 'ro');

=attr UpdatedAt

RFC3339 timestamp string of when the config was last updated.

=cut

sub decoded_data {
  my ($self) = @_;
  my $spec = $self->Spec;
  return unless ref $spec eq 'HASH';
  return unless defined $spec->{Data};
  return decode_base64($spec->{Data});
}

=method decoded_data

    my $text = $config->decoded_data;

The config's content: C<< Spec->{Data} >> run through
L<MIME::Base64/decode_base64>. Returns nothing when the object carries no
C<Spec> or no C<Data> in it.

The result is B<raw bytes>, symmetric with what
L<API::Docker::API::Configs/create> takes -- decode the character set yourself
if the config holds text above C<U+007F>, for instance with
C<Encode::decode_utf8>.

L</Spec> is left alone; see
L</"Decoding is offered here, not in the API class">.

=cut

sub version_index {
  my ($self) = @_;
  my $version = $self->Version;
  return unless ref $version eq 'HASH';
  return $version->{Index};
}

=method version_index

    my $index = $config->version_index;

The C<Index> out of L</Version>, which is what the daemon wants as the
C<version> query parameter on an update. Returns nothing when the object
carries no C<Version>.

It is the version as of the moment this object was fetched, which is exactly
the token's meaning: an update built on a stale entity is refused by the
daemon rather than silently overwriting whatever changed in between.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->configs->inspect($self->ID);
}

=method inspect

    my $fresh = $config->inspect;

Get fresh config information. Returns a new L<API::Docker::Config>.

=cut

sub update {
  my ($self, %opts) = @_;
  my $version = exists $opts{version} ? delete $opts{version} : $self->version_index;
  return $self->client->configs->update($self->ID, $version, %opts);
}

=method update

    my %spec = %{ $config->Spec };
    delete $spec{Data};                 # already base64 -- see below
    $spec{Labels} = { app => 'web' };
    $config->update(%spec);

Update the config. Passes L</ID> and, by default, L</version_index> to
L<API::Docker::API::Configs/update>; everything else is the spec and becomes
the request body.

The default is only a default. A C<version> key in the arguments is used
verbatim and removed before the spec goes out -- the spec's own fields are all
capitalised (C<Name>, C<Labels>, C<Data>, ...), so a lowercase C<version>
cannot collide with one:

    $config->update(version => $index, %spec);

A C<Data> passed here is raw bytes and gets encoded on the way out, so the
C<Data> already in L</Spec> would be encoded a second time -- drop it, or pass
L</decoded_data> in its place.

=cut

sub remove {
  my ($self) = @_;
  return $self->client->configs->remove($self->ID);
}

=method remove

    $config->remove;

Remove the config. The daemon answers 204 with no body, so this returns
nothing.

=cut

=seealso

=over

=item * L<API::Docker::API::Configs> - Config API operations

=item * L<API::Docker::Secret> - Secret entity, the same shape for a value
that cannot be read back

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
