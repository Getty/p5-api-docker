use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec;
use FindBin;
use Package::Stash;

# Every class of the generated type model, loaded and asked what it
# registered. The suite otherwise exercises a handful of them by name, so a
# class that failed to compile, or that declared an attribute the registry
# never heard of, would sit in lib/ unnoticed until a caller found it.
#
# Nothing here opens a socket or reaches a daemon, in either mode.

my $LIB  = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..', 'lib'));
my $ROOT = File::Spec->catdir($LIB, 'API', 'Docker', 'Type');
plan skip_all => 'no generated type model in this distribution' unless -d $ROOT;

my @classes;
find(
  { no_chdir => 1, wanted => sub {
      return unless /\.pm\z/;
      my $rel = File::Spec->abs2rel($File::Find::name, $LIB);
      $rel =~ s{\.pm\z}{};
      push @classes, join '::', File::Spec->splitdir($rel);
    } },
  $ROOT,
);
@classes = sort @classes;
cmp_ok scalar @classes, '>=', 200, 'the model is all there';

my (@failed, @empty, @bad_wire, @bad_type, @unloadable_target);
for my $class (@classes) {
  unless (eval "require $class; 1") { push @failed, "$class: $@"; next }
  my $registry = $class->docker_attributes;
  push @empty, $class unless %$registry;
  for my $name (sort keys %$registry) {
    my $info = $registry->{$name};
    push @bad_wire, "$class.$name" unless defined $info->{wire} && length $info->{wire};
    push @bad_type, "$class.$name" unless ref $info->{type} eq 'HASH' && $info->{type}{kind};
    # Every class an attribute names must exist, or the first hashref a
    # caller hands that field dies inside the coercion rather than here.
    my $target = $info->{type};
    $target = $target->{inner} while $target->{inner};
    next unless $target->{kind} eq 'object';
    push @unloadable_target, "$class.$name -> $target->{class}"
      unless eval "require $target->{class}; 1";
  }
}

is_deeply \@failed,  [], 'every class compiles';
is_deeply \@empty,   [], 'every class registered at least one attribute';
is_deeply \@bad_wire, [], 'every attribute carries a wire name';
is_deeply \@bad_type, [], 'every attribute carries a parsed type descriptor';
is_deeply \@unloadable_target, [], 'every class an attribute points at is loadable';

subtest 'the whole model round-trips an empty object' => sub {
  # TO_JSON walks the registry rather than the object, so an attribute the
  # DSL half-registered would show up here as a key with no value rather
  # than as an absent field.
  my @noisy = grep { keys %{ $_->new->TO_JSON } } @classes;
  is_deeply \@noisy, [],
    'a class with nothing set serialises to an empty structure';
};

subtest 'a generated class holds its fields and the documented roster' => sub {
  # What `use API::Docker::Type` puts on a class is a fixed set: Moo's
  # keywords, the type vocabulary, the two DSL keywords, and everything
  # composing API::Docker::Role::Type contributes. Measured over all 201
  # classes it is the same 33 names every time, so the surface of a
  # generated class can be stated positively -- its registry attributes plus
  # this roster, and nothing else.
  #
  # Stated that way on purpose. The assertion here used to be a list of two
  # forbidden names, croak and blessed, which leaked onto every class until
  # API::Docker::Role::Type gained its namespace::clean (karr k82). Half of
  # it went vacuous the moment the blessed import was dropped from that role
  # (karr k87): the name could no longer arrive, so forbidding it proved
  # nothing, and nobody could tell by reading it. A roster cannot go vacuous
  # -- it fails on a name that appears and on one that disappears -- and it
  # names the leak without anyone having thought of it first.
  #
  # It is a name roster rather than a check on where each sub was compiled
  # because a name is what collides: these classes are generated from a
  # specification that grows fields without asking, and a field the swagger
  # one day spells `Has` or `New` would quietly take the place of what is
  # here.
  #
  # This holds while nothing under lib/API/Docker/Type/ pulls in an entity
  # role -- API::Docker::Role::Entity::* attaches itself to its classes when
  # the ROLE is loaded, and this file loads only the model. A class that
  # gained ->start or ->remove that way would be reported here by name; that
  # is a deliberate change to the surface and belongs in the roster.
  my @roster = (
    # Moo, imported into the class by API::Docker::Type::_setup_class
    qw( has with extends around before after ),
    # the type vocabulary, imported by the same sub, so that a class body
    # can write `docker target => Str`
    qw( Any Bool Int Num Str ),
    # the two keywords, installed into the class through Package::Stash
    qw( docker docker_extends ),
    # what composing API::Docker::Role::Type leaves behind: its two
    # attributes, all of its methods -- the private ones included, Role::Tiny
    # composes every sub the role has -- and the new, BUILDARGS and DOES that
    # the composition itself generates
    qw( new BUILDARGS DOES
        unknown_fields rejected_fields
        from_data from_json TO_JSON to_json
        docker_attributes docker_attribute_order
        _fits _entity_attribute_index
        _docker_attr_registry _merge_registry
        _docker_attr_order _merge_order _append_order
        _docker_wire_index _invalidate_docker_cache ),
  );
  my %roster = map { ($_ => 1) } @roster;

  # Counted by name rather than collected per class: a leak out of the role
  # or the DSL is on all 201 at once, and `{ croak => 201 }` says that in one
  # line where 201 strings would bury it.
  my (%extra, %absent);
  for my $class (@classes) {
    my $fields = $class->docker_attributes;
    my %have = map { ($_ => 1) }
      Package::Stash->new($class)->list_all_symbols('CODE');
    $extra{$_}++  for grep { !$fields->{$_} && !$roster{$_} } keys %have;
    $absent{$_}++ for grep { !$have{$_} } @roster;
  }
  is_deeply \%extra, {},
    'no generated class answers to a name outside its fields and the roster';
  is_deeply \%absent, {},
    'every generated class answers to the whole roster';
};

done_testing;
