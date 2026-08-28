#!/usr/bin/env perl
# Generator for the classes under lib/API/Docker/Type/, out of the swagger in
# spec/.
#
# ==========================================================================
# THIS SCRIPT IS NOT A CLASS UPDATER, AND MUST NEVER BECOME ONE.
# ==========================================================================
#
# It may write a file that does not exist. It refuses to overwrite one that
# does, in any directory, and it has no code path that opens a file under
# lib/ for writing at all -- the output goes to a staging directory a human
# then copies from. There is no --force and there is no "regenerate all",
# deliberately: a generated class is a class somebody has since read,
# corrected and documented, and a re-run would throw that away silently. If
# you are here because a bulk refresh would be convenient, that convenience
# is the failure mode this paragraph exists to rule out. When a newer spec
# lands, maint/spec-drift-check.pl reports the difference and a human or an
# agent decides field by field what happens to each class.
#
# Two modes, both of which only ever write into a directory you name:
#
#   --stage DIR    Write the classes lib/ does not have yet. A class that
#                  already exists in lib/ is skipped and reported; a file
#                  that already exists in DIR stops the run.
#
#   --verify DIR   Render EVERY class into DIR, including the ones lib/
#                  already has, and diff DIR against lib/. This is the
#                  acceptance test: the sixteen classes written by hand are
#                  the model the generator is measured against, and the diff
#                  has to be empty. It is a proof, not a refresh -- nothing
#                  it writes goes anywhere near lib/.
#
# What the generator cannot derive lives in files beside it, never as a
# heuristic in here:
#
#   maint/spec-to-type-names.yaml       the Perl name for each of the 70
#                                       field names carrying a run of
#                                       capitals. An unlisted one stops
#                                       the run.
#   maint/spec-drift-exceptions.yaml    inline_class_names -- the six array
#                                       element classes whose name had to be
#                                       made singular. The same file the
#                                       drift checker reads; there is no
#                                       second map.
#   maint/spec-to-type-prose.yaml       the sentences a human wrote that the
#                                       swagger does not contain.
#
# Usage:
#   maint/spec-to-type.pl --verify /tmp/staged
#   maint/spec-to-type.pl --stage  /tmp/staged --only '^API::Docker::Type::Health'
use strict;
use warnings;
use v5.10;
use FindBin;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use File::Path qw( make_path );
use File::Spec;
use Getopt::Long qw( GetOptions );
use YAML::XS ();

require File::Spec->catfile($FindBin::Bin, 'spec-common.pl');
my $SPEC = 'API::Docker::Maint::Spec';

my $DIST_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $PREFIX    = 'API::Docker::Type::';
my $VERSION_LITERAL = '0.004';
my $WIDTH     = 76;

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
  my ($code) = @_;
  print <<"USAGE";
Usage:
  $0 --verify DIR [options]     render every class into DIR and diff against lib/
  $0 --stage  DIR [options]     write only the classes lib/ does not have

Options:
  --spec PATH         Spec to generate from (default: DIST/spec/v1.51.yaml)
  --baseline PATH     Older spec, repeatable, oldest first; the `since`
                       annotations come from diffing these against --spec
                       (default: DIST/spec/v1.41.yaml and v1.44.yaml)
  --only REGEX        Only classes whose name matches
  --lib PATH          The model to compare against (default: DIST/lib)
  --exceptions PATH   default: maint/spec-drift-exceptions.yaml
  --names PATH        default: maint/spec-to-type-names.yaml
  --prose PATH        default: maint/spec-to-type-prose.yaml
  --help

There is no --force and no mode that writes into lib/. See the header.
USAGE
  exit($code // 0);
}

sub parse_args {
  my %opt = (
    lib        => File::Spec->catdir($DIST_ROOT, 'lib'),
    spec       => File::Spec->catfile($DIST_ROOT, 'spec', 'v1.51.yaml'),
    exceptions => File::Spec->catfile($FindBin::Bin, 'spec-drift-exceptions.yaml'),
    names      => File::Spec->catfile($FindBin::Bin, 'spec-to-type-names.yaml'),
    prose      => File::Spec->catfile($FindBin::Bin, 'spec-to-type-prose.yaml'),
    baseline   => [],
  );
  GetOptions(\%opt,
    'stage=s', 'verify=s', 'spec=s', 'baseline=s@', 'only=s',
    'lib=s', 'exceptions=s', 'names=s', 'prose=s', 'help|h',
  ) or usage(1);
  usage(0) if $opt{help};
  die "spec-to-type: give exactly one of --stage or --verify\n"
    unless 1 == grep { defined $opt{$_} } qw( stage verify );
  @{ $opt{baseline} } = map { File::Spec->catfile($DIST_ROOT, 'spec', $_) }
    qw( v1.41.yaml v1.44.yaml ) unless @{ $opt{baseline} };
  return \%opt;
}

