# Shared spec handling for maint/spec-drift-check.pl and maint/spec-to-type.pl.
#
# Loaded with `require`, not `use`: this is a maintenance library, not a
# module of the distribution. It deliberately does not live under lib/ and
# deliberately is not a .pm -- nothing here ships, nothing here is indexed,
# and it carries no $VERSION to go stale, because [@Author::GETTY] rewrites
# only what its :InstallModules finder sees.
#
#   require File::Spec->catfile($FindBin::Bin, 'spec-common.pl');
#
# The two scripts MUST read the spec through this file. They answer
# different questions -- one reports drift, one emits classes -- but they
# have to agree, to the letter, on what the spec says: which definitions are
# classes, what a field's type is, what an inline object's class is called,
# and above all in WHICH ORDER the fields appear. Two text scans that can
# drift apart is a bug nobody would notice until a generated class and the
# checker disagreed about a class that looks fine in both.
package API::Docker::Maint::Spec;
use strict;
use warnings;
use YAML::XS ();

our $PREFIX = 'API::Docker::Type::';

# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

# YAML::XS, not YAML::PP, and not by preference: Docker's published swagger
# is not YAML that YAML::PP 0.41 will parse. Its `example:` blocks are
# multi-line flow maps whose closing brace is indented less than the key
# that opens them (spec/v1.51.yaml line 1364 is the first of twelve), which
# YAML::PP rejects with "Bad indendation in FLOWMAP" while libyaml accepts
# it. The specs stay byte-identical to what Docker publishes -- see
# spec/README.md -- so the parser is what has to give.
#
# libyaml hands back plain hashes, so it loses the order the fields are
# written in. That order is not cosmetic here: a generated class lists its
# attributes in spec order, which is the order a reader of the swagger sees.
# So the text is scanned a second time for the order alone, and the scan is
# then checked against what the parser found, path by path and name by name.
# A scanner that quietly disagreed with the parser is the one failure this
# file exists to make impossible.
sub load {
  my ($path) = @_;
  die "spec-common: no such spec: $path\n" unless -f $path;
  local $YAML::XS::Boolean = 'JSON::PP';
  my $spec = YAML::XS::LoadFile($path);
  my $defs = $spec->{definitions}
    or die "spec-common: no 'definitions' key in $path\n";
  my $order = _scan_order($path);
  _cross_check($defs, $order, $path);
  # The whole document, not just definitions: `paths:` is where the spec says
  # what a definition without a description of its own IS.
  return { definitions => $defs, order => $order, path => $path, document => $spec };
}

