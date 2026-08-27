package API::Docker::API::Secrets;
# ABSTRACT: Docker Engine Secrets API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::Filters';
use API::Docker::Secret;
use Carp qw( croak );
use MIME::Base64 qw( encode_base64 );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List secrets
    my $secrets = $docker->secrets->list;

    # Create a secret -- Data is RAW BYTES, this class base64-encodes it
    my $created = $docker->secrets->create(
        Name   => 'my-secret',
        Data   => "hunter2\n",
        Labels => { env => 'prod' },
    );

    # Inspect a secret -- an API::Docker::Secret
    my $secret = $docker->secrets->inspect($created->{ID});
    say $secret->Spec->{Name};

    # Update: the version comes from the inspect above, and is mandatory
    my %spec = %{ $secret->Spec };
    $spec{Labels} = { env => 'staging' };
    $secret->update(%spec);

    # Remove
    $docker->secrets->remove($created->{ID});

=head1 DESCRIPTION

This module provides methods for managing Docker secrets (C</secrets>):
listing, creation, inspection, update and removal.

Accessed via C<< $docker->secrets >>.

The value of a secret is write-only. L</list> and L</inspect> return the
metadata -- C<ID>, C<Spec>, C<CreatedAt>, C<Version> -- and never the payload;
the engine hands that out to containers, not over this API. If you need to
read the value back, this is the wrong storage: use
L<API::Docker::API::Configs>, whose entity offers a C<decoded_data> because
the daemon actually sends one.

=head2 Data is raw bytes; this class does the base64

The wire field C<Data> carries base64. B<This class encodes it for you.> Pass
L</create> raw bytes and they go out encoded; do not pre-encode, or the daemon
faithfully stores your base64 text as the secret.

That division of labour is not a matter of taste, because the daemon does not
validate what it decodes. Measured against Podman 5.4.2: a C<Data> of the
plain text C<"hello there!"> was accepted with B<HTTP 200> and stored three
bytes of garbage -- Go's decoder consumed the leading C<"hell">, stopped at
the space, and reported nothing. A caller left to encode their own payload can
therefore corrupt a secret and be told it succeeded. Doing it here removes
that failure mode from the caller entirely.

The alphabet is B<standard> base64 with padding (C<+> and C</>), not the
URL-safe one, and unwrapped. The Engine API reference calls the field
"base64-url-safe-encoded"; that is measurably not what the engine accepts. The
same four bytes sent as C<-v_--w==> were rejected with B<500>
C<"secret data must be larger than 0 and less than 512000 bytes"> -- the
URL-safe alphabet decoded to nothing -- where C<+v/++w==> was stored correctly.

C<Data> must be a byte string. A string holding characters above C<U+00FF>
croaks here rather than reaching L<MIME::Base64>, which would die with a bare
C<Wide character in subroutine entry>. Encode it first, for instance with
C<Encode::encode_utf8>.

To send an already-encoded value verbatim, bypass this class and use the
transport directly:

    $docker->post('/secrets/create', { Name => 'my-secret', Data => $b64 });

=head2 update takes the current version, and it is mandatory

C<POST /secrets/{id}/update> carries a C<version> query parameter, and the
daemon rejects the request without it. The value is the C<Version.Index> of
the secret as it stands right now, which is what L</inspect> returns:

    my $secret = $docker->secrets->inspect($id);
    $docker->secrets->update($id, $secret->version_index, %spec);

It is an optimistic-concurrency token, not a serial number to invent. If
anything else changed the secret since that C<inspect>, the index has moved on
and the daemon refuses the write instead of silently overwriting that change.
Read it immediately before the update, and read it again before a retry.

This class makes it the second positional argument and croaks when it is
missing or not numeric, so the mistake is caught here rather than one round
trip later. L<API::Docker::Secret/update> supplies it from the entity's own
C<Version.Index> instead, which is the same value read at the same moment.

The Engine API reference states that only C<Labels> may actually change: every
other field of the spec must be sent back unchanged from what C<inspect>
returned. Hence the C<< %spec = %{ $secret->Spec } >> in the SYNOPSIS -- send
the whole spec back with the one key edited, not just the key you edited.

=head2 Swarm, and what Podman serves instead

The Engine API groups C</secrets> with Swarm. A Docker daemon that is not a
swarm manager answers B<503> C<"This node is not a swarm manager."> to every
one of these endpoints, and this client turns that into a croak. That is the
engine behaving as documented, not a fault at this end: it needs
C<docker swarm init>, or a manager to talk to -- and a single-node install
that has never run it is the ordinary case, not an edge one.

C<GET /info>'s C<Swarm.LocalNodeState> does not tell you which of those two
you are looking at. Measured fresh against both engines with no swarm
initialized anywhere, it reports C<"inactive"> on Docker and on Podman alike
-- and Podman still serves C</secrets> with B<200> and real data in that
state, while Docker still answers B<503>. Whether C</secrets> works is a
property of the engine, not of that field.

Podman is the useful exception. Measured against Podman 5.4.2 (API 1.41) with
no swarm involved anywhere, C</secrets> is served from Podman's own local
secret store: L</list>, L</create>, L</inspect> and L</remove> all work, and
the objects carry a C<Version.Index> just as Docker's do. Two differences
worth knowing:

=over

