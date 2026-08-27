package API::Docker::Error::Stream;
# ABSTRACT: Failure reported inside a Docker Engine progress stream
our $VERSION = '0.004';
use Moo;
# namespace::clean has to come BEFORE "use overload" here, not after it as
# everywhere else in this distribution. It sweeps the symbols `overload`
# installs -- the `("" ` slot among them -- so with the two lines in the
# house order the class ends up not overloaded at all and stringifies as
# API::Docker::Error::Stream=HASH(0x...). Nothing dies when that happens:
# every caller that only inspects $@ as a string silently starts seeing a
# reference address instead of the reason. Measured, not assumed:
# overload::Overloaded($err) is false with the lines swapped.
use namespace::clean;
use overload
  '""'     => sub { $_[0]->as_string },
  'bool'   => sub { 1 },
  fallback => 1;

=head1 SYNOPSIS

    my $events = eval { $docker->images->build(context => $tar, t => 'app:v1') };
    if (my $err = $@) {
        # Behaves exactly like the string it replaces ...
        warn "build failed: $err";

        # ... and carries the whole stream that led up to the failure.
        if (ref $err && $err->isa('API::Docker::Error::Stream')) {
            for my $event (@{ $err->events }) {
                print $event->{stream} if defined $event->{stream};
            }
        }
    }

=head1 DESCRIPTION

The engine's streaming endpoints -- C</build>, C</images/create> (pull) and
C</images/{name}/push> -- report a failed operation as an C<errorDetail> object
B<inside> a stream that was already answered with HTTP 200. A client that only
treats status >= 400 as an error hands a broken build back to its caller as a
success.

L<API::Docker::Role::HTTP> therefore croaks with an object of this class as
soon as an C<errorDetail> event appears in such a stream. The object exists
purely so the progress output is not lost with the failure: the complete event
list, error event included, is available through L</events>.

=head2 It is still the string it replaces

Everything else in this distribution croaks plain strings, and callers rely on
that. This class overloads stringification (with C<< fallback => 1 >>, so
comparison, concatenation, C<sprintf> and matching all work through it) and
produces exactly what C<croak> would have died with: the reason, followed by
Carp's own C< at FILE line N.> location suffix. Code written against the old
behaviour keeps working unchanged:

    eval { $docker->images->build(...) };
    if ($@) {
        (my $reason = $@) =~ s/\s+at\s+\S+\s+line\s+\d+\.?//g;   # still works
        die "no good: $@";                                        # still works
        warn $@ if $@ =~ /exit status/;                           # still works
    }

Note that a substitution B<on> C<$@> replaces the object in that scalar with a
plain string, as it would with any overloaded object, so take a copy first if
L</events> is still wanted afterwards.

The boolean overload is explicit rather than derived from the string, so an
engine message of C<0> cannot make a live exception test false.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

=attr message

The reason on its own, without the location suffix: the C<errorDetail.message>
the engine sent, prefixed with the request it belongs to. Trailing whitespace
is stripped -- engine messages usually end in a newline, and Carp appends no
location to a message that already ends in one.

=cut

has events => (
  is      => 'ro',
  default => sub { [] },
);

=attr events

ArrayRef of every event decoded from the stream, in order, the C<errorDetail>
event included. This is the progress output the caller would otherwise lose
by never receiving a return value.

=cut

has location => (
  is      => 'ro',
  default => sub { '' },
);

=attr location

Carp's location suffix (C< at FILE line N.\n>), captured at the point the
error was raised so it names the same frame a plain C<croak> would have named.
Kept apart from L</message> so a caller can have the reason without it.

=cut

sub as_string { $_[0]->message . $_[0]->location }

=method as_string

    my $text = $err->as_string;   # same as "$err"

The message and the location suffix, concatenated. This is what the
stringification overload returns.

=cut

=seealso

=over

=item * L<API::Docker::Role::HTTP> - Raises this error; see its C<ndjson> option

=item * L<API::Docker::API::Images> - C<build>, C<pull> and C<push>

=back

=cut

1;