# The property names of one schema path, in the order the swagger writes
# them. Paths are dotted and skip the structural keywords: Mount.BindOptions,
# Mount.VolumeOptions.DriverConfig, Resources.Ulimits (an array's items are
# unnamed, so they keep the property's own path), HostConfig (its allOf
# contributes to the definition's own path).
sub ordered_properties {
  my ($spec, $path) = @_;
  return @{ $spec->{order}{$path} // [] };
}

# ---------------------------------------------------------------------------
# The order scan
# ---------------------------------------------------------------------------

sub _content_lines {
  my ($path) = @_;
  open my $fh, '<:encoding(UTF-8)', $path or die "spec-common: cannot read $path: $!\n";
  my @lines = <$fh>;
  close $fh;
  chomp @lines;
  # A sequence item's "- " is two columns of indentation as far as the keys
  # after it are concerned, so flattening it here lets one routine read both
  # `allOf: [ {...}, {...} ]` items as keys of the schema they contribute to.
  # Only allOf is ever descended into, and the other sequences in the spec
  # (enum, required, example) are skipped whole, so this is safe.
  s/\A(\s*)-(\s)/$1 $2/ for @lines;
  return \@lines;
}

sub _indent_of {
  my ($line) = @_;
  my ($ws) = $line =~ /\A(\s*)/;
  return length $ws;
}

sub _is_skippable { return $_[0] =~ /\A\s*(?:#.*)?\z/ }

# The indentation of the first content line at or after $i.
sub _child_indent {
  my ($lines, $i) = @_;
  $i++ while $i < @$lines && _is_skippable($lines->[$i]);
  return $i < @$lines ? _indent_of($lines->[$i]) : undef;
}

sub _skip_block {
  my ($lines, $i, $indent) = @_;
  while ($i < @$lines) {
    if (_is_skippable($lines->[$i])) { $i++; next }
    last if _indent_of($lines->[$i]) <= $indent;
    $i++;
  }
  return $i;
}

sub _scan_order {
  my ($path) = @_;
  my $lines = _content_lines($path);
  my %order;
  my $i = 0;
  $i++ while $i < @$lines && $lines->[$i] !~ /\Adefinitions:\s*\z/;
  die "spec-common: no top-level 'definitions:' in $path\n" if $i >= @$lines;
  $i++;
  my $indent = _child_indent($lines, $i) // 0;
  while ($i < @$lines) {
    if (_is_skippable($lines->[$i])) { $i++; next }
    last if _indent_of($lines->[$i]) < $indent;
    if (_indent_of($lines->[$i]) > $indent) { $i++; next }
    my ($name) = $lines->[$i] =~ /\A\s*([A-Za-z_][\w.\-]*):/;
    unless (defined $name) { $i++; next }
    my $child = _child_indent($lines, $i + 1);
    $i = defined $child && $child > $indent
      ? _scan_schema($lines, $i + 1, $child, $name, \%order)
      : $i + 1;
  }
  return \%order;
}

# Keys of one schema mapping. Only four of them are structure; every other
# key -- description, example, enum, default, format, x-nullable -- is
# skipped whole, block scalars and multi-line flow maps included, so nothing
# inside a description can be mistaken for a field name.
sub _scan_schema {
  my ($lines, $i, $indent, $path, $order) = @_;
  while ($i < @$lines) {
    if (_is_skippable($lines->[$i])) { $i++; next }
    my $here = _indent_of($lines->[$i]);
    return $i if $here < $indent;
    if ($here > $indent) { $i++; next }
    my ($key) = $lines->[$i] =~ /\A\s*([A-Za-z_\$][\w.\-\$]*):/;
    unless (defined $key) { $i++; next }
    my $child = _child_indent($lines, $i + 1);
    my $has_block = defined $child && $child > $indent;
    if (!$has_block) { $i++; next }
    if ($key eq 'properties') {
      $i = _scan_properties($lines, $i + 1, $child, $path, $order);
    }
    elsif ($key eq 'items' || $key eq 'additionalProperties' || $key eq 'allOf') {
      # An array's items, a map's values and an allOf's parts are all
      # unnamed: they contribute to the path they sit in, not to a new one.
      $i = _scan_schema($lines, $i + 1, $child, $path, $order);
    }
    else {
      $i = _skip_block($lines, $i + 1, $indent);
    }
  }
  return $i;
}

sub _scan_properties {
  my ($lines, $i, $indent, $path, $order) = @_;
  while ($i < @$lines) {
    if (_is_skippable($lines->[$i])) { $i++; next }
    my $here = _indent_of($lines->[$i]);
    return $i if $here < $indent;
    if ($here > $indent) { $i++; next }
    my ($name) = $lines->[$i] =~ /\A\s*"?([A-Za-z_\$][\w.\-\$]*)"?:/;
    unless (defined $name) { $i++; next }
    push @{ $order->{$path} }, $name;
    my $child = _child_indent($lines, $i + 1);
    $i = defined $child && $child > $indent
      ? _scan_schema($lines, $i + 1, $child, "$path.$name", $order)
      : $i + 1;
  }
  return $i;
}

# What the parser found, in the same path scheme the scanner uses.
sub _parsed_paths {
  my ($defs) = @_;
  my %seen;
  my $walk;
  $walk = sub {
    my ($schema, $path) = @_;
    return unless ref $schema eq 'HASH';
    if (my $props = $schema->{properties}) {
      $seen{$path}{$_} = 1 for keys %$props;
      $walk->($props->{$_}, "$path.$_") for keys %$props;
    }
    $walk->($schema->{items}, $path) if ref $schema->{items} eq 'HASH';
    $walk->($schema->{additionalProperties}, $path)
      if ref $schema->{additionalProperties} eq 'HASH';
    $walk->($_, $path) for @{ $schema->{allOf} || [] };
  };
  $walk->($defs->{$_}, $_) for keys %$defs;
  return \%seen;
}

sub _cross_check {
  my ($defs, $order, $path) = @_;
  my $parsed = _parsed_paths($defs);
  my @problems;
  for my $p (sort keys %$parsed) {
    my @want = sort keys %{ $parsed->{$p} };
    my @have = sort @{ $order->{$p} // [] };
    push @problems, "  $p: parser has [@want], scan has [@have]"
      if join("\0", @want) ne join("\0", @have);
  }
  for my $p (sort keys %$order) {
    push @problems, "  $p: the scan found a properties block the parser did not"
      unless $parsed->{$p};
    my %seen;
    my @dupes = grep { $seen{$_}++ } @{ $order->{$p} };
    push @problems, "  $p: the scan listed @dupes twice" if @dupes;
  }
  die "spec-common: the field-order scan of $path disagrees with the parser.\n"
    . "This is not a spec problem, it is a bug in _scan_order -- the order it\n"
    . "produces is what generated classes are laid out from, so it stops here\n"
    . "rather than emitting a class with fields in an invented order:\n"
    . join("\n", @problems) . "\n"
    if @problems;
  return;
}

# ---------------------------------------------------------------------------
# The definition model, shared so that the checker and the generator cannot
# disagree about what the spec asks for.
# ---------------------------------------------------------------------------

sub strip_ref { my ($r) = @_; $r =~ s{\A\#/definitions/}{}; return $r }

# The definition a schema is nothing but a wrapper around: a bare $ref, or
# an allOf holding exactly one $ref and nothing else. The second form is
# swagger's way of hanging a description onto a $ref -- Mount.Type and
# MountPoint.Type both do it, and neither is an object reference.
sub single_ref {
  my ($schema) = @_;
  return undef unless ref $schema eq 'HASH';
  return strip_ref($schema->{'$ref'}) if $schema->{'$ref'};
  my $all = $schema->{allOf} or return undef;
  return @$all == 1 && $all->[0]{'$ref'} ? strip_ref($all->[0]{'$ref'}) : undef;
}

# A definition is class-shaped when it has properties of its own, or is an
# allOf that composes something with an inline schema. Everything else -- a
# string with an enum, an array, a bare additionalProperties map -- is not a
# class and must never become one.
sub is_class_schema {
  my ($schema) = @_;
  return 0 unless ref $schema eq 'HASH';
  return 1 if $schema->{properties};
  my $all = $schema->{allOf} or return 0;
  return 0 if @$all == 1 && $all->[0]{'$ref'};
  return 1;
}

# Dotted schema path -> class name. Mount.VolumeOptions.DriverConfig becomes
# API::Docker::Type::Mount::VolumeOptions::DriverConfig. The exceptions file
# overrides the one case this cannot get right on its own: an array of
# inline objects, where the class is named for a single element and
# Resources.Ulimits has to become Resources::Ulimit.
sub class_for_path {
  my ($path, $exc) = @_;
  # A renamed ancestor carries its descendants: once Resources.Ulimits is
  # Resources::Ulimit, anything nested inside it belongs under that name and
  # not under the plural the swagger wrote. The longest matching prefix wins,
  # so a descendant can still be named outright.
  my @parts = split /\./, $path;
  for my $take (reverse 0 .. $#parts) {
    my $prefix = join '.', @parts[0 .. $take];
    my $mapped = $exc->{inline_class_names}{$prefix} or next;
    return join '::', $mapped, @parts[$take + 1 .. $#parts];
  }
  return $PREFIX . join '::', @parts;
}

# The type descriptor string a property's schema calls for, in the same
# vocabulary API::Docker::Type::describe_type produces from the registry.
sub spec_type {
  my ($schema, $path, $defs, $exc) = @_;
  return 'any' unless ref $schema eq 'HASH';
  if (defined(my $ref = single_ref($schema))) {
    my $target = $defs->{$ref} // {};
    return 'object<' . $PREFIX . $ref . '>' if is_class_schema($target);
    return spec_type($target, $ref, $defs, $exc);
  }
  # Keyed on the structural keyword, not on `type`: swagger lets `type` be
  # omitted where `items` or `additionalProperties` already says what the
  # schema is, and v1.51 does exactly that once --
  # ContainerStatsResponse.networks is `additionalProperties: {$ref:
  # ContainerNetworkStats}` with no `type: object` above it. Reading `type`
  # first turned that typed map into an untyped passthrough, which is the
  # quiet half of the mistake this model exists to avoid.
  my $type = $schema->{type} // '';
  return 'array<' . spec_type($schema->{items} // {}, $path, $defs, $exc) . '>'
    if is_array_schema($schema);
  my $ap = $schema->{additionalProperties};
  return 'hash<' . spec_type($ap, $path, $defs, $exc) . '>' if ref $ap eq 'HASH';
  return 'object<' . class_for_path($path, $exc) . '>' if $schema->{properties};
  return 'any' if $type eq 'object';
  return 'str'  if $type eq 'string';
  return 'int'  if $type eq 'integer';
  return 'num'  if $type eq 'number';
  return 'bool' if $type eq 'boolean';
  return 'any';
}

# The schema that becomes an inline class for this property, if any: the
# property's own schema when it is an object with properties, or its items
# when it is an array of such objects.
# An array whether or not the swagger bothered to say `type: array`.
sub is_array_schema {
  my ($schema) = @_;
  return 0 unless ref $schema eq 'HASH';
  return 1 if ($schema->{type} // '') eq 'array';
  return ref $schema->{items} eq 'HASH' ? 1 : 0;
}

sub inline_object_schema {
  my ($schema) = @_;
  return undef unless ref $schema eq 'HASH';
  return undef if single_ref($schema);
  return inline_object_schema($schema->{items}) if is_array_schema($schema);
  return $schema if $schema->{properties};
  return undef;
}

# Every class the spec calls for, keyed by class name:
#   { path, extends => [class, ...], order => [ Wire, ... ],
#     props => { Wire => { schema, path } } }
# props is the FLATTENED set -- an allOf's $ref contributes its fields too,
# so a class is compared against everything it must be able to carry --
# while order lists only what the class DECLARES, parents first.
sub expected_model {
  my ($spec, $exc) = @_;
  my $defs = $spec->{definitions};
  my %model;

  my (%own, %own_order, %parents);
  for my $name (sort keys %$defs) {
    next unless is_class_schema($defs->{$name});
    my $schema = $defs->{$name};
    my @refs;
    my @inline = ($schema);
    if (my $all = $schema->{allOf}) {
      @inline = ();
      for my $part (@$all) {
        if ($part->{'$ref'}) { push @refs, strip_ref($part->{'$ref'}) }
        else                 { push @inline, $part }
      }
    }
    my %props;
    for my $part (@inline) {
      $props{$_} = { schema => $part->{properties}{$_}, path => $name }
        for keys %{ $part->{properties} // {} };
    }
    $own{$name}       = \%props;
    $own_order{$name} = [ ordered_properties($spec, $name) ];
    $parents{$name}   = \@refs;
  }

  my (%flat, %flat_order);
  my ($flatten, $flatten_order);
  $flatten = sub {
    my ($name, $seen) = @_;
    return $flat{$name} if $flat{$name};
    die "spec-common: allOf cycle at $name\n" if $seen->{$name}++;
    my %props;
    for my $parent (@{ $parents{$name} // [] }) {
      next unless $own{$parent};
      my $up = $flatten->($parent, $seen);
      $props{$_} = $up->{$_} for keys %$up;
    }
    $props{$_} = $own{$name}{$_} for keys %{ $own{$name} };
    return $flat{$name} = \%props;
  };
  $flatten_order = sub {
    my ($name, $seen) = @_;
    return $flat_order{$name} if $flat_order{$name};
    die "spec-common: allOf cycle at $name\n" if $seen->{$name}++;
    my (@order, %have);
    for my $parent (@{ $parents{$name} // [] }) {
      next unless $own{$parent};
      for my $wire (@{ $flatten_order->($parent, $seen) }) {
        push @order, $wire unless $have{$wire}++;
      }
    }
    for my $wire (@{ $own_order{$name} }) {
      push @order, $wire unless $have{$wire}++;
    }
    return $flat_order{$name} = \@order;
  };

  for my $name (sort keys %own) {
    $model{ $PREFIX . $name } = {
      path       => $name,
      extends    => [ map { $PREFIX . $_ } grep { $own{$_} } @{ $parents{$name} } ],
      props      => $flatten->($name, {}),
      order      => [ @{ $own_order{$name} } ],
      flat_order => [ @{ $flatten_order->($name, {}) } ],
    };
  }

  # Inline classes are named for the definition that DECLARES them, so they
  # are collected from the own properties, never from the flattened set.
  my $add_inline;
  $add_inline = sub {
    my ($path) = @_;
    for my $name (ordered_properties($spec, $path)) {
      my $prop = _schema_at($spec, $path, $name) or next;
      my $inner = inline_object_schema($prop) or next;
      my $inner_path  = "$path.$name";
      my $inner_class = class_for_path($inner_path, $exc);
      $model{$inner_class} //= {
        path => $inner_path, extends => [], props => {},
        order => [ ordered_properties($spec, $inner_path) ],
      };
      $model{$inner_class}{flat_order} //= $model{$inner_class}{order};
      $model{$inner_class}{props}{$_} = { schema => $inner->{properties}{$_}, path => $inner_path }
        for keys %{ $inner->{properties} // {} };
      $add_inline->($inner_path);
    }
  };
  $add_inline->($_) for sort keys %own;

  # A definition that is not class-shaped can still carry an inline object:
  # GenericResources is `type: array` whose items are an object with two
  # properties, so a field typed `$ref: GenericResources` is an array of
  # something, and that something needs a class. Registered under the
  # definition's own path, which is what spec_type names, and marked as
  # coming from items so the generator asks for a name the way it does for
  # any other array element.
  for my $name (sort keys %$defs) {
    next if $own{$name};
    my $inner = inline_object_schema($defs->{$name}) or next;
    my $class = class_for_path($name, $exc);
    $model{$class} //= {
      path => $name, extends => [], props => {},
      order => [ ordered_properties($spec, $name) ],
      from_items => (($defs->{$name}{type} // '') eq 'array' ? 1 : 0),
    };
    $model{$class}{flat_order} //= $model{$class}{order};
    $model{$class}{props}{$_} = { schema => $inner->{properties}{$_}, path => $name }
      for keys %{ $inner->{properties} // {} };
    $add_inline->($name);
  }
  return \%model;
}

# The schema of one property at a dotted path, following the same structural
# keywords the order scan follows.
sub _schema_at {
  my ($spec, $path, $name) = @_;
  my @parts = split /\./, $path;
  my $schema = $spec->{definitions}{ shift @parts };
  for my $part (@parts) {
    $schema = _properties_of($schema)->{$part} or return undef;
  }
  return _properties_of($schema)->{$name};
}

sub _properties_of {
  my ($schema) = @_;
  return {} unless ref $schema eq 'HASH';
  my %props = %{ $schema->{properties} // {} };
  for my $part (@{ $schema->{allOf} || [] }) {
    next if $part->{'$ref'};
    %props = (%props, %{ $part->{properties} // {} });
  }
  if (ref $schema->{items} eq 'HASH') {
    %props = (%props, %{ _properties_of($schema->{items}) });
  }
  if (ref $schema->{additionalProperties} eq 'HASH') {
    %props = (%props, %{ _properties_of($schema->{additionalProperties}) });
  }
  return \%props;
}

# ---------------------------------------------------------------------------
# Where a definition is used
#
# 34 of the 132 definitions in v1.51 carry neither a description nor a title,
# so there is nothing in the definition itself to say what the type IS. The
# spec still says it, twice over, just not in that field: `paths:` names the
# request or response a definition is the schema of, and the other
# definitions name the fields that hold it. Both are measurements of the same
# checked-in file, as verifiable as a description field, which is why
# maint/spec-to-type.pl is allowed to write a sentence out of them.
# ---------------------------------------------------------------------------

# Definition name -> [ { method, path, kind, code, via }, ... ], sorted.
#   kind  'response' or 'request' -- a body parameter is input, not output,
#         and a generated sentence has to say so
#   via   'direct', 'array' (the definition is ONE ENTRY of the answer) or
#         'map' (one value of it)
sub path_index {
  my ($spec) = @_;
  return $spec->{_path_index} if $spec->{_path_index};
  my %index;
  my $paths = $spec->{document}{paths} // {};
  # Recursive, because a definition is not always the whole body: the exec
  # inspect response is an inline object with a ProcessConfig field, and the
  # network create body an inline object with an IPAM field. `field` is the
  # dotted path inside the body, empty when the definition IS the body.
  my $record;
  $record = sub {
    my ($schema, $site, $field) = @_;
    return unless ref $schema eq 'HASH';
    if (my $ref = $schema->{'$ref'}) {
      push @{ $index{ strip_ref($ref) } }, { %$site, via => 'direct', field => $field };
      return;
    }
    for my $part (@{ $schema->{allOf} || [] }) { $record->($part, $site, $field) }
    if (ref $schema->{items} eq 'HASH') {
      my $items = $schema->{items};
      if (my $ref = $items->{'$ref'}) {
        push @{ $index{ strip_ref($ref) } }, { %$site, via => 'array', field => $field };
      }
      else { $record->($items, $site, $field) }
    }
    if (ref $schema->{additionalProperties} eq 'HASH') {
      my $ap = $schema->{additionalProperties};
      if (my $ref = $ap->{'$ref'}) {
        push @{ $index{ strip_ref($ref) } }, { %$site, via => 'map', field => $field };
      }
      else { $record->($ap, $site, $field) }
    }
    for my $name (sort keys %{ $schema->{properties} // {} }) {
      $record->($schema->{properties}{$name}, $site,
        (length $field ? "$field.$name" : $name));
    }
  };
  for my $path (sort keys %$paths) {
    my $item = $paths->{$path};
    next unless ref $item eq 'HASH';
    for my $method (sort keys %$item) {
      next unless $method =~ /\A(?:get|put|post|delete|head|patch)\z/;
      my $op = $item->{$method};
      next unless ref $op eq 'HASH';
      my $site = { method => uc $method, path => $path };
      for my $code (sort keys %{ $op->{responses} // {} }) {
        $record->($op->{responses}{$code}{schema},
          { %$site, kind => 'response', code => $code }, '');
      }
      for my $param (@{ $op->{parameters} // [] }, @{ $item->{parameters} // [] }) {
        next unless ref $param eq 'HASH' && ($param->{in} // '') eq 'body';
        $record->($param->{schema}, { %$site, kind => 'request' }, '');
      }
    }
  }
  for my $name (keys %index) {
    my %seen;
    $index{$name} = [
      grep { !$seen{ join '|', map { $_ // '' } @{$_}{qw( method path kind code via field )} }++ }
      # The body itself before a field of it, a response before a request,
      # then by status, path and method: the first entry is what a generated
      # abstract names, so the order has to be total and stable.
      sort {
        (length($a->{field}) <=> length($b->{field}) && (length($a->{field}) ? 1 : -1))
          || $a->{kind} cmp $b->{kind}
          || ($a->{code} // '') cmp ($b->{code} // '')
          || $a->{path} cmp $b->{path}
          || $a->{method} cmp $b->{method}
          || $a->{field} cmp $b->{field}
      } @{ $index{$name} }
    ];
  }
  return $spec->{_path_index} = \%index;
}

# Definition name -> [ { field, via }, ... ] -- the dotted schema paths of
# every field in every other definition that holds one. `field` is named the
# way the swagger names it (HostConfig.Mounts), which is the same notation
# the drift checker prints.
sub reference_index {
  my ($spec) = @_;
  return $spec->{_reference_index} if $spec->{_reference_index};
  my $defs = $spec->{definitions};
  my %index;
  my $walk;
  $walk = sub {
    my ($schema, $field) = @_;
    return unless ref $schema eq 'HASH';
    if (my $ref = $schema->{'$ref'}) {
      push @{ $index{ strip_ref($ref) } }, { field => $field, via => 'direct' };
      return;
    }
    for my $part (@{ $schema->{allOf} || [] }) { $walk->($part, $field) }
    if (ref $schema->{items} eq 'HASH') {
      my $items = $schema->{items};
      if (my $ref = $items->{'$ref'}) {
        push @{ $index{ strip_ref($ref) } }, { field => $field, via => 'array' };
      }
      else { $walk->($items, $field) }
    }
    if (ref $schema->{additionalProperties} eq 'HASH') {
      my $ap = $schema->{additionalProperties};
      if (my $ref = $ap->{'$ref'}) {
        push @{ $index{ strip_ref($ref) } }, { field => $field, via => 'map' };
      }
      else { $walk->($ap, $field) }
    }
    for my $name (sort keys %{ $schema->{properties} // {} }) {
      $walk->($schema->{properties}{$name}, ($field ? "$field.$name" : $name));
    }
  };
  for my $name (sort keys %$defs) {
    my $schema = $defs->{$name};
    # allOf's own $ref is inheritance, not a field, and saying "referenced by
    # HostConfig" about Resources would describe the wrong relationship.
    my @parts = $schema->{allOf} ? grep { !$_->{'$ref'} } @{ $schema->{allOf} } : ($schema);
    $walk->($_, $name) for @parts;
  }
  for my $name (keys %index) {
    my %seen;
    $index{$name} = [
      grep { !$seen{ $_->{field} }++ }
      sort { $a->{field} cmp $b->{field} } @{ $index{$name} }
    ];
  }
  return $spec->{_reference_index} = \%index;
}

# Definitions that are deliberately not classes, for a report's benefit.
sub non_class_definitions {
  my ($spec) = @_;
  my $defs = $spec->{definitions};
  my %out;
  for my $name (sort keys %$defs) {
    next if is_class_schema($defs->{$name});
    $out{$name} = $defs->{$name}{type} // 'allOf-of-one-$ref';
  }
  return \%out;
}

# ---------------------------------------------------------------------------
# The exceptions file
# ---------------------------------------------------------------------------

sub load_exceptions {
  my ($path) = @_;
  die "spec-common: exceptions file not found: $path\n" unless -f $path;
  local $YAML::XS::Boolean = 'JSON::PP';
  my $data = YAML::XS::LoadFile($path) // {};
  $data->{inline_class_names}     //= {};
  $data->{ignore_missing_classes} //= [];
  $data->{ignore_missing_fields}  //= [];
  $data->{ignore_extra_fields}    //= [];
  $data->{ignore_type_mismatch}   //= [];
  $data->{ignore_since}           //= [];
  $data->{perl_only}              //= [];
  return $data;
}

1;
