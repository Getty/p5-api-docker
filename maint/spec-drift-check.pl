#!/usr/bin/env perl
# Drift checker for the generated Docker type model of API::Docker.
#
# Every class under lib/API/Docker/Type/ is written from Docker's published
# swagger, which is checked into spec/ -- not from a running daemon. This
# script is what keeps that claim true. Two modes:
#
#   Coverage mode (default): diffs one spec/*.yaml against what lib/ ships,
#   definition by definition, field by field, reading the attribute registry
#   the `docker` DSL writes (API::Docker::Type). It reports classes that do
#   not exist, fields that are missing or extra, type mismatches, `allOf`
#   inheritance that was not declared, and -- with --baseline -- `since`
#   annotations that do not match the specs they claim to come from.
#
#   Compare mode (--from/--to): diffs two specs directly against each other,
#   with no reference to lib/ at all. The swagger carries no per-field
#   version information whatsoever, so this is the only way a `since` value
#   can be derived: v1.41 -> v1.44 -> v1.51.
#
# This is a report generator. It never writes to lib/, never touches the
# karr board, and never edits the exceptions file.
#
# Usage:
#   maint/spec-drift-check.pl [--spec spec/v1.51.yaml] [--only REGEX]
#                             [--baseline spec/v1.41.yaml --baseline ...]
#                             [--exceptions PATH] [--lib PATH]
#                             [--format text|json] [--output PATH] [--verbose]
#
#   maint/spec-drift-check.pl --from spec/v1.41.yaml --to spec/v1.51.yaml
#
# Examples:
#   maint/spec-drift-check.pl
#     Coverage against spec/v1.51.yaml, the newest spec checked in.
#
#   maint/spec-drift-check.pl --only '^API::Docker::Type::(Mount|Port|HostConfig)'
#     The same, narrowed to one branch of the model.
#
#   maint/spec-drift-check.pl --baseline spec/v1.41.yaml --baseline spec/v1.44.yaml
#     Coverage, plus a check that every `since` matches the oldest spec the
#     field actually appears in.
#
# No network access: the specs are in the repository, exactly as Docker
# publishes them (curl the URL in spec/README and diff if you doubt it).
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Find;
use File::Spec;
use Getopt::Long qw( GetOptions );
use JSON::PP;

# YAML::XS, not YAML::PP, and not by preference: Docker's published swagger
# is not YAML that YAML::PP 0.41 will parse. Its `example:` blocks are
# multi-line flow maps whose closing brace is indented less than the key
# that opens them (spec/v1.51.yaml line 1364, ContainerConfig.ExposedPorts,
# and eleven more places), which YAML::PP rejects with
#   Bad indendation in FLOWMAP ... Line: 1367, Column: 9
# while libyaml accepts it. Switching this back to the purer YAML::PP kills
# the checker on a file Docker ships as it is -- and the specs stay
# byte-identical to what Docker publishes, so the parser is what has to
# give. Both are develop-only dependencies; nothing under lib/ loads YAML.
use YAML::XS ();

my $DIST_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $PREFIX    = 'API::Docker::Type::';

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
  my ($exit_code) = @_;
  print <<"USAGE";
Usage:
  $0 [--spec PATH] [options]                  # coverage mode (default)
  $0 --from PATH --to PATH                    # compare mode

Coverage mode options:
  --spec PATH         Spec to check against (default: DIST/spec/v1.51.yaml)
  --baseline PATH     Older spec, repeatable, oldest first. Enables the
                       `since` check: an attribute's since must name the
                       oldest of these specs the field appears in.
  --only REGEX        Only report classes whose name matches

Compare mode options:
  --from PATH         Baseline spec (required to enable compare mode)
  --to PATH           Target spec (default: DIST/spec/v1.51.yaml)

Common options:
  --exceptions PATH   Exceptions file (default: maint/spec-drift-exceptions.yaml)
  --lib PATH          lib/ to load the model from (default: DIST/lib)
  --format text|json  Report format (default: text)
  --output PATH       Also write the report to this file
  --verbose           Also list what the exceptions file suppressed
  --help              This message
