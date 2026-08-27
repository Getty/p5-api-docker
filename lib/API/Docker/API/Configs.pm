package API::Docker::API::Configs;
# ABSTRACT: Docker Engine Configs API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::Filters';
use Carp qw( croak );
use MIME::Base64 qw( encode_base64 );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List configs
    my $configs = $docker->configs->list;

    # Create a config -- Data is RAW BYTES, this class base64-encodes it
    my $created = $docker->configs->create(
        Name   => 'my-config',
        Data   => "listen 8080;\n",
        Labels => { app => 'web' },
    );

    # Inspect a config -- Spec.Data comes back base64, and stays that way
    my $config = $docker->configs->inspect($created->{ID});
    my $text   = MIME::Base64::decode_base64($config->{Spec}{Data});

    # Update: the version comes from the inspect above, and is mandatory
    my %spec = %{ $config->{Spec} };
    $spec{Labels} = { app => 'web', tier => 'edge' };
    $docker->configs->update($created->{ID}, $config->{Version}{Index}, %spec);

    # Remove
    $docker->configs->remove($created->{ID});

=head1 DESCRIPTION

This module provides methods for managing Docker configs (C</configs>):
listing, creation, inspection, update and removal.

Accessed via C<< $docker->configs >>.

Configs are L<API::Docker::API::Secrets> without the secrecy: the same five
endpoints, the same spec shape, the same mandatory C<version> on update. The
one behavioural difference is that a config's value can be read back --
L</inspect> returns it in C<< $config->{Spec}{Data} >>, where a secret returns
no payload at all. Which is the whole point of the split: put configuration in
a config, and anything you would mind seeing in a C<docker config inspect> in
a secret.

=head2 Data is raw bytes on the way out, base64 on the way back

The wire field C<Data> carries base64. B<L</create> and L</update> encode it
for you> -- pass them raw bytes, and do not pre-encode, or the daemon stores
your base64 text as the config's content.

Doing it here is not a convenience, it is a guard. The daemon does not
validate what it decodes: measured against Podman 5.4.2's C</secrets>, which
takes the identical field, a C<Data> of the plain text C<"hello there!"> was
accepted with B<HTTP 200> and stored three bytes of garbage -- Go's decoder
took the leading C<"hell">, stopped at the space, and said nothing. A caller
left to encode their own payload can corrupt the value and be told it worked.

The alphabet is B<standard> base64 with padding (C<+> and C</>), unwrapped,
and not the URL-safe one. The Engine API reference calls the field
"base64-url-safe-encoded" and that is measurably not what the engine takes:
four bytes sent as C<-v_--w==> were rejected B<500>, the same four as
C<+v/++w==> stored correctly.

C<Data> must be a byte string. Characters above C<U+00FF> croak here rather
than reaching L<MIME::Base64> and dying with a bare
C<Wide character in subroutine entry>; encode first, e.g. with
C<Encode::encode_utf8>.

B<The reverse trip is not symmetric, deliberately.> L</inspect> and L</list>
hand back exactly what the daemon sent, so C<< {Spec}{Data} >> is still
base64 and you decode it yourself:

    my $text = MIME::Base64::decode_base64($config->{Spec}{Data});

The asymmetry follows one rule: this class encodes where getting it wrong is
silent, and touches nothing where getting it wrong is visible. An unencoded
C<Data> going out is stored as garbage with a 200; a base64 string coming back
is obvious the moment you look at it. Decoding it here would also mean
rewriting a daemon response, which nothing else in this distribution does.

To send an already-encoded value verbatim, bypass this class:

    $docker->post('/configs/create', { Name => 'my-config', Data => $b64 });

=head2 update takes the current version, and it is mandatory

C<POST /configs/{id}/update> carries a C<version> query parameter and the
daemon rejects the request without it. The value is the C<Version.Index> of
the config as it stands right now, which is what L</inspect> returns:

    my $config = $docker->configs->inspect($id);
    $docker->configs->update($id, $config->{Version}{Index}, %spec);

It is an optimistic-concurrency token, not a serial number to invent. If
anything else changed the config since that C<inspect>, the index has moved on
and the daemon refuses the write rather than silently overwriting that change.
Read it immediately before the update, and again before a retry.

This class makes it the second positional argument and croaks when it is
missing or not numeric, so the mistake surfaces here instead of one round trip
later.

