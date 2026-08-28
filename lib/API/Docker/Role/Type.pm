package API::Docker::Role::Type;
# ABSTRACT: Instance behaviour of a generated API::Docker::Type class
our $VERSION = '0.004';
use Moo::Role;
use Carp qw( croak );
use JSON::MaybeXS ();
use Scalar::Util qw( blessed );

=head1 SYNOPSIS

    # composed automatically by `use API::Docker::Type;`
    my $hc = API::Docker::Type::HostConfig->from_data($from_the_daemon);
    my $wire = $hc->TO_JSON;            # CamelCase keys, JSON booleans
    my $bytes = $hc->to_json;

=head1 DESCRIPTION

Every class under C<API::Docker::Type::*> composes this role; it is applied
by L<API::Docker::Type>'s C<import>, so a generated class never names it.

The role reads the attribute registry L<API::Docker::Type> writes -- it never
walks the object's own keys. A field that is an attribute but not in the
registry is invisible here, which is exactly what
C<maint/spec-drift-check.pl> exists to catch.

=cut

# The merged views are rebuilt whenever API::Docker::Type registers a new
# attribute (it calls _invalidate_docker_cache), so they can be cached. Keyed
# by class name, one entry each.
my %ATTR_CACHE;    # class -> { perl_name => info }
my %ORDER_CACHE;   # class -> [ perl_name, ... ]
my %WIRE_CACHE;    # class -> { wire_name => perl_name }
my %ENTITY_CACHE;  # class -> { perl_name => 1 }  (not daemon fields)

=attr unknown_fields

A HashRef of everything that reached this object under a name the model does
not know, kept under the name it arrived with and handed back out by
L</TO_JSON> unchanged.

This is the whole reason a caller whose engine is newer than the swagger this
model was generated from still gets their field to the daemon. Translating
what we know and B<forwarding the rest verbatim> is worth more to this
distribution than a tidy model: a field the caller set must never be dropped
because we have not heard of it.

=cut

has unknown_fields => (
  is      => 'ro',
  default => sub { {} },
);

# Constructor-side name resolution, and the only place unknown fields are
# collected. A key is taken as a Perl attribute name first, then as a wire
# name, and is otherwise kept verbatim -- so ->new, ->from_data and the
# hashref coercion of a nested field all behave identically.
#
# Idempotent on purpose: where one generated class extends another (the
# `allOf` shape, see API::Docker::Type) the role is composed into both, so
# this modifier runs twice on the same arguments. The second pass sees every
# key already resolved and merges an empty set into unknown_fields.
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my $known = $class->_docker_attr_registry;
  my $wire  = $class->_docker_wire_index;
  my $mine  = $class->_entity_attribute_index;
  my %unknown = %{ delete($args->{unknown_fields}) || {} };
  my %out;
  for my $key (keys %$args) {
    if ($known->{$key})              { $out{$key} = $args->{$key} }
    elsif (defined $wire->{$key})    { $out{ $wire->{$key} } = $args->{$key} }
    elsif ($mine->{$key})            { $out{$key} = $args->{$key} }
    else                             { $unknown{$key} = $args->{$key} }
  }
  $out{unknown_fields} = \%unknown;
  return \%out;
};

=method from_data

    my $mount = API::Docker::Type::Mount->from_data($hashref);

Builds an object from a decoded daemon response. Keys are matched against the
registry's wire names first and the Perl attribute names second, so both
spellings work; nested objects, arrays of objects and hashes of objects are
inflated through the same attribute coercions C<new> uses. Anything else is
kept in L</unknown_fields>.

=cut

sub from_data {
  my ($class, $data) = @_;
  $class = ref($class) if ref($class);
  croak __PACKAGE__ . '->from_data needs a HashRef'
    unless ref $data eq 'HASH';
  return $class->new(%$data);
}

=method from_json

    my $mount = API::Docker::Type::Mount->from_json($bytes);

L</from_data> on a JSON document. The argument is a UTF-8 encoded byte
string, exactly what L</to_json> produces.

=cut

sub from_json {
  my ($class, $json) = @_;
  return $class->from_data(JSON::MaybeXS->new(utf8 => 1)->decode($json));
}

=method TO_JSON

    my $struct = $host_config->TO_JSON;

The structure the daemon expects: registry wire names as keys, JSON booleans
for C<Bool>, nested objects serialised by their own C<TO_JSON>.

An attribute that was never set is B<omitted>, not sent as null -- Docker
tells an absent flag apart from a false one, and so does this. The contents
of L</unknown_fields> are written first and a known field wins over them.

=cut

sub TO_JSON {
  my ($self) = @_;
  my %out = %{ $self->unknown_fields };
  my $reg = $self->_docker_attr_registry;
  for my $attr (@{ $self->_docker_attr_order }) {
    my $value = $self->$attr;
    next unless defined $value;
    $out{ $reg->{$attr}{wire} }
      = API::Docker::Type::_encode_value($reg->{$attr}{type}, $value);
  }
  return \%out;
}

