package API::Docker::Role::Entity::Image;
# ABSTRACT: Image operations, on the generated image types
our $VERSION = '0.005';
use Moo::Role;
with 'API::Docker::Role::Entity';
requires 'id';
use API::Docker::Type::ImageInspect;
use API::Docker::Type::ImageSummary;
use Carp qw( croak );
use Package::Stash;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # from list: an API::Docker::Type::ImageSummary
    my ($image) = @{ $docker->images->list };

    say $image->id;
    say join ', ', @{ $image->repo_tags };
    say $image->size;

    $image->tag(repo => 'myrepo/app', tag => 'v1');
    $image->remove(force => 1);

    # from inspect: an API::Docker::Type::ImageInspect, where the same
    # methods work and the extra build metadata is there
    my $full = $image->inspect;
    say $full->architecture;
    say $full->os;
    say $full->config->cmd->[0];

=head1 DESCRIPTION

The convenience methods of an image. This role is composed, at load time,
into the two generated classes the daemon answers image requests with:

=over

=item * L<API::Docker::Type::ImageSummary> -- one entry of
C<GET /images/json>, what L<API::Docker::API::Images/list> returns

=item * L<API::Docker::Type::ImageInspect> -- the body of
C<GET /images/{name}/json>, what L<API::Docker::API::Images/inspect> returns

=back

Every method here forwards to L<API::Docker::API::Images> with the image's
own C<id> and returns whatever that method returns; the options are that
method's options, undocumented here on purpose so there is one place to
correct when the engine's are found to be something else.

The fields differ between the two classes -- see
L<API::Docker::API::Images/"The two image shapes"> for the differences that
have bitten.

Why the methods are a role applied to generated classes rather than a class
of their own: L<API::Docker::Role::Entity/DESCRIPTION>.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->images->inspect($self->id);
}

=method inspect

    my $full = $image->inspect;

Get fresh image information. Returns an L<API::Docker::Type::ImageInspect>
whatever the invocant was, so this is also how a C<list> entry is turned into
the full shape.

=cut

sub history {
  my ($self) = @_;
  return $self->client->images->history($self->id);
}

=method history

    my $history = $image->history;

Get image layer history. Delegates to L<API::Docker::API::Images/history>,
which hands back the daemon's ArrayRef unwrapped.

=cut

sub tag {
  my ($self, %opts) = @_;
  return $self->client->images->tag($self->id, %opts);
}

=method tag

    $image->tag(repo => 'myrepo/app', tag => 'v1');

Tag the image. Addresses it by C<id> (L<API::Docker::Type::ImageSummary/id>
/ L<API::Docker::Type::ImageInspect/id>, the same field on both), so this
works on an image with no C<repo_tags> at all.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->images->remove($self->id, %opts);
}

=method remove

    $image->remove(force => 1);

Remove the image.

=cut

# --- composition -----------------------------------------------------------
#
# Here rather than in API::Docker::API::Images, for the reason spelled out in
# API::Docker::Role::Entity::Container: loading this role is what puts the
# methods on the classes, so there is no program in which an
# API::Docker::Type::ImageSummary has ->remove and another in which it does
# not, depending on which module was loaded first.
#
# The clash check is not decoration. Moo composes a role into a class the
# class-wins way, so a generated accessor of the same name as a method here
# would silently keep its place and the method would be missing -- and the
# generated classes are written from a specification that grows fields
# without asking. None of the four names collides today; a future one says so
# on the first `use`.
{
  my @provided = Package::Stash->new(__PACKAGE__)->list_all_symbols('CODE');
  for my $class (
    'API::Docker::Type::ImageSummary',
    'API::Docker::Type::ImageInspect',
  ) {
    my $fields = $class->docker_attributes;
    my @clash = sort grep { $fields->{$_} } @provided;
    croak __PACKAGE__ . ': ' . $class . ' declares ' . join(', ', @clash)
      . ' as a daemon field; the generated accessor would win over the '
      . 'method of that name and it would be missing without a word'
      if @clash;
    Moo::Role->apply_roles_to_package($class, __PACKAGE__);
  }
}

=seealso

=over

=item * L<API::Docker::API::Images> - the operations these forward to

=item * L<API::Docker::Type::ImageSummary> - the fields C<list> returns

=item * L<API::Docker::Type::ImageInspect> - the fields C<inspect> returns

=item * L<API::Docker::Role::Entity> - why the methods live in a role

=back

=cut

1;