The Engine API reference states that only C<Labels> may actually change: the
rest of the spec must go back unchanged from what C<inspect> returned. Hence
C<< %spec = %{ $config->{Spec} } >> in the SYNOPSIS -- send the whole spec back
with the one key edited. Note that a C<Spec> from C<inspect> carries C<Data>
already base64-encoded, so passing it straight to L</update> would encode it a
second time; delete the key, or decode it, before sending it back.

=head2 Swarm, and Podman

The Engine API groups C</configs> with Swarm. A Docker daemon that is not a
swarm manager answers B<503> C<"This node is not a swarm manager."> to all of
these endpoints, which this client turns into a croak. That is documented
engine behaviour, not a fault at this end -- the daemon needs
C<docker swarm init>, or a manager to talk to.

B<Podman does not serve C</configs> at all.> Measured against Podman 5.4.2
(API 1.41): every path under it answers B<404> with the plain-text body
C<Not Found>, not a JSON error, so the croak from this client reads
C<Docker API error (404): Not Found>. There is no Podman-side equivalent to
fall back on and no socket setting that enables it. This is the one class in
the distribution that cannot be exercised against the engine the rest of it is
tested on -- L<API::Docker::API::Secrets>, the same five endpoints, is served
by Podman from its own local secret store.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

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
  return $self->client->get('/configs', params => \%params) // [];
}

=method list

    my $configs = $configs->list;
    my $configs = $configs->list(filters => { label => ['app=web'] });

List configs. Returns an ArrayRef of HashRefs exactly as the daemon sent them
-- unlike C<< $docker->volumes->list >> these are not wrapped in an entity
class, because there is no C<API::Docker::Config>. Each carries a
C<< {Spec}{Data} >> that is still base64.

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
  return $self->client->post('/configs/create', \%spec);
}

=method create

    my $created = $configs->create(
        Name   => 'my-config',
        Data   => "listen 8080;\n",
        Labels => { app => 'web' },
    );

Create a config. Returns the daemon's response, a HashRef carrying C<ID>.

Options:

=over

=item * C<Name> - Required. The config's name.

=item * C<Data> - Required. The config's content as B<raw bytes>; this method
base64-encodes it. See L</"Data is raw bytes on the way out, base64 on the way back">.

=item * C<Labels> - HashRef of labels.

=item * C<Templating> - HashRef naming a templating driver,
C<< { Name => ..., Options => {...} } >>.

=back

=cut

sub inspect {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->inspect config ID or name required'
    unless defined $id && length $id;
  return $self->client->get("/configs/$id");
}

=method inspect

    my $config = $configs->inspect($id);
    my $index  = $config->{Version}{Index};   # what update needs
    my $text   = MIME::Base64::decode_base64($config->{Spec}{Data});

Get a config by ID or name. Returns the daemon's HashRef unchanged, with
C<ID>, C<Spec>, C<CreatedAt>, C<UpdatedAt> and C<Version>. C<< {Spec}{Data} >>
is base64 and is B<not> decoded here.

=cut

sub update {
  my ($self, $id, $version, %spec) = @_;
  croak __PACKAGE__ . '->update config ID or name required'
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
  return $self->client->post("/configs/$id/update", \%spec,
    params => { version => $version });
}

=method update

    my $config = $configs->inspect($id);
    my %spec   = %{ $config->{Spec} };
    delete $spec{Data};                       # already base64 -- see below
    $spec{Labels} = { app => 'web', tier => 'edge' };

    $configs->update($id, $config->{Version}{Index}, %spec);

Update a config. Returns nothing on success -- the daemon answers 200 with an
empty body.

C<$version> is mandatory and is the C<Version.Index> from L</inspect>; see
L</"update takes the current version, and it is mandatory"> for why it cannot
be guessed and why the whole spec goes back.

A C<Data> passed here is treated like L</create>'s: raw bytes, encoded on the
way out. The C<Data> in a C<Spec> from L</inspect> is already base64, so drop
or decode it before handing that spec back, or it gets encoded twice.

=cut

sub remove {
  my ($self, $id) = @_;
  croak __PACKAGE__ . '->remove config ID or name required'
    unless defined $id && length $id;
  return $self->client->delete_request("/configs/$id");
}

=method remove

    $configs->remove($id);

Remove a config by ID or name. The daemon answers 204 with no body, so this
returns nothing; a config that is not there is a 404 and croaks.

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::API::Secrets> - Secrets, the same shape for values that
must not be readable back

=back

=cut

1;