=method to_json

    my $bytes = $host_config->to_json;

L</TO_JSON> encoded as a UTF-8 byte string, canonical so two equal objects
encode to the same bytes.

=cut

sub to_json {
  my ($self) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1)
    ->encode($self->TO_JSON);
}

=method docker_attributes

    my $info = API::Docker::Type::HostConfig->docker_attributes;

The class's merged attribute registry as a HashRef keyed by Perl attribute
name. Each entry carries C<wire>, C<type> (a type descriptor, see
L<API::Docker::Type>), C<since>, C<required> and C<enum>. This is what
C<maint/spec-drift-check.pl> reads.

=cut

sub docker_attributes { return $_[0]->_docker_attr_registry }

=method docker_attribute_order

    my $names = API::Docker::Type::HostConfig->docker_attribute_order;

The Perl attribute names in declaration order, inherited ones first -- which
is the order the fields appear in the swagger.

=cut

sub docker_attribute_order { return $_[0]->_docker_attr_order }

# --- attributes that are not the daemon's ----------------------------------
#
# API::Docker::Role::Entity puts `client` on a generated class so the
# convenience methods have something to delegate through. It arrives at the
# same constructor as the daemon's fields, and without being named here it is
# neither a registry entry nor a wire name, so BUILDARGS would file it under
# unknown_fields -- where TO_JSON would faithfully offer the client object to
# the engine and JSON::MaybeXS would die trying to encode it. A class that
# composes such a role answers _entity_attributes with their names.

sub _entity_attribute_index {
  my $class = ref($_[0]) || $_[0];
  return $ENTITY_CACHE{$class} //= do {
    my %mine = $class->can('_entity_attributes')
      ? (map { ($_ => 1) } $class->_entity_attributes)
      : ();
    my $reg  = _docker_attr_registry($class);
    my $wire = _docker_wire_index($class);
    # Both sets reach the same constructor, so a name in both is an ambiguity
    # nobody can resolve at runtime -- say so instead of picking one.
    for my $name (sort keys %mine) {
      croak __PACKAGE__ . ": $class has '$name' as an entity attribute and as "
        . 'a daemon field; one of the two has to be renamed'
        if $reg->{$name} || defined $wire->{$name};
    }
    \%mine;
  };
}

# --- merged views over @ISA ------------------------------------------------
#
# A generated class that resolves an `allOf` inherits its parent's fields
# (see API::Docker::Type), so every lookup below is the class's own registry
# entry merged with its ancestors'. Nearest declaration wins.

sub _docker_attr_registry {
  my $class = ref($_[0]) || $_[0];
  return $ATTR_CACHE{$class} //= _merge_registry($class);
}

sub _merge_registry {
  my ($class) = @_;
  my %info = %{ $API::Docker::Type::REGISTRY{$class} // {} };
  no strict 'refs';
  for my $parent (@{"${class}::ISA"}) {
    my $up = _merge_registry($parent);
    $info{$_} //= $up->{$_} for keys %$up;
  }
  return \%info;
}

sub _docker_attr_order {
  my $class = ref($_[0]) || $_[0];
  return $ORDER_CACHE{$class} //= _merge_order($class);
}

sub _merge_order {
  my ($class) = @_;
  my (@order, %seen);
  _append_order($class, \@order, \%seen);
  return \@order;
}

sub _append_order {
  my ($class, $order, $seen) = @_;
  no strict 'refs';
  # Parents first: the swagger lists the inherited `$ref` ahead of the
  # class's own properties, and this keeps TO_JSON in that order.
  _append_order($_, $order, $seen) for @{"${class}::ISA"};
  for my $attr (@{"${class}::_docker_attr_order"}) {
    next if $seen->{$attr}++;
    push @$order, $attr;
  }
  return;
}

sub _docker_wire_index {
  my $class = ref($_[0]) || $_[0];
  return $WIRE_CACHE{$class} //= do {
    my $reg = _docker_attr_registry($class);
    +{ map { ($reg->{$_}{wire} => $_) } keys %$reg };
  };
}

# Called by API::Docker::Type after every registration: a merged view
# computed before a parent gained an attribute must not survive.
sub _invalidate_docker_cache {
  my ($class) = @_;
  my %sweep;
  @sweep{ keys %ATTR_CACHE, keys %ORDER_CACHE, keys %WIRE_CACHE,
          keys %ENTITY_CACHE } = ();
  for my $cached (keys %sweep) {
    next unless $cached eq $class || $cached->isa($class);
    delete $ATTR_CACHE{$cached};
    delete $ORDER_CACHE{$cached};
    delete $WIRE_CACHE{$cached};
    delete $ENTITY_CACHE{$cached};
  }
  delete $ATTR_CACHE{$class};
  delete $ORDER_CACHE{$class};
  delete $WIRE_CACHE{$class};
  delete $ENTITY_CACHE{$class};
  return;
}

1;