=item * L</create> answers B<200> where Docker documents B<201>. The body is
the same C<< { ID => ... } >>, so only code inspecting the status code notices.

=item * L</update> is not implemented at all: B<501>
C<"update is not supported">, with or without a C<version> parameter.

=back

L<API::Docker::API::Configs> gets none of this -- Podman does not serve
C</configs> from a real store the way it does C</secrets>; see
L<API::Docker::API::Configs/"Swarm, and Podman"> for what it answers instead,
which is not simply "no route" on every path.

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
  return API::Docker::Secret->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

# The wire field is base64; the public contract is raw bytes. Guarding the
# character range here keeps the failure a croak naming this class instead of
# MIME::Base64's "Wide character in subroutine entry" from two frames down.
sub _encode_data {
  my ($self, $method, $data) = @_;
  croak __PACKAGE__ . "->$method Data must be a byte string, not decoded "
    . 'characters -- encode it first (Encode::encode_utf8)'
    if $data =~ /[^\x00-\xff]/;
  return encode_base64($data, '');
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->_wrap_list($self->client->get('/secrets', params => \%params) // []);
}

=method list

    my $secrets = $secrets->list;
    my $secrets = $secrets->list(filters => { label => ['env=prod'] });

List secrets. Returns an ArrayRef of L<API::Docker::Secret> objects.

Options:

=over

=item * C<filters> - HashRef of filters, JSON-encoded by the transport. The
Engine API accepts C<id>, C<label>, C<name> and C<names>; values are always
ArrayRefs of strings, shape-checked and normalised by
L<API::Docker::Role::Filters>.

=back

=cut

sub create {
  my ($self, %spec) = @_;
  croak __PACKAGE__ . '->create Name required'
    unless defined $spec{Name} && length $spec{Name};
  croak __PACKAGE__ . '->create Data required'
    unless defined $spec{Data} && length $spec{Data};
  $spec{Data} = $self->_encode_data('create', $spec{Data});
  return $self->client->post('/secrets/create', \%spec);
}

=method create

    my $created = $secrets->create(
        Name   => 'my-secret',
        Data   => "hunter2\n",
        Labels => { env => 'prod' },
    );

Create a secret. Returns the daemon's response, a HashRef carrying C<ID> --
not an L<API::Docker::Secret>, because C<ID> is all the daemon answers with
and an entity built from it would carry no C<Spec> and no C<Version>. Call
L</inspect> on that C<ID> for the object.

Options:

=over

=item * C<Name> - Required. The secret's name.

=item * C<Data> - Required. The secret's value as B<raw bytes>; this method
base64-encodes it. See L</"Data is raw bytes; this class does the base64">.

=item * C<Labels> - HashRef of labels.

=item * C<Driver> - HashRef naming an external secret driver, C<< { Name =>
..., Options => {...} } >>.

=item * C<Templating> - HashRef naming a templating driver, same shape.

=back

=cut

sub inspect {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->inspect secret ID or name required'
    unless defined $id && length $id;
  return $self->_wrap($self->client->get("/secrets/$id"));
}

=method inspect

    my $secret = $secrets->inspect($id);
    my $index  = $secret->version_index;      # what update needs

Get a secret's metadata by ID or name. Returns an L<API::Docker::Secret>, with
C<ID>, C<Spec>, C<CreatedAt>, C<UpdatedAt> and C<Version>. Never the value --
see L<API::Docker::Secret/"There is no accessor for the value">.

=cut

sub update {
  my ($self, $id, $version, %spec) = @_;
  croak __PACKAGE__ . '->update secret ID or name required'
    unless defined $id && length $id;
  croak __PACKAGE__ . '->update requires the current version as its second '
    . 'argument: the Version.Index from inspect($id), which the daemon uses '
    . 'as an optimistic-concurrency token and will not accept the update '
    . 'without'
    unless defined $version;
  croak __PACKAGE__ . '->update version must be the numeric Version.Index '
    . "from inspect(\$id), got '$version'"
    unless $version =~ /\A[0-9]+\z/;
  $spec{Data} = $self->_encode_data('update', $spec{Data})
    if defined $spec{Data};
  return $self->client->post("/secrets/$id/update", \%spec,
    params => { version => $version });
}

=method update

    my $secret = $secrets->inspect($id);
    my %spec   = %{ $secret->Spec };
    $spec{Labels} = { env => 'staging' };

    $secrets->update($id, $secret->version_index, %spec);
    $secret->update(%spec);                   # the same call, via the entity

Update a secret. Returns nothing on success -- the daemon answers 200 with an
empty body.

C<$version> is mandatory and is the C<Version.Index> from L</inspect>; see
L</"update takes the current version, and it is mandatory"> for why it cannot
be guessed and why the whole spec goes back. L<API::Docker::Secret/update>
fills it in from the entity it was called on. Podman does not implement this
endpoint and answers 501.

=cut

sub remove {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->remove secret ID or name required'
    unless defined $id && length $id;
  return $self->client->delete_request("/secrets/$id");
}

=method remove

    $secrets->remove($id);

Remove a secret by ID or name. The daemon answers 204 with no body, so this
returns nothing; a secret that is not there is a 404 and croaks.

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Secret> - Secret entity class

=item * L<API::Docker::API::Configs> - Configs, the same shape without the
secrecy

=back

=cut

1;
