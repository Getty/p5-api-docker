package API::Docker::API::Distribution;
# ABSTRACT: Docker Engine Distribution API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::RegistryAuth';
use Carp qw( croak );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Ask a registry about an image reference without pulling it
    my $descriptor = $docker->distribution->inspect('nginx:latest');

    # With registry credentials
    my $descriptor = $docker->distribution->inspect('private/app:1.0',
        auth => {
            username => 'someone',
            password => 'secret',
        },
    );

    # The same question as a predicate: is that tag already published?
    if ($docker->distribution->exists('myrepo/app:1.0', auth => $auth)) {
        die "refusing to overwrite a released tag";
    }

=head1 DESCRIPTION

This module provides access to the Docker distribution endpoint
(C<GET /distribution/{name}/json>), which asks a I<registry> for the manifest
descriptor of an image reference without pulling the image.

Accessed via C<< $docker->distribution >>.

The reference goes into the path unescaped, so its slashes and its tag stay
readable on the wire (C</distribution/myrepo/app:1.0/json>) -- that is what
the engine parses, and percent-encoding them breaks the reference.

=head2 A 404 means two different things

The endpoint answers 404 both when the registry does not have the reference
and when the engine has no such route, and the two want opposite handling.
The split here is:

=over

=item * L</inspect> is the endpoint, and croaks on B<any> error status, 404
included, the way every other method in this distribution does.

=item * L</exists> is the question, and answers it: true, false, or a croak
when the engine could not ask the registry at all.

=back

L</exists> exists because answering "no" to everything is the failure this
class was added to remove -- see the Podman note below -- and a predicate
that cannot fail loudly would have reintroduced it one layer up.

=head2 Not available on Podman

Measured against the rootless Podman socket (5.4.2, API 1.41):
C<< GET /v1.41/distribution/nginx:latest/json >> answers C<404 Not Found>
with
C<< {"cause":"","message":"Path /v1.41/distribution/nginx:latest/json is not supported","response":0} >>,
and so does every other reference, escaped or not -- the compat layer has no
route for this endpoint. This class therefore needs a real Docker daemon.

That 404 is exactly the one a naive predicate would read as "the registry
does not have it", which is why L</exists> tells the engine's own
no-such-route answer apart and croaks on it instead.

=head2 What this class returns

L</inspect> returns the decoded engine response -- a HashRef with
C<Descriptor> and C<Platforms> -- not an entity object, deviating from the
C<inspect> convention the other resource classes follow, because there is no
C<API::Docker::Distribution> entity class to wrap it in.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

# Only when the caller asked for it, like the plugin family and unlike
# /images/{name}/push. The distribution router decodes the header and
# discards the error -- the same "ignore invalid AuthConfig" pattern the
# plugin routes use -- so a public image is looked up anonymously, with no
# header at all. Not verifiable on this machine: Podman serves no route here.
sub _auth_headers {
  my ($self, $opts) = @_;
  return () unless defined $opts->{auth};
  return (headers => { 'X-Registry-Auth' => $self->_registry_auth_header($opts->{auth}) });
}

sub inspect {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->inspect requires an image reference' unless $name;

  return $self->client->get("/distribution/$name/json",
    $self->_auth_headers(\%opts),
    (exists $opts{response} ? (response => $opts{response}) : ()));
}

=method inspect

    my $descriptor = $distribution->inspect('nginx:latest');
    my $descriptor = $distribution->inspect('private/app:1.0', auth => $auth);

Ask the registry for the manifest descriptor of an image reference. The
daemon performs the lookup; nothing is pulled and no local image is touched.

Returns a HashRef with C<Descriptor> -- C<MediaType>, C<digest>, C<size>,
C<URLs> -- and C<Platforms>, the list of C<{ Architecture, OS, ... }> the
reference resolves to.

B<A missing reference croaks.> This method is the endpoint, so it inherits
the transport's rule that any status at or above 400 is an error, and the
registry's "no such reference" is a 404 like any other. Use L</exists> for
the predicate, or eval and read the status:

    my %res;
    my $d = eval { $distribution->inspect($ref, response => \%res) };
    # $res{status} == 404 here means the registry said no *or* the engine
    # has no such route -- see L</exists>, which separates the two.

Options:

=over

=item * C<auth> - Registry credentials, in any shape
L<API::Docker::API::Images/push> accepts them: a HashRef of C<username> /
C<password> / C<serveraddress> / C<identitytoken>, or a pre-encoded base64
string. Sent as C<X-Registry-Auth>. Unlike C<push>, which always sends the
header, it is omitted entirely without this option -- the lookup is then
anonymous, which is what a public image needs

=item * C<response> - HashRef the status line and the response headers are
written into, as for L<API::Docker::Role::HTTP/get>

=back

=cut

# The engine's own "I have no such route" 404 versus the registry's "I do not
# have that reference" 404. Measured on Podman 5.4.2 (API 1.41), which has no
# route: 'Path /v1.41/distribution/nginx:latest/json is not supported'.
# Docker's own unknown-route answer is 'page not found'. Anything not
# recognised as the engine talking about itself is taken as the registry's
# answer, so an unfamiliar wording degrades to plain "404 means no" rather
# than to a wrong croak.
my $NO_SUCH_ROUTE = qr/\bis not supported\b|\bpage not found\b/i;

sub exists {
  my ($self, $name, %opts) = @_;
  croak __PACKAGE__ . '->exists requires an image reference' unless $name;

  # A caller's own response HashRef is reused rather than shadowed, so
  # passing one through this method still fills it.
  my $res = ref $opts{response} eq 'HASH' ? $opts{response} : {};
  my $ok = eval {
    $self->inspect($name, %opts, response => $res);
    1;
  };
  return 1 if $ok;

  my $err = $@;
  die $err unless ($res->{status} // 0) == 404;
  croak __PACKAGE__ . '->exists cannot ask this engine: ' . $err
    if $err =~ $NO_SUCH_ROUTE;
  return 0;
}

=method exists

    if ($distribution->exists('myrepo/app:1.0', auth => $auth)) { ... }

Whether the registry has that image reference. Returns a true value when the
lookup succeeded, a false one when the registry answered 404, and B<croaks>
otherwise -- including when the engine has no C</distribution> route, so that
an engine which cannot answer the question never answers it with "no".

Takes the same options as L</inspect>. Callable without an C<eval>: every
outcome it returns is an answer from the registry, and everything else is
loud.

The distinction rests on the engine's error message, which is the only thing
that separates the two 404s -- C<is not supported> from Podman,
C<page not found> from Docker's own router. A wording neither recognises is
read as the registry's answer, i.e. as false, which is the behaviour a plain
"404 means no" would have had anyway.

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::RegistryAuth> - the shared C<X-Registry-Auth>
encoding

=item * L<API::Docker::API::Images> - Image management, including C<push> and
its C<X-Registry-Auth> handling

=back

=cut

1;