# The one guard that makes the header's promise structural rather than a
# convention: an output directory that is lib/, or inside it, is refused
# before anything is rendered.
sub check_output_dir {
  my ($dir, $lib) = @_;
  # abs_path, not rel2abs: the default --lib arrives as DIST/maint/../lib and
  # a hand-typed one as DIST/lib, and comparing those two as strings would
  # let `--stage lib` through. The output directory may not exist yet, so its
  # nearest existing ancestor is what gets resolved.
  my $abs_out = _resolve($dir);
  my $abs_lib = _resolve($lib);
  die "spec-to-type: refusing to write into the model itself ($abs_out).\n"
    . "The generator never writes to lib/; stage the output and copy what you\n"
    . "have read. See the header of this script for why.\n"
    if $abs_out eq $abs_lib || index($abs_out . '/', $abs_lib . '/') == 0;
  return $abs_out;
}

sub _resolve {
  my ($path) = @_;
  my $abs = File::Spec->rel2abs($path);
  my @missing;
  while (!-e $abs) {
    my $parent = dirname($abs);
    last if $parent eq $abs;
    unshift @missing, (File::Spec->splitdir($abs))[-1];
    $abs = $parent;
  }
  my $real = abs_path($abs) // $abs;
  return File::Spec->catdir($real, @missing);
}

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------

my %NAME_MAP;
my %PROSE;

# The mechanical half: an underscore before every capital that follows a
# lower-case letter or a digit, anything that is not a word character to an
# underscore, the lot lower-cased. Right for 568 of the 638 names in v1.51;
# the other 70 are in the map and a 71st stops the run.
sub perl_name {
  my ($wire, $where) = @_;
  if ($wire =~ /[A-Z]{2}/) {
    my $mapped = $NAME_MAP{$wire};
    die "spec-to-type: '$wire' (at $where) carries a run of capitals and is not\n"
      . "in maint/spec-to-type-names.yaml. Where a run of capitals ends is a\n"
      . "judgement about English, not about the string. The mechanical\n"
      . "derivation would give '" . _naive_name($wire) . "' here; it is not\n"
      . "consulted for these names because for DeviceIDs it gives 'device_i_ds',\n"
      . "which passes every check there is and still reads wrong. Add '$wire'\n"
      . "to the map and run again.\n"
      unless defined $mapped;
    return $mapped;
  }
  return _naive_name($wire);
}

sub _naive_name {
  my ($wire) = @_;
  my $name = $wire;
  $name =~ s/([a-z\d])([A-Z])/$1_$2/g;
  $name =~ s/[^A-Za-z0-9]+/_/g;
  return lc $name;
}

sub wire_from_perl { return join '', map { ucfirst } split /_/, $_[0] }

# ---------------------------------------------------------------------------
# Markdown -> POD
#
# The descriptions in the swagger are Markdown: backticks, bullet lists,
# fenced code, links, **bold**, and one <sup>. Everything below is
# deterministic. What it cannot do faithfully it records in @ROUGH, and that
# list is the curation order that follows a generation run -- it is not a
# warning to be silenced.
# ---------------------------------------------------------------------------

my @ROUGH;
sub rough { push @ROUGH, [ @_ ] }

sub md_inline {
  my ($text, $where) = @_;
  $text =~ s/\s+\z//;
  # POD has no escape for its own metacharacters inside C<>, so a backtick
  # span holding a > is wrapped in the double-angle form.
  $text =~ s/`([^`]*)`/_code_span($1)/ge;
  $text =~ s/\*\*([^*]+)\*\*/B<$1>/g;
  # Underscore italics, but only where the underscores are not part of an
  # identifier: `memory.kmem.tcp.limit_in_bytes` must survive intact, and by
  # this point it is already inside a C<>, whose word characters block the
  # look-behind.
  $text =~ s/(?<![\w`])_([^_`\n]+?)_(?![\w])/I<$1>/g;
  $text =~ s/\[([^\]]+)\]\((https?:[^)]+)\)/L<$1|$2>/g;
  $text =~ s{<sup>([^<]*)</sup>}{^$1}g;
  $text =~ s{<kbd>([^<]*)</kbd>}{C<$1>}g;
  # Only real HTML counts. The swagger is full of placeholders in angle
  # brackets -- <port>, <name|id>, <cidr> -- which are content, not markup,
  # and flagging them would bury the handful of fields that carry actual HTML.
  if ($text =~ m{</?(?:p|br|kbd|sup|sub|em|strong|b|i|a|ul|ol|li|code|table|tr|td)[ />]}i) {
    rough($where, 'the description carries HTML the converter left as it was');
  }
  return $text;
}

sub _code_span {
  my ($inner) = @_;
  return "C<< $inner >>" if $inner =~ /[<>]/;
  return "C<$inner>";
}

sub wrap_text {
  my ($text, $indent, $width) = @_;
  $width //= $WIDTH;
  my @words = split /\s+/, $text;
  my (@lines, $line);
  for my $word (@words) {
    next unless length $word;
    if (!defined $line) { $line = $word; next }
    if (length($line) + 1 + length($word) <= $width) { $line .= ' ' . $word }
    else { push @lines, $line; $line = $word }
  }
  push @lines, $line if defined $line;
  return map { length($_) ? $indent . $_ : '' } @lines;
}

# One description into POD blocks. Returns a list of blocks; each block is a
# list of lines, and blocks are joined with a blank line.
sub md_to_pod {
  my ($text, $where) = @_;
  return () unless defined $text && length $text;
  $text =~ s/\r\n/\n/g;
  # The three pieces of real HTML the swagger uses for layout, turned into
  # the layout they mean before the block parser sees them.
  $text =~ s{\s*</p>\s*<p>\s*}{\n\n}gi;
  $text =~ s{\s*</?p>\s*}{\n\n}gi;
  $text =~ s{<br\s*/?>}{\n}gi;
  my @lines = split /\n/, $text, -1;
  my (@blocks, @para, @list, @verbatim);
  my $in_fence = 0;

  my $flush_para = sub {
    return unless @para;
    push @blocks, [ wrap_text(md_inline(join(' ', @para), $where), '') ];
    @para = ();
  };
  my $flush_list = sub {
    return unless @list;
    my @out = ('=over 4', '');
    for my $item (@list) {
      push @out, wrap_text('=item * ' . md_inline($item, $where), '');
      push @out, '';
    }
    push @out, '=back';
    push @blocks, \@out;
    @list = ();
  };
  my $flush_verbatim = sub {
    return unless @verbatim;
    push @blocks, [ map { length($_) ? '    ' . $_ : '' } @verbatim ];
    @verbatim = ();
  };

  for my $line (@lines) {
    if ($line =~ /\A\s*```/) {
      if ($in_fence) { $flush_verbatim->(); $in_fence = 0 }
      else { $flush_para->(); $flush_list->(); $in_fence = 1 }
      next;
    }
    if ($in_fence) { push @verbatim, $line; next }
    if ($line =~ /\A\s*\z/) { $flush_para->(); $flush_list->(); next }
    if ($line =~ /\A(\s*)[-*]\s+(.*)\z/) {
      my ($indent, $item) = ($1, $2);
      $flush_para->();
      if (length($indent) >= 2 && @list) {
        # A nested bullet. POD can nest =over, but the swagger uses the
        # nesting for asides rather than for structure, so the item is folded
        # into the one above it and the field is named for curation.
        rough($where, 'a nested bullet list was folded into its parent item');
        $list[-1] .= ' ' . $item;
      }
      else { push @list, $item }
      next;
    }
    if (@list) { $list[-1] .= ' ' . $line; next }
    push @para, $line;
  }
  $flush_para->();
  $flush_list->();
  $flush_verbatim->();
  return @blocks;
}