USAGE
  exit($exit_code // 0);
}

sub parse_args {
  my %opt = (
    exceptions => File::Spec->catfile($FindBin::Bin, 'spec-drift-exceptions.yaml'),
    lib        => File::Spec->catdir($DIST_ROOT, 'lib'),
    format     => 'text',
    baseline   => [],
  );
  GetOptions(\%opt,
    'spec=s', 'from=s', 'to=s', 'baseline=s@', 'only=s',
    'exceptions=s', 'lib=s', 'format=s', 'output=s', 'verbose', 'help|h',
  ) or usage(1);
  usage(0) if $opt{help};
  die "spec-drift-check: --format must be 'text' or 'json'\n"
    if $opt{format} !~ /\A(?:text|json)\z/;
  $opt{spec} //= File::Spec->catfile($DIST_ROOT, 'spec', 'v1.51.yaml');
  $opt{to}   //= File::Spec->catfile($DIST_ROOT, 'spec', 'v1.51.yaml');
  return \%opt;
}

# ---------------------------------------------------------------------------
# Spec loading and the definition model
# ---------------------------------------------------------------------------

sub load_spec {
  my ($path) = @_;
  die "spec-drift-check: no such spec: $path\n" unless -f $path;
  local $YAML::XS::Boolean = 'JSON::PP';
  my $spec = YAML::XS::LoadFile($path);
  my $defs = $spec->{definitions}
    or die "spec-drift-check: no 'definitions' key in $path\n";
  my $label = File::Spec->abs2rel($path, $DIST_ROOT);
  return ($defs, $label);
}

