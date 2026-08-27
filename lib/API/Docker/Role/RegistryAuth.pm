package API::Docker::Role::RegistryAuth;
# ABSTRACT: AuthConfig encoding shared by the registry-facing endpoints
our $VERSION = '0.004';
use Moo::Role;
use Carp qw( croak );
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( decode_base64 encode_base64 );
use namespace::clean;

=head1 SYNOPSIS

    package API::Docker::API::Whatever;
    use Moo;
    with 'API::Docker::Role::RegistryAuth';

    # The header form: X-Registry-Auth on a registry-facing request
    my $header = $self->_registry_auth_header($opts{auth});

    # The body form: the same credentials as a plain HashRef
    my $config = $self->_registry_auth_config($opts{auth});

=head1 DESCRIPTION

One AuthConfig, two carriers. The Docker Engine takes registry credentials
as a JSON object with the keys C<username>, C<password>, C<serveraddress>,
C<identitytoken> and C<email>, and moves it around in two shapes:

=over

=item * base64url-encoded in the C<X-Registry-Auth> request header, for
C<< POST /images/{name}/push >>, C<< POST /images/create >>,
C<< GET /distribution/{name}/json >> and the C</plugins> family

=item * as the plain JSON request body of C<< POST /auth >>

=back

This role carries the conversion in both directions so every class that
speaks to a registry agrees on it, and so a caller can hand the same C<auth>
argument to any of them.

B<It carries the encoding, not the policy.> Whether a header is sent at all
differs per endpoint on purpose and stays with the endpoint:
L<API::Docker::API::Images/push> sends C<X-Registry-Auth> on B<every> push
because the engine rejects an image push without it, while an anonymous
plugin or distribution call sends B<no> header -- their routers decode the
header and discard the error, so an absent one is the anonymous case rather
than a failure.

=head2 The padding is not optional

The engine decodes C<X-Registry-Auth> with Go's C<base64.URLEncoding>, not
C<RawURLEncoding>, so the C<=> padding is required. Stripping it makes every
push fail with
C<< failed to parse "X-Registry-Auth" header ... unexpected EOF >> -- the
anonymous case included, where the payload C<{}> encodes to C<e30=>: three
characters and one pad.

=cut

sub _registry_auth_header {
  my ($self, $auth) = @_;

  my $payload;
  if (!defined $auth) {
    $payload = '{}';
  }
  elsif (ref $auth eq 'HASH') {
    $payload = encode_json($auth);
  }
  else {
    # Already pre-built JSON or pre-encoded string. If it looks base64-like
    # (no braces), pass through; otherwise encode as-is.
    return $auth if $auth =~ /^[A-Za-z0-9+\/=_\-]+$/;
    $payload = $auth;
  }

  # Padded base64url, and the padding is not optional -- see above.
  my $b64 = encode_base64($payload, '');
  $b64 =~ tr{+/}{-_};
  return $b64;
}

sub _registry_auth_config {
  my ($self, $auth) = @_;

  return undef unless defined $auth;
  return { %$auth } if ref $auth eq 'HASH';
  croak __PACKAGE__ . '->_registry_auth_config auth must be a HashRef, a '
    . 'JSON object or a base64url-encoded one' if ref $auth;

  # The inverse of _registry_auth_header, so a caller can hand POST /auth
  # exactly what it was going to push with -- including a header value it
  # built earlier. The same "looks base64-like" test decides, and in the same
  # order, or the two would disagree about a given string.
  my $json = $auth;
  unless ($auth =~ /^\s*\{/) {
    my $b64 = $auth;
    $b64 =~ tr{-_}{+/};
    # decode_base64 tolerates missing padding, so a value that lost its '='
    # somewhere still decodes here; the header side is where the pad matters.
    $json = decode_base64($b64);
  }

  my $config = eval { decode_json($json) };
  croak __PACKAGE__ . '->_registry_auth_config could not read auth as an '
    . 'AuthConfig: ' . $@ unless ref $config eq 'HASH';
  return $config;
}

=head1 METHODS

Both are private and composed into the resource classes; they are documented
here because the two shapes are one decision, not two.

C<_registry_auth_header($auth)> returns the padded base64url value for
C<X-Registry-Auth>. C<undef> gives the anonymous encoding C<e30=>, a HashRef
is JSON-encoded, and a string that already looks base64-encoded is passed
through untouched.

C<_registry_auth_config($auth)> returns the same credentials as a plain
HashRef for a JSON request body. C<undef> gives C<undef> -- whether that is
an error is the endpoint's call, not this role's. A HashRef is copied, a JSON
object is decoded, and a base64url string is decoded back through both
layers. Anything that does not read as an AuthConfig croaks.

=seealso

=over

=item * L<API::Docker::API::Images> - C<push>, which always sends the header

=item * L<API::Docker::API::System> - C<auth>, which sends the body form

=item * L<API::Docker::API::Distribution> - registry manifest lookups

=item * L<API::Docker::API::Plugins> - the plugin family, which sends the
header only when credentials were given

=back

=cut

1;