sub blocks_to_text {
  my (@blocks) = @_;
  return join("\n\n", map { join("\n", @$_) } @blocks);
}

# The swagger is inconsistent about ending a description with a full stop --
# "Port on the container." has one, "Port exposed on the host" does not. A
# POD paragraph gets one either way.
sub terminate {
  my ($blocks) = @_;
  return unless @$blocks;
  return if $blocks->[-1][0] =~ /\A(?:=|    )/;
  my $text = join ' ', @{ $blocks->[-1] };
  $text =~ s/\s+\z//;
  return if $text =~ /[.!?:]\z/;
  $blocks->[-1] = [ wrap_text($text . '.', '') ];
  return;
}

# Append a sentence to the last block when that block is a paragraph, or as a
# new paragraph when it is a list or a verbatim block.
sub append_sentence {
  my ($blocks, $sentence) = @_;
  if (@$blocks && $blocks->[-1][0] !~ /\A(?:=|    )/) {
    my $text = join ' ', @{ $blocks->[-1] };
    $text =~ s/\s+\z//;
    # A closing > is the tail of a C<< ... >> and takes no full stop; a
    # closing paren does ("(Windows only)" is the end of a sentence).
    $text .= '.' unless $text =~ /[.!?:]\z/ || $text =~ />\z/;
    $blocks->[-1] = [ wrap_text($text . ' ' . $sentence, '') ];
  }
  else { push @$blocks, [ wrap_text($sentence, '') ] }
  return;
}

# ---------------------------------------------------------------------------
# Rendering one class
# ---------------------------------------------------------------------------

