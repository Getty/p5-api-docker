package API::Docker::Image;
# ABSTRACT: Docker image entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $images = $docker->images->list;
    my $image = $images->[0];

    say $image->Id;
    say join ', ', @{$image->RepoTags};
    say $image->Size;

    $image->tag(repo => 'myrepo/app', tag => 'v1');
    $image->remove;

=head1 DESCRIPTION

This class represents a Docker image. Instances are returned by
L<API::Docker::API::Images> methods.

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

has Id           => (is => 'ro');

=attr Id

Image ID (usually sha256:... hash).

=cut

has ParentId     => (is => 'ro');

=attr ParentId

ID of the parent image layer, or an empty string when the image has none --
both images in F<t/fixtures/images_list.json> report C<"">.

=cut

has RepoTags     => (is => 'ro');

=attr RepoTags

ArrayRef of repository tags (e.g., C<["nginx:latest", "nginx:1.21"]>).

=cut

has RepoDigests  => (is => 'ro');

=attr RepoDigests

ArrayRef of content-addressable digests for the image, e.g.
C<["nginx@sha256:abc123"]> in F<t/fixtures/images_list.json>.

=cut

has Created      => (is => 'ro');

=attr Created

Image creation timestamp, an integer Unix epoch (e.g. C<1705300000> in
F<t/fixtures/images_list.json>) -- the same shape a container C<list> uses,
see L<API::Docker::API::Containers/"The two container shapes">. No fixture
captures an image C<inspect> response, so whether it switches to an RFC3339
string there too, the way a container C<inspect> does, is not verified.

=cut

has Size         => (is => 'ro');

=attr Size

Image size in bytes.

=cut

has SharedSize   => (is => 'ro');

=attr SharedSize

Size in bytes shared with other images (C<list> only).

=cut

has VirtualSize  => (is => 'ro');

=attr VirtualSize

Total size in bytes including shared layers. Equal to L</Size> in both images
of F<t/fixtures/images_list.json>, though nothing here guarantees that holds
in general.

=cut

has Labels       => (is => 'ro');

=attr Labels

HashRef of the image's labels (C<{}> when there are none).

=cut

has Containers   => (is => 'ro');

=attr Containers

Number of containers using this image, as reported by C<list> -- C<2> and
C<1> for the two images in F<t/fixtures/images_list.json>.

=cut

has Architecture => (is => 'ro');

=attr Architecture

The CPU architecture the image was built for (C<inspect> only, e.g.
C<amd64>). No file under F<t/fixtures/> exercises image C<inspect>; this is
confirmed only by this distribution's own test mock in F<t/images.t>.

=cut

has Os           => (is => 'ro');

=attr Os

The OS the image was built for (C<inspect> only, e.g. C<linux>). Same caveat
as L</Architecture> -- no fixture captures this, only the test mock in
F<t/images.t>.

=cut

has Config       => (is => 'ro');

=attr Config

HashRef of the image's default container configuration -- C<Cmd>, C<Env>,
C<Entrypoint> and similar (C<inspect> only). Not exercised by any fixture
under F<t/fixtures/>.

=cut

has RootFS       => (is => 'ro');

=attr RootFS

HashRef describing the image's root filesystem layers (C<inspect> only). Not
exercised anywhere in this distribution's tests or fixtures, so its shape is
not verified here.

=cut

has Metadata     => (is => 'ro');

=attr Metadata

HashRef of driver-specific image metadata (C<inspect> only). Not exercised
anywhere in this distribution's tests or fixtures, so its shape is not
verified here.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->images->inspect($self->Id);
}

=method inspect

    my $updated = $image->inspect;

Get fresh image information.

=cut

sub history {
  my ($self) = @_;
  return $self->client->images->history($self->Id);
}

=method history

    my $history = $image->history;

Get image layer history.

=cut

sub tag {
  my ($self, %opts) = @_;
  return $self->client->images->tag($self->Id, %opts);
}

=method tag

    $image->tag(repo => 'myrepo/app', tag => 'v1');

Tag the image.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->images->remove($self->Id, %opts);
}

=method remove

    $image->remove(force => 1);

Remove the image.

=cut

=seealso

=over

=item * L<API::Docker::API::Images> - Image API operations

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