sub strip_ref { my ($r) = @_; $r =~ s{\A\#/definitions/}{}; return $r }

# The definition a schema is nothing but a wrapper around: a bare $ref, or an
# allOf holding exactly one $ref and nothing else. The second form is
# swagger's way of hanging a description onto a $ref -- Mount.Type and
# MountPoint.Type both do it, and neither is an object reference.
sub single_ref {
  my ($schema) = @_;
  return strip_ref($schema->{'$ref'}) if $schema->{'$ref'};
  my $all = $schema->{allOf} or return undef;
  return @$all == 1 && $all->[0]{'$ref'} ? strip_ref($all->[0]{'$ref'}) : undef;
}

# A definition is class-shaped when it has properties of its own, or is an
# allOf that composes something with an inline schema. Everything else --
# a string with an enum, an array, a bare additionalProperties map -- is not
# a class and must never become one.
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
# overrides the one case this does not get right on its own: an array of
# inline objects, where the class is named for a single element and
# Resources.Ulimits has to become Resources::Ulimit.
sub class_for_path {
  my ($path, $exc) = @_;
  return $exc->{inline_class_names}{$path} if $exc->{inline_class_names}{$path};
  (my $class = $path) =~ s/\./::/g;
  return $PREFIX . $class;
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
  my $type = $schema->{type} // '';
  return 'array<' . spec_type($schema->{items} // {}, $path, $defs, $exc) . '>'
    if $type eq 'array';
  if ($type eq 'object') {
    my $ap = $schema->{additionalProperties};
    return 'hash<' . spec_type($ap, $path, $defs, $exc) . '>' if ref $ap eq 'HASH';
    return 'object<' . class_for_path($path, $exc) . '>' if $schema->{properties};
    return 'any';
  }
  return 'str'  if $type eq 'string';
  return 'int'  if $type eq 'integer';
  return 'num'  if $type eq 'number';
  return 'bool' if $type eq 'boolean';
  return 'any';
}

# The schema that becomes an inline class for this property, if any: the
# property's own schema when it is an object with properties, or its items
# when it is an array of such objects.
sub inline_object_schema {
  my ($schema) = @_;
  return undef unless ref $schema eq 'HASH';
  return undef if single_ref($schema);
  return $schema if ($schema->{type} // '') eq 'object' && $schema->{properties};
  return $schema if !$schema->{type} && $schema->{properties};
  if (($schema->{type} // '') eq 'array') {
    my $items = $schema->{items};
    return inline_object_schema($items) if ref $items eq 'HASH';
  }
  return undef;
}

# Every class the spec calls for, keyed by class name:
#   { path, extends => [class, ...], props => { Wire => { schema, path } } }
# props is the FLATTENED set -- an allOf's $ref contributes its fields too,
# so a class is compared against everything it must be able to carry.
sub expected_model {
  my ($defs, $exc) = @_;
  my %model;

  my $add_inline;
  $add_inline = sub {
    my ($class, $path, $props) = @_;
    for my $name (sort keys %$props) {
      my $inner = inline_object_schema($props->{$name}) or next;
      my $inner_path  = "$path.$name";
      my $inner_class = class_for_path($inner_path, $exc);
      $model{$inner_class} //= { path => $inner_path, extends => [], props => {} };
      $model{$inner_class}{props}{$_} = { schema => $inner->{properties}{$_}, path => $inner_path }
        for keys %{ $inner->{properties} // {} };
      $add_inline->($inner_class, $inner_path, $inner->{properties} // {});
    }
  };

  # Own (non-inherited) properties of a definition, with the path each was
  # declared at -- an inherited Ulimits keeps the path Resources.Ulimits, so
  # it still resolves to Resources::Ulimit and not HostConfig::Ulimit.
  my (%own, %parents);
  for my $name (sort keys %$defs) {
    next unless is_class_schema($defs->{$name});
    my $schema = $defs->{$name};
    my (@refs, @inline);
    if (my $all = $schema->{allOf}) {
      for my $part (@$all) {
        if ($part->{'$ref'}) { push @refs, strip_ref($part->{'$ref'}) }
        else                 { push @inline, $part }
      }
    }
    else { @inline = ($schema) }
    my %props;
    for my $part (@inline) {
      $props{$_} = { schema => $part->{properties}{$_}, path => $name }
        for keys %{ $part->{properties} // {} };
    }
    $own{$name}     = \%props;
    $parents{$name} = \@refs;
  }

  my %flat;
  my $flatten;
  $flatten = sub {
    my ($name, $seen) = @_;
    return $flat{$name} if $flat{$name};
    die "spec-drift-check: allOf cycle at $name\n" if $seen->{$name}++;
    my %props;
    for my $parent (@{ $parents{$name} // [] }) {
      next unless $own{$parent};
      my $up = $flatten->($parent, $seen);
      $props{$_} = $up->{$_} for keys %$up;
    }
    my $mine = $own{$name};
    $props{$_} = $mine->{$_} for keys %$mine;
    return $flat{$name} = \%props;
  };

  for my $name (sort keys %own) {
    my $class = $PREFIX . $name;
    $model{$class} = {
      path    => $name,
      extends => [ map { $PREFIX . $_ } grep { $own{$_} } @{ $parents{$name} } ],
      props   => $flatten->($name, {}),
    };
  }
  # Inline classes are named for the definition that DECLARES them, so they
  # are collected from the own properties, never from the flattened set.
  for my $name (sort keys %own) {
    $add_inline->($PREFIX . $name, $name,
      { map { ($_ => $own{$name}{$_}{schema}) } keys %{ $own{$name} } });
  }
  return \%model;
}

# Definitions that are deliberately not classes, for the report's benefit.
sub non_class_definitions {
  my ($defs) = @_;
  my %out;
  for my $name (sort keys %$defs) {
    next if is_class_schema($defs->{$name});
    $out{$name} = $defs->{$name}{type} // 'allOf-of-one-$ref';
  }
  return \%out;
}

# ---------------------------------------------------------------------------
# The shipped model
# ---------------------------------------------------------------------------

sub load_model {
  my ($lib_dir) = @_;
  die "spec-drift-check: lib dir not found: $lib_dir\n" unless -d $lib_dir;
  unshift @INC, $lib_dir unless grep { $_ eq $lib_dir } @INC;
  my $root = File::Spec->catdir($lib_dir, 'API', 'Docker', 'Type');
  my @paths;
  find({ wanted => sub { push @paths, $File::Find::name if /\.pm\z/ }, no_chdir => 1 }, $root)
    if -d $root;
  my %shipped;
  for my $path (sort @paths) {
    my $rel = File::Spec->abs2rel($path, $lib_dir);
    (my $module = $rel) =~ s{[\\/]}{::}g;
    $module =~ s/\.pm\z//;
    $rel =~ s{\\}{/}g;
    eval { require $rel; 1 } or do {
      warn "spec-drift-check: failed to load $module: $@";
      next;
    };
    $shipped{$module} = $module->docker_attributes;
  }
  return \%shipped;
}

# ---------------------------------------------------------------------------
# Exceptions file
# ---------------------------------------------------------------------------

sub load_exceptions {
  my ($path) = @_;
  die "spec-drift-check: exceptions file not found: $path\n" unless -f $path;
  local $YAML::XS::Boolean = 'JSON::PP';
  my $data = YAML::XS::LoadFile($path) // {};
  $data->{inline_class_names}   //= {};
  $data->{ignore_missing_classes} //= [];
  $data->{ignore_missing_fields}  //= [];
  $data->{ignore_extra_fields}    //= [];
  $data->{ignore_type_mismatch}   //= [];
  $data->{ignore_since}           //= [];
  $data->{perl_only}              //= [];
  return $data;
}

sub prefix_match {
  my ($name, $entries) = @_;
  for my $entry (@$entries) {
    my $prefix = ref $entry eq 'HASH' ? $entry->{prefix} : $entry;
    next unless defined $prefix && length $prefix;
    return (1, ref $entry eq 'HASH' ? $entry->{reason} : undef)
      if substr($name, 0, length $prefix) eq $prefix;
  }
  return (0, undef);
}

sub field_ignored {
  my ($class, $field, $entries) = @_;
  for my $entry (@$entries) {
    next unless ref $entry eq 'HASH';
    next unless ($entry->{class} // '') eq $class && ($entry->{field} // '') eq $field;
    return (1, $entry->{reason});
  }
  return (0, undef);
}

# ---------------------------------------------------------------------------
# Coverage mode
# ---------------------------------------------------------------------------

# Wire name -> the oldest spec label the field appears in, across the
# baselines (oldest first) and finally the target spec.
sub build_since_index {
  my ($opt, $exc) = @_;
  return undef unless @{ $opt->{baseline} };
  my @sources;
  for my $path (@{ $opt->{baseline} }, $opt->{spec}) {
    my ($defs, $label) = load_spec($path);
    my $version = $label =~ m{v(\d+\.\d+)\.yaml\z} ? $1 : $label;
    push @sources, [ $version, expected_model($defs, $exc) ];
  }
  my %first;    # class -> wire -> version
  for my $source (@sources) {
    my ($version, $model) = @$source;
    for my $class (keys %$model) {
      for my $wire (keys %{ $model->{$class}{props} }) {
        $first{$class}{$wire} //= $version;
      }
    }
  }
  my $oldest = $sources[0][0];
  return { first => \%first, oldest => $oldest };
}

sub run_coverage_mode {
  my ($opt) = @_;
  my $exc = load_exceptions($opt->{exceptions});
  my ($defs, $label) = load_spec($opt->{spec});
  my $expected  = expected_model($defs, $exc);
  my $non_class = non_class_definitions($defs);
  my $shipped   = load_model($opt->{lib});
  my $since_idx = build_since_index($opt, $exc);
  my $only      = defined $opt->{only} ? qr/$opt->{only}/ : undef;

  my (@missing_class, @missing_field, @extra_field, @type_mismatch,
      @inheritance, @since_drift, @perl_only, @suppressed, @checked);

  for my $class (sort keys %$expected) {
    next if $only && $class !~ $only;
    my $want = $expected->{$class};
    my $have = $shipped->{$class};
    unless ($have) {
      my ($ignored, $reason) = prefix_match($class, $exc->{ignore_missing_classes});
      if ($ignored) { push @suppressed, [ 'ignore_missing_classes', $class, $reason ]; next }
      push @missing_class, [ $class, $want->{path}, scalar keys %{ $want->{props} } ];
      next;
    }
    push @checked, $class;

    my %by_wire = map { ($have->{$_}{wire} => $have->{$_}) } keys %$have;

    for my $wire (sort keys %{ $want->{props} }) {
      unless ($by_wire{$wire}) {
        my ($ignored, $reason) = field_ignored($class, $wire, $exc->{ignore_missing_fields});
        if ($ignored) { push @suppressed, [ 'ignore_missing_fields', "$class.$wire", $reason ]; next }
        push @missing_field, [ $class, $wire ];
        next;
      }
      my $prop = $want->{props}{$wire};
      my $want_type = spec_type($prop->{schema}, "$prop->{path}.$wire", $defs, $exc);
      my $have_type = API::Docker::Type::describe_type($by_wire{$wire}{type});
      if ($want_type ne $have_type) {
        my ($ignored, $reason) = field_ignored($class, $wire, $exc->{ignore_type_mismatch});
        if ($ignored) { push @suppressed, [ 'ignore_type_mismatch', "$class.$wire", $reason ] }
        else { push @type_mismatch, [ $class, $wire, $have_type, $want_type ] }
      }
      if ($since_idx) {
        my $want_since = $since_idx->{first}{$class}{$wire};
        $want_since = undef if defined $want_since && $want_since eq $since_idx->{oldest};
        my $have_since = $by_wire{$wire}{since};
        if (($want_since // '') ne ($have_since // '')) {
          my ($ignored, $reason) = field_ignored($class, $wire, $exc->{ignore_since});
          if ($ignored) { push @suppressed, [ 'ignore_since', "$class.$wire", $reason ] }
          else { push @since_drift, [ $class, $wire, $have_since // '(none)', $want_since // '(none)' ] }
        }
      }
    }

    for my $wire (sort keys %by_wire) {
      next if $want->{props}{$wire};
      my ($ignored, $reason) = field_ignored($class, $wire, $exc->{ignore_extra_fields});
      if ($ignored) { push @suppressed, [ 'ignore_extra_fields', "$class.$wire", $reason ]; next }
      push @extra_field, [ $class, $wire ];
    }

    for my $parent (@{ $want->{extends} }) {
      push @inheritance, [ $class, $parent ] unless $class->isa($parent);
    }
  }

  for my $class (sort keys %$shipped) {
    next if $only && $class !~ $only;
    next if $expected->{$class};
    my ($ignored, $reason) = prefix_match($class, $exc->{perl_only});
    if ($ignored) { push @suppressed, [ 'perl_only', $class, $reason ]; next }
    push @perl_only, $class;
  }

  return {
    mode           => 'coverage',
    spec           => $label,
    baselines      => [ map { File::Spec->abs2rel($_, $DIST_ROOT) } @{ $opt->{baseline} } ],
    only           => $opt->{only},
    defs_total     => scalar keys %$defs,
    classes_wanted => scalar keys %$expected,
    classes_have   => scalar keys %$shipped,
    classes_checked=> \@checked,
    non_class      => $non_class,
    missing_class  => \@missing_class,
    missing_field  => \@missing_field,
    extra_field    => \@extra_field,
    type_mismatch  => \@type_mismatch,
    inheritance    => \@inheritance,
    since_drift    => \@since_drift,
    since_checked  => ($since_idx ? 1 : 0),
    perl_only      => \@perl_only,
    suppressed     => \@suppressed,
  };
}

sub render_coverage_report {
  my ($r, $verbose) = @_;
  my @out;
  push @out, '=== API::Docker spec-drift-check :: coverage ===';
  push @out, "spec:  $r->{spec}  ($r->{defs_total} definitions, "
    . "$r->{classes_wanted} classes called for)";
  push @out, "lib:   $r->{classes_have} classes loaded, "
    . scalar(@{ $r->{classes_checked} }) . ' checked against the spec';
  push @out, 'since: ' . ($r->{since_checked}
    ? 'checked against ' . join(', ', @{ $r->{baselines} })
    : 'not checked (pass --baseline to enable)');
  push @out, "only:  $r->{only}" if defined $r->{only};
  push @out, '';
  my @sections = (
    [ 'MISSING CLASS',     'definition in the spec, no class in lib/', $r->{missing_class},
      sub { sprintf('%s  <- %s (%d fields)', @{$_[0]}) } ],
    [ 'MISSING FIELD',     'field in the spec, not in the registry', $r->{missing_field},
      sub { sprintf('%s :: %s', @{$_[0]}) } ],
    [ 'EXTRA FIELD',       'field in the registry, not in the spec', $r->{extra_field},
      sub { sprintf('%s :: %s', @{$_[0]}) } ],
    [ 'TYPE MISMATCH',     'registry type vs spec type', $r->{type_mismatch},
      sub { sprintf('%s :: %s  lib=%s  spec=%s', @{$_[0]}) } ],
    [ 'INHERITANCE DRIFT', 'allOf $ref not composed with docker_extends', $r->{inheritance},
      sub { sprintf('%s should extend %s', @{$_[0]}) } ],
    [ 'SINCE DRIFT',       'POD version vs the specs it claims', $r->{since_drift},
      sub { sprintf('%s :: %s  lib=%s  specs=%s', @{$_[0]}) } ],
    [ 'PERL ONLY',         'class in lib/, no definition in the spec', $r->{perl_only},
      sub { $_[0] } ],
  );
  push @out, '--- SUMMARY ---';
  push @out, sprintf('  %-18s %5d   %s', $_->[0], scalar @{ $_->[2] }, $_->[1]) for @sections;
  push @out, '';
  for my $section (@sections) {
    my ($title, $blurb, $items, $format) = @$section;
    push @out, "--- $title  ($blurb) ---";
    push @out, '  ' . $format->($_) for @$items;
    push @out, '  (none)' unless @$items;
    push @out, '';
  }
  push @out, '--- NOT CLASSES (definitions that are a scalar, an array or a map) ---';
  push @out, sprintf('  %-24s %s', $_, $r->{non_class}{$_}) for sort keys %{ $r->{non_class} };
  push @out, '';
  if ($verbose) {
    push @out, '--- SUPPRESSED BY THE EXCEPTIONS FILE ---';
    push @out, sprintf('  [%s] %s  -- %s', $_->[0], $_->[1], $_->[2] // 'no reason given')
      for @{ $r->{suppressed} };
    push @out, '  (none)' unless @{ $r->{suppressed} };
    push @out, '';
  }
  else {
    push @out, sprintf('%d item(s) suppressed by %s; --verbose lists them.',
      scalar @{ $r->{suppressed} }, 'the exceptions file')
      if @{ $r->{suppressed} };
    push @out, '';
  }
  return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# Compare mode: two specs against each other. This is where `since` comes
# from -- the swagger has no per-field version of its own.
# ---------------------------------------------------------------------------

sub run_compare_mode {
  my ($opt) = @_;
  my $exc = load_exceptions($opt->{exceptions});
  my ($defs_a, $label_a) = load_spec($opt->{from});
  my ($defs_b, $label_b) = load_spec($opt->{to});
  my $model_a = expected_model($defs_a, $exc);
  my $model_b = expected_model($defs_b, $exc);

  my (@new_def, @removed_def, @new_field, @removed_field,
      @required_change, @type_change, @description_change);

  for my $name (sort keys %$defs_b) {
    push @new_def, $name unless exists $defs_a->{$name};
  }
  for my $name (sort keys %$defs_a) {
    push @removed_def, $name unless exists $defs_b->{$name};
  }

  for my $class (sort keys %$model_b) {
    my $b = $model_b->{$class};
    my $a = $model_a->{$class} or next;
    for my $wire (sort keys %{ $b->{props} }) {
      unless ($a->{props}{$wire}) { push @new_field, [ $class, $wire ]; next }
      my $ta = spec_type($a->{props}{$wire}{schema}, "$a->{props}{$wire}{path}.$wire", $defs_a, $exc);
      my $tb = spec_type($b->{props}{$wire}{schema}, "$b->{props}{$wire}{path}.$wire", $defs_b, $exc);
      push @type_change, [ $class, $wire, $ta, $tb ] if $ta ne $tb;
      my $da = $a->{props}{$wire}{schema}{description} // '';
      my $db = $b->{props}{$wire}{schema}{description} // '';
      push @description_change, [ $class, $wire ] if $da ne $db && $ta eq $tb;
    }
    for my $wire (sort keys %{ $a->{props} }) {
      push @removed_field, [ $class, $wire ] unless $b->{props}{$wire};
    }
  }

  for my $name (sort keys %$defs_b) {
    next unless exists $defs_a->{$name};
    my %ra = map { ($_ => 1) } @{ $defs_a->{$name}{required} // [] };
    my %rb = map { ($_ => 1) } @{ $defs_b->{$name}{required} // [] };
    push @required_change, [ $name, $_, 'now required' ] for grep { !$ra{$_} } sort keys %rb;
    push @required_change, [ $name, $_, 'no longer required' ] for grep { !$rb{$_} } sort keys %ra;
  }

  return {
    mode               => 'compare',
    from               => $label_a,
    to                 => $label_b,
    new_definition     => \@new_def,
    removed_definition => \@removed_def,
    new_field          => \@new_field,
    removed_field      => \@removed_field,
    required_change    => \@required_change,
    type_change        => \@type_change,
    description_change => \@description_change,
  };
}

sub render_compare_report {
  my ($r) = @_;
  my @out;
  push @out, '=== API::Docker spec-drift-check :: compare ===';
  push @out, "from:  $r->{from}";
  push @out, "to:    $r->{to}";
  push @out, '';
  push @out, 'A field listed under NEW FIELD is a `since` annotation waiting to be';
  push @out, "written: the swagger carries no per-field version, so this diff is the";
  push @out, 'only place one can come from. Classes are named as this dist names them,';
  push @out, 'inline schemas included.';
  push @out, '';
  my @sections = (
    [ 'NEW DEFINITION'      => $r->{new_definition},     sub { $_[0] } ],
    [ 'REMOVED DEFINITION'  => $r->{removed_definition}, sub { $_[0] } ],
    [ 'NEW FIELD'           => $r->{new_field},          sub { sprintf('%s :: %s', @{$_[0]}) } ],
    [ 'REMOVED FIELD'       => $r->{removed_field},      sub { sprintf('%s :: %s', @{$_[0]}) } ],
    [ 'REQUIRED CHANGE'     => $r->{required_change},    sub { sprintf('%s :: %s  %s', @{$_[0]}) } ],
    [ 'TYPE CHANGE'         => $r->{type_change},        sub { sprintf('%s :: %s  %s -> %s', @{$_[0]}) } ],
    [ 'DESCRIPTION CHANGE'  => $r->{description_change}, sub { sprintf('%s :: %s', @{$_[0]}) } ],
  );
  push @out, '--- SUMMARY ---';
  push @out, sprintf('  %-24s %4d', $_->[0], scalar @{ $_->[1] }) for @sections;
  push @out, '';
  for my $section (@sections) {
    my ($title, $items, $format) = @$section;
    push @out, "--- $title ---";
    push @out, '  ' . $format->($_) for @$items;
    push @out, '  (none)' unless @$items;
    push @out, '';
  }
  return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt    = parse_args();
my $result = defined $opt->{from} ? run_compare_mode($opt) : run_coverage_mode($opt);
my $report =
    $opt->{format} eq 'json' ? JSON::PP->new->canonical->pretty->encode($result)
  : $result->{mode} eq 'compare' ? render_compare_report($result)
  :                                render_coverage_report($result, $opt->{verbose});

print $report;
if ($opt->{output}) {
  open my $fh, '>:encoding(UTF-8)', $opt->{output}
    or die "spec-drift-check: cannot write $opt->{output}: $!\n";
  print $fh $report;
  close $fh;
}