sub type_literal {
  my ($descriptor) = @_;
  my $kind = $descriptor->{kind};
  return ucfirst lc $descriptor->{scalar} if $kind eq 'scalar';
  return 'Any' if $kind eq 'any';
  if ($kind eq 'object') {
    (my $short = $descriptor->{class}) =~ s/\A\Q$PREFIX\E//;
    return "'" . $short . "'";
  }
  my $inner = type_literal($descriptor->{inner});
  return $kind eq 'array'
    ? ($inner =~ /\A'/ ? "[ $inner ]" : "[$inner]")
    : "{ Str, $inner }";
}

# The spec's type as a descriptor, in the shape API::Docker::Type builds from
# a DSL declaration -- so the literal above and the drift checker's
# describe_type render the same thing from the same information.
sub descriptor_for {
  my ($schema, $path, $defs, $exc) = @_;
  my $string = $SPEC->can('spec_type')->($schema, $path, $defs, $exc);
  return _parse_descriptor($string);
}

sub _parse_descriptor {
  my ($string) = @_;
  return { kind => 'array', inner => _parse_descriptor($1) } if $string =~ /\Aarray<(.*)>\z/;
  return { kind => 'hash',  inner => _parse_descriptor($1) } if $string =~ /\Ahash<(.*)>\z/;
  return { kind => 'object', class => $1 } if $string =~ /\Aobject<(.*)>\z/;
  return { kind => 'any' } if $string eq 'any';
  return { kind => 'scalar', scalar => ucfirst $string };
}

sub enum_literal {
  my ($values) = @_;
  my $plain = !grep { !length($_) || /[^A-Za-z0-9_.\-\/]/ } @$values;
  return $plain
    ? '[qw( ' . join(' ', @$values) . ' )]'
    : '[ ' . join(', ', map { "'" . $_ . "'" } @$values) . ' ]';
}

sub declaration {
  my ($field) = @_;
  my @opts;
  push @opts, "wire => '" . $field->{wire} . "'" if $field->{explicit_wire};
  push @opts, "since => '" . $field->{since} . "'" if defined $field->{since};
  push @opts, 'required => 1' if $field->{required};
  push @opts, 'enum => ' . enum_literal($field->{enum}) if $field->{enum};
  my $head = 'docker ' . $field->{name} . ' => ' . $field->{type_literal};
  my $one  = $head . (@opts ? ', ' . join(', ', @opts) : '') . ';';
  return $one if length($one) <= 78;

  # Too long for one line: the options move to a continuation line indented
  # by two. If they still do not fit, only an enum can be that long, and its
  # values wrap inside the qw().
  my $rest = '  ' . join(', ', @opts) . ';';
  return "$head,\n$rest" if length($rest) <= 78;
  my @head_opts = grep { !/\Aenum => / } @opts;
  my $prefix = @head_opts ? $head . ', ' . join(', ', @head_opts) : $head;
  my @wrapped = wrap_text(join(' ', @{ $field->{enum} }), '    ', 74);
  return join("\n", "$prefix,", '  enum => [qw(', @wrapped, '  )];');
}

sub class_file_body {
  my ($class, $info, $ctx) = @_;
  my @out;
  push @out, 'package ' . $class . ';';
  push @out, '# ABSTRACT: ' . $info->{abstract};
  push @out, "our \$VERSION = '" . $VERSION_LITERAL . "';";
  push @out, 'use API::Docker::Type;';
  push @out, 'use ' . $_ . ';' for @{ $info->{uses} };
  push @out, '';
  push @out, '=head1 DESCRIPTION';
  push @out, '';
  push @out, $info->{description};
  push @out, '';
  push @out, '=cut';
  push @out, '';
  if (@{ $info->{extends} }) {
    (my $short = $info->{extends}[0]) =~ s/\A\Q$PREFIX\E//;
    push @out, "docker_extends '" . $short . "';";
    push @out, '';
  }
  for my $field (@{ $info->{fields} }) {
    push @out, declaration($field);
    push @out, '';
    push @out, '=attr ' . $field->{name};
    push @out, '';
    push @out, $field->{pod};
    push @out, '';
    push @out, '=cut';
    push @out, '';
  }
  push @out, '1;';
  return join("\n", @out) . "\n";
}

# ---------------------------------------------------------------------------
# Building the description of a class and of each of its fields
# ---------------------------------------------------------------------------

sub spec_label { my ($path) = @_; (my $l = $path) =~ s{.*/}{}; return "spec/$l" }

# Go doc comments open with the identifier they document, and the swagger
# inherits that: "PortBinding represents a binding between ...". As the first
# line of a NAME section that reads as a stutter, so the opener is stripped.
sub strip_go_opener {
  my ($text, $name) = @_;
  return $text unless defined $name && length $name;
  return $text unless $text =~ s/\A\Q$name\E\s+(?:represents|stores|describes|contains|is)\s+//;
  return ucfirst $text;
}

# A description split into (first sentence, everything after it). The first
# sentence becomes the ABSTRACT and the remainder the body, so the split has
# to survive the swagger's line wrapping: "PortBinding represents a binding
# between a host IP address and a host\nport." is one sentence with a newline
# in the middle of it. Paragraph breaks after the first paragraph are kept.
sub split_description {
  my ($text) = @_;
  $text =~ s/\A\s+//;
  $text =~ s/\s+\z//;
  my ($head, @rest) = split /\n[ \t]*\n/, $text, -1;
  my $flat = $head;
  $flat =~ s/\s+/ /g;
  my ($first) = $flat =~ /\A(.*?\.)(?:\s|\z)/;
  my $tail;
  if (defined $first) {
    $tail = substr($flat, length $first);
    $first =~ s/\.\z//;
  }
  else { ($first, $tail) = ($flat, '') }
  $tail =~ s/\A\s+//;
  my $body = join "\n\n", grep { /\S/ } ($tail, @rest);
  return ($first, $body);
}

# ---------------------------------------------------------------------------
# What a definition IS, where the definition itself does not say
#
# 34 of v1.51's definitions carry neither description nor title. The spec
# still states the fact, in two other places: `paths:` names the request or
# response a definition is the schema of, and the other definitions name the
# fields that hold it. Reading either is a measurement of the same checked-in
# file, no less verifiable than a description field -- so a sentence built
# out of one is a derivation, not an invention, and the refusal below stays
# only for what neither reaches.
# ---------------------------------------------------------------------------

# "one entry of A, B and C" rather than "one entry of A, one entry of B and
# one entry of C": where every site is reached the same way, the lead is said
# once. ThrottleDevice sits in four fields of Resources and reads as a list.
sub join_phrases {
  my (@phrases) = @_;
  return '' unless @phrases;
  my $lead = '';
  for my $candidate ('one entry of ', 'one value of ', 'the value of ', 'the body of ') {
    next if grep { index($_, $candidate) != 0 } @phrases;
    $lead = $candidate;
    s/\A\Q$candidate\E// for @phrases;
    last;
  }
  return $lead . $phrases[0] if @phrases == 1;
  my $last = pop @phrases;
  return $lead . join(', ', @phrases) . " and $last";
}

sub path_site_phrase {
  my ($site) = @_;
  my $endpoint = 'C<' . $site->{method} . ' ' . $site->{path} . '>';
  my $where = $site->{kind} eq 'response'
    ? 'the C<' . $site->{code} . '> response to ' . $endpoint
    : 'the body of a ' . $endpoint . ' request';
  my $base = length $site->{field}
    ? 'the C<' . $site->{field} . '> field of ' . $where
    : $where;
  return 'one entry of ' . $base if $site->{via} eq 'array';
  return 'one value of ' . $base if $site->{via} eq 'map';
  return $base if length $site->{field};
  return $site->{kind} eq 'response' ? 'the body of ' . $where : $where;
}

sub ref_site_phrase {
  my ($site) = @_;
  my $field = 'C<' . $site->{field} . '>';
  return 'one entry of ' . $field if $site->{via} eq 'array';
  return 'one value of ' . $field if $site->{via} eq 'map';
  return 'the value of ' . $field;
}

# ({ abstract, sentence }) or nothing.
sub derive_identity {
  my ($spec, $name) = @_;
  if (my $sites = $SPEC->can('path_index')->($spec)->{$name}) {
    my @phrases = map { path_site_phrase($_) } @$sites;
    return {
      abstract => ucfirst $phrases[0],
      sentence => 'C<paths:> says what it is: ' . join_phrases(@phrases) . '.',
    };
  }
  if (my $sites = $SPEC->can('reference_index')->($spec)->{$name}) {
    my @phrases = map { ref_site_phrase($_) } @$sites;
    return {
      abstract => ucfirst $phrases[0],
      sentence => 'Nothing in C<paths:> reaches it either; it is '
        . join_phrases(@phrases) . '.',
    };
  }
  return undef;
}

sub build_class {
  my ($class, $model_info, $spec, $defs, $exc, $since, $label) = @_;
  my $path   = $model_info->{path};
  my @parts  = split /\./, $path;
  my $schema = $defs->{ $parts[0] };
  my $own_description;
  my $is_inline = @parts > 1;
  if ($is_inline) {
    # For an inline object the property and the schema are the same node, so
    # a description written on the property IS the schema's description --
    # "Optional configuration for the `bind` type." sits on Mount.BindOptions
    # and describes the object it opens. Only an array's items are a
    # different node, and there the property describes the array rather than
    # one element of it, which is why nothing is borrowed across that step.
    my $prop = $SPEC->can('_schema_at')->($spec, join('.', @parts[0 .. $#parts - 1]), $parts[-1]);
    $own_description = $SPEC->can('inline_object_schema')->($prop)->{description};
  }
  else { $own_description = $schema->{description} }
  my $identity;
  if (!defined $own_description || !length $own_description) {
    if (!$is_inline) { $identity = derive_identity($spec, $parts[0]) }
    else {
      # An inline schema that is an array's items: the class is named for one
      # element and the property for the whole array, so saying which array is
      # the singularisation the exceptions file records, spelled out. For an
      # inline object that IS the property, the same sentence would only
      # repeat the class name back at the reader, so there is nothing to
      # derive and the refusal stands.
      my $parent_path = join '.', @parts[0 .. $#parts - 1];
      my $prop = $SPEC->can('_schema_at')->($spec, $parent_path, $parts[-1]);
      my $field = "$parent_path.$parts[-1]";
      # No sentence: the provenance line above already says "the inline items
      # schema of C<Resources.Ulimits>", and repeating the path underneath it
      # would be filler.
      $identity = { abstract => 'One entry of C<' . $field . '>' }
        if $SPEC->can('is_array_schema')->($prop);
    }
  }

  # Two shapes where the mechanical class name is a guess rather than a
  # derivation, and both belong in inline_class_names:
  #
  #   * a property the swagger spells in lower case ("rootfs") would give Perl
  #     a lower-case class name, which reads as a pragma rather than a class;
  #   * an inline object inside an ARRAY is one element of that array, and the
  #     property is named for the whole of it -- Resources.Ulimits holds
  #     Ulimit objects, and no rule turns the one word into the other.
  #
  # Neither is fatal to the model, both are wrong to guess at, so the class is
  # reported and not written.
  if (!$exc->{inline_class_names}{$path}) {
    if ($is_inline) {
      die { needs_class_name => $class }
        if (split /::/, $class)[-1] !~ /\A[A-Z]/;
      my $parent_path = join '.', @parts[0 .. $#parts - 1];
      my $prop_schema = $SPEC->can('_schema_at')->($spec, $parent_path, $parts[-1]);
      die { needs_class_name => $class }
        if $SPEC->can('is_array_schema')->($prop_schema);
    }
    # A definition that is itself an array of inline objects: the class is one
    # element and the definition names the whole array, so it is the same
    # judgement.
    die { needs_class_name => $class } if $model_info->{from_items};
  }

  my $prose = $PROSE{$class} // {};

  # ABSTRACT
  my $abstract = $prose->{abstract};
  if (!defined $abstract) {
    # The one line under `package` is what a reader sees first, and where the
    # swagger describes neither the definition nor the inline schema there is
    # nothing to derive it from. The class is not rendered: a generated
    # placeholder would be an invention, and the whole point of the prose file
    # is that inventions are written by a person and recorded.
    if (defined $own_description && length $own_description) {
      $abstract = strip_go_opener((split_description($own_description))[0], $parts[-1]);
      $abstract = md_inline($abstract, "$class ABSTRACT");
    }
    elsif ($identity) { $abstract = $identity->{abstract} }
    else { die { needs_abstract => $class } }
  }

  # DESCRIPTION
  my @blocks;
  my $provenance;
  if ($is_inline) {
    my $parent = join '.', @parts[0 .. $#parts - 1];
    my $named  = @parts == 2 ? "the C<$parent> definition" : "C<$parent>";
    my $what   = $SPEC->can('inline_object_schema')->(
      $SPEC->can('_schema_at')->($spec, join('.', @parts[0 .. $#parts - 1]), $parts[-1]) ) ;
    my $prop_schema = $SPEC->can('_schema_at')->($spec, $parent, $parts[-1]);
    my $through_items = ($prop_schema->{type} // '') eq 'array' ? 1 : 0;
    $provenance = $through_items
      ? "Generated from the inline C<items> schema of C<$path> in C<"
        . spec_label($label) . '>.'
      : "Generated from the inline C<$parts[-1]> schema of $named in C<"
        . spec_label($label) . '>.';
  }
  else {
    $provenance = "Generated from the C<$path> definition of C<" . spec_label($label) . '>.';
  }
  unless (defined $own_description && length $own_description) {
    $provenance =~ s/\.\z/, which the swagger leaves undescribed./;
  }
  push @blocks, [ wrap_text($provenance, '') ];
  append_sentence(\@blocks, $identity->{sentence})
    if $identity && $identity->{sentence};
  if (@{ $model_info->{extends} }) {
    my $own   = scalar @{ $model_info->{order} };
    my $total = scalar @{ $model_info->{flat_order} };
    my $parent = $model_info->{extends}[0];
    (my $parent_short = $parent) =~ s/\A\Q$PREFIX\E//;
    $blocks[-1] = [ wrap_text(
      join(' ', @{ $blocks[-1] }) =~ s/\.\z//r
      . ", which is C<allOf [ \$ref $parent_short, { $own properties } ]>.", '') ];
    append_sentence(\@blocks,
      'The reference becomes a superclass, so a C<' . $parts[-1] . '> carries the '
      . ($total - $own) . " fields of L<$parent> as well as the $own declared "
      . "here -- $total in all.");
    append_sentence(\@blocks,
      'See L<API::Docker::Type/C<allOf> becomes inheritance>.');
  }
  if (defined $own_description && length $own_description) {
    my (undef, $rest) = split_description($own_description);
    push @blocks, md_to_pod($rest, "$class DESCRIPTION") if $rest =~ /\S/;
  }
  append_sentence(\@blocks, $_) for @{ $prose->{description_append} // [] };
  push @blocks, [ wrap_text($_, '') ] for @{ $prose->{description_extra} // [] };
  terminate(\@blocks);

  # Fields
  my (@fields, %uses, %perl_seen);
  for my $wire (@{ $model_info->{order} }) {
    my $prop = $model_info->{props}{$wire} or next;
    my $name = perl_name($wire, "$path.$wire");
    die "spec-to-type: $class derives the Perl name '$name' twice, from\n"
      . "$perl_seen{$name} and from $wire. One of them needs a different name\n"
      . "in maint/spec-to-type-names.yaml.\n" if $perl_seen{$name};
    $perl_seen{$name} = $wire;
    my $descriptor = descriptor_for($prop->{schema}, "$prop->{path}.$wire", $defs, $exc);
    _collect_uses($descriptor, \%uses);
    my $derived_wire  = wire_from_perl($name);
    my $explicit_wire = $derived_wire ne $wire;
    my $required = grep { $_ eq $wire } @{ ($defs->{ $parts[0] }{required} // []) };
    $required = 0 if $is_inline;
    my $field = {
      name          => $name,
      wire          => $wire,
      explicit_wire => $explicit_wire,
      since         => $since->{$class}{$wire},
      required      => $required,
      enum          => _enum_of($prop->{schema}, $defs),
      type_literal  => type_literal($descriptor),
      descriptor    => $descriptor,
    };
    $field->{pod} = build_attr_pod($class, $field, $prop, $defs, $prose);
    push @fields, $field;
  }
  delete $uses{$_} for ($class, @{ $model_info->{extends} });

  return {
    abstract    => $abstract,
    description => blocks_to_text(@blocks),
    uses        => [ sort keys %uses ],
    extends     => $model_info->{extends},
    fields      => \@fields,
  };
}

sub _object_class_of {
  my ($descriptor) = @_;
  return $descriptor->{class} if $descriptor->{kind} eq 'object';
  return _object_class_of($descriptor->{inner}) if $descriptor->{inner};
  return undef;
}

sub _collect_uses {
  my ($descriptor, $uses) = @_;
  return $uses->{ $descriptor->{class} } = 1 if $descriptor->{kind} eq 'object';
  return _collect_uses($descriptor->{inner}, $uses) if $descriptor->{inner};
  return;
}

sub _enum_of {
  my ($schema, $defs) = @_;
  return $schema->{enum} if $schema->{enum};
  my $ref = $SPEC->can('single_ref')->($schema) or return undef;
  my $target = $defs->{$ref} or return undef;
  return $SPEC->can('is_class_schema')->($target) ? undef : $target->{enum};
}

sub build_attr_pod {
  my ($class, $field, $prop, $defs, $prose) = @_;
  my $where = $class . '::' . $field->{name};
  my $curated = $prose->{attr}{ $field->{name} };
  return join("\n", wrap_text($curated->{replace}, '')) if $curated && $curated->{replace};

  my $description = $prop->{schema}{description};
  # A bare $ref carries no description of its own. The definition it points
  # at does, and that is the description of this field -- HostConfig's
  # PortBindings and RestartPolicy are both nothing but a $ref. For a $ref to
  # a class only the opening sentence is taken: the rest belongs on the class
  # the reader is sent to.
  if (!defined $description || !length $description) {
    if (my $ref = $SPEC->can('single_ref')->($prop->{schema})) {
      my $target = $defs->{$ref};
      if ($target && defined $target->{description}) {
        $description = $SPEC->can('is_class_schema')->($target)
          ? (split_description($target->{description}))[0] . '.'
          : $target->{description};
      }
    }
  }
  my @blocks;
  if (defined $description && length $description) {
    @blocks = md_to_pod($description, $where);
    # The swagger starts a few descriptions in lower case ("key/value map of
    # driver specific options"); a POD paragraph starts with a capital.
    $blocks[0][0] =~ s/\A([a-z])/\u$1/ if @blocks && $blocks[0][0] !~ /\A(?:=|    )/;
  }
  else {
    @blocks = ([ 'Undocumented upstream.' ]);
    rough($where, 'the swagger gives this field no description at all');
  }
  append_sentence(\@blocks, $_) for @{ ($curated ? $curated->{extra} : undef) // [] };

  # A field whose schema is an allOf around a single $ref to something that
  # is not a class: swagger's way of hanging a description onto a reference.
  if (my $ref = $SPEC->can('single_ref')->($prop->{schema})) {
    my $target = $defs->{$ref};
    if ($target && !$SPEC->can('is_class_schema')->($target) && $prop->{schema}{allOf}) {
      append_sentence(\@blocks,
        "The swagger types this field as an C<allOf> around a single C<\$ref> to "
        . "C<$ref>, which is a "
        . ($target->{type} // 'scalar')
        . ' and not an object, so it is a plain '
        . type_literal($field->{descriptor}) . ' here.');
    }
  }

  if (my $enum = $field->{enum}) {
    my $rendered = blocks_to_text(@blocks);
    my $missing = grep { length($_) && index($rendered, $_) < 0 } @$enum;
    if ($missing) {
      my @quoted = map { length($_) ? "C<$_>" : 'the empty string' } @$enum;
      my $last = pop @quoted;
      append_sentence(\@blocks,
        'The swagger enumerates ' . join(', ', @quoted) . " and $last.");
    }
  }

  # A field that carries a typed object points at its class, so the class is
  # one click away in the POD rather than something to guess from the name.
  if (my $target = _object_class_of($field->{descriptor})) {
    append_sentence(\@blocks, 'See L<' . $target . '>.');
  }

  # A daemon-side default is worth stating -- but only where the description
  # is not already talking about defaults itself. Mount.BindOptions'
  # ReadOnlyNonRecursive carries `default: false` next to a paragraph saying
  # the daemon defaults it to true for pre-1.44 clients, and appending the
  # schema's value there would read as a contradiction.
  if (exists $prop->{schema}{default} && blocks_to_text(@blocks) !~ /default/i) {
    my $default = $prop->{schema}{default};
    $default = ref $default ? ($default ? 'true' : 'false')
      : !defined $default   ? 'null'
      :                       $default;
    append_sentence(\@blocks, 'The daemon defaults it to ' . $default . '.');
  }

  if ($field->{descriptor}{kind} eq 'hash') {
    append_sentence(\@blocks,
      "B<The keys are the caller's data> and are never translated.");
  }

  if ($field->{explicit_wire}) {
    append_sentence(\@blocks,
      'Serialised as C<' . $field->{wire} . '> -- spelled out, because deriving '
      . 'it from the Perl name would produce C<' . wire_from_perl($field->{name}) . '>.');
  }

  if ($field->{required}) {
    append_sentence(\@blocks,
      'The swagger lists this field as required; nothing here enforces that, '
      . 'see L<API::Docker::Type/C<since> is documentation>.');
  }

  terminate(\@blocks);
  return blocks_to_text(@blocks);
}

# ---------------------------------------------------------------------------
# since
# ---------------------------------------------------------------------------

sub since_index {
  my ($opt, $exc) = @_;
  my (%first, $oldest);
  for my $path (@{ $opt->{baseline} }, $opt->{spec}) {
    my $spec = $SPEC->can('load')->($path);
    my $version = $path =~ m{v(\d+\.\d+)\.yaml\z} ? $1 : $path;
    $oldest //= $version;
    my $model = $SPEC->can('expected_model')->($spec, $exc);
    for my $class (keys %$model) {
      $first{$class}{$_} //= $version for keys %{ $model->{$class}{props} };
    }
  }
  for my $class (keys %first) {
    for my $wire (keys %{ $first{$class} }) {
      delete $first{$class}{$wire} if $first{$class}{$wire} eq $oldest;
    }
  }
  return \%first;
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $opt = parse_args();
my $out_dir = check_output_dir($opt->{stage} // $opt->{verify}, $opt->{lib});
%NAME_MAP = %{ YAML::XS::LoadFile($opt->{names}) // {} };
%PROSE    = %{ -f $opt->{prose} ? YAML::XS::LoadFile($opt->{prose}) // {} : {} };

my $exc   = $SPEC->can('load_exceptions')->($opt->{exceptions});
my $spec  = $SPEC->can('load')->($opt->{spec});
my $defs  = $spec->{definitions};
my $model = $SPEC->can('expected_model')->($spec, $exc);
my $since = since_index($opt, $exc);
my $only  = defined $opt->{only} ? qr/$opt->{only}/ : undef;

my (@written, @skipped, @needs_abstract, @needs_class_name);
for my $class (sort keys %$model) {
  next if $only && $class !~ $only;
  (my $rel = $class) =~ s{::}{/}g;
  $rel .= '.pm';
  my $in_lib = File::Spec->catfile($opt->{lib}, $rel);
  if ($opt->{stage} && -e $in_lib) {
    push @skipped, $class;
    next;
  }
  my $target = File::Spec->catfile($out_dir, $rel);
  die "spec-to-type: $target already exists. The generator never overwrites a\n"
    . "file; empty the staging directory or name another one.\n" if -e $target;
  my $body = eval {
    class_file_body($class,
      build_class($class, $model->{$class}, $spec, $defs, $exc, $since, $opt->{spec}));
  };
  unless (defined $body) {
    my $err = $@;
    die $err unless ref $err eq 'HASH';
    push @needs_abstract, $err->{needs_abstract} if $err->{needs_abstract};
    push @needs_class_name, $err->{needs_class_name} if $err->{needs_class_name};
    next;
  }
  make_path(dirname($target));
  open my $fh, '>:encoding(UTF-8)', $target
    or die "spec-to-type: cannot write $target: $!\n";
  print $fh $body;
  close $fh;
  push @written, $class;
}

printf("spec-to-type: %s\n", $opt->{verify} ? 'verify' : 'stage');
printf("  spec      %s\n", spec_label($opt->{spec}));
printf("  output    %s\n", $out_dir);
printf("  rendered  %d class(es)\n", scalar @written);
printf("  skipped   %d class(es) that lib/ already has\n", scalar @skipped)
  if $opt->{stage};

if (@needs_class_name) {
  printf("\n--- NEEDS A CLASS NAME BEFORE IT CAN BE GENERATED (%d) ---\n",
    scalar @needs_class_name);
  print "Either the swagger spells the property in lower case, so the\n"
    . "mechanical name would be a lower-case Perl class, or the inline object\n"
    . "sits inside an array and the property names the whole array rather than\n"
    . "one element of it. Put the name you want under inline_class_names in\n"
    . "maint/spec-drift-exceptions.yaml.\n";
  printf("  %s\n", $_) for @needs_class_name;
}

if (@needs_abstract) {
  printf("\n--- NEEDS AN ABSTRACT BEFORE IT CAN BE GENERATED (%d) ---\n",
    scalar @needs_abstract);
  print "The swagger describes neither the definition nor, for an inline\n"
    . "schema, the schema itself. Write the one-line abstract into\n"
    . "maint/spec-to-type-prose.yaml; nothing here will invent one.\n";
  printf("  %s\n", $_) for @needs_abstract;
}

if (@ROUGH) {
  my %by;
  push @{ $by{ $_->[1] } }, $_->[0] for @ROUGH;
  print "\n--- CURATION LIST (what the converter could only translate roughly) ---\n";
  for my $reason (sort keys %by) {
    my @where = do { my %s; grep { !$s{$_}++ } @{ $by{$reason} } };
    printf("  %s (%d)\n", $reason, scalar @where);
    printf("    %s\n", $_) for @where;
  }
}

if ($opt->{verify}) {
  # The acceptance test. Every class that exists in both trees is diffed;
  # a class lib/ does not have yet is nothing to compare against and is
  # counted, not diffed.
  my ($compared, $differ, $absent) = (0, 0, 0);
  my @failed;
  print "\n--- DIFF against $opt->{lib} ---\n";
  for my $class (@written) {
    (my $rel = $class) =~ s{::}{/}g;
    $rel .= '.pm';
    my $in_lib = File::Spec->catfile($opt->{lib}, $rel);
    unless (-e $in_lib) { $absent++; next }
    $compared++;
    my $rc = system('diff', '-u', $in_lib, File::Spec->catfile($out_dir, $rel));
    next if $rc == 0;
    $differ++;
    push @failed, $class;
  }
  printf("%d class(es) compared, %d identical, %d different, "
    . "%d not in lib/ yet\n", $compared, $compared - $differ, $differ, $absent);
  print "the diff is empty\n" unless $differ;
  printf("  %s\n", $_) for @failed;
  exit($differ ? 1 : 0);
}
exit(@needs_abstract || @needs_class_name ? 1 : 0);
