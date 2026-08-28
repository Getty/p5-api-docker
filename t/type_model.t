use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec;
use FindBin;

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

done_testing;
