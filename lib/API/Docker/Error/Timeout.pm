package API::Docker::Error::Timeout;
# ABSTRACT: Read timeout while waiting for the Docker Engine
our $VERSION = '0.004';
use Moo;
# namespace::clean has to come BEFORE "use overload" here, not after it as
# everywhere else in this distribution -- same reason as in
# API::Docker::Error::Stream and API::Docker::Error::HTTP. It sweeps the
# symbols `overload` installs -- the `("" ` slot among them -- so with the two
# lines in the house order the class ends up not overloaded at all and
# stringifies as API::Docker::Error::Timeout=HASH(0x...). Nothing dies when
# that happens: every caller that only inspects $@ as a string silently starts
# seeing a reference address instead of the reason. Measured, not assumed:
# overload::Overloaded($err) is false with the lines swapped.
use namespace::clean;
use overload
  '""'     => sub { $_[0]->as_string },
  'bool'   => sub { 1 },
  fallback => 1;

=head1 SYNOPSIS

    # Stop waiting after two seconds of silence instead of hanging forever.
    my $out = '';
    eval {
        $docker->containers->attach($id,
            stream       => 1,
            stdout       => 1,
            read_timeout => 2,
            on_frame     => sub { $out .= $_[0]{data} },
        );
    };
    if (my $err = $@) {
        die $err unless ref $err
            && $err->isa('API::Docker::Error::Timeout');
        # Every complete frame reached the callback before the timeout; the
        # summary says how many.
        warn 'stopped after ' . $err->summary->{delivered} . ' frames';
    }

=head1 DESCRIPTION

L<API::Docker::Role::HTTP> croaks with an object of this class when a request
was given a L<API::Docker::Role::HTTP/read_timeout> and the daemon then went
quiet for longer than it -- and, with L</phase> set to C<'connect'>, when a
request was given a L<API::Docker::Role::HTTP/connect_timeout> and the socket
never came up within it.

The rest of this describes the read timeout, which is the one that has
something to hand back. A connect timeout carries no L</partial> and no
L</summary>, for the reason L</phase> gives: nothing was ever sent.

It is an B<idle> timeout, not a deadline: the clock is the time since the last
byte arrived, so a stream that keeps producing runs as long as it likes and one
that stalls is cut off. That is the distinction the endpoints this exists for
need -- a hung C</containers/{id}/attach> has already delivered its buffered
frames before it stalls, so "nothing yet" would never have fired.

=head2 Why it is fatal, on every path

A timeout is not information about the response; it is the absence of it. The
transport cannot know whether the daemon was about to send the rest, so it
cannot decide for the caller that what arrived is usable -- and every return
shape this distribution promises would hide the question if it tried. C<ndjson>
promises an ArrayRef of events, C<raw> promises the response bytes, the default
promises the decoded body: a truncated value satisfies all three and is
indistinguishable from a complete one. A half tarball that looks whole is a
worse outcome than the hang it replaced.

That holds for the callback streams too, even though they have already handed
the caller every complete unit. Returning normally there would run the stream
handler's finish step, which is written for a daemon that closed: it treats a
trailing partial line as a complete final event, and reports leftover bytes as
a frame the daemon cut in half. Neither statement is true of a timeout. One
rule -- a timeout is fatal -- also keeps C<read_timeout> meaning the same thing
whether or not C<on_event>/C<on_frame>/C<on_chunk> is in use.

Nothing is lost with the exception: L</partial> carries the bytes a buffered
read had collected, L</summary> the count a streamed one had delivered. A
caller who wants "collect what there is, then stop" writes the C<eval> in the
SYNOPSIS; a caller who wants to fail loudly gets that without writing anything.

=head2 It is still the string it replaces

Like L<API::Docker::Error::HTTP> and L<API::Docker::Error::Stream>, this class
overloads stringification (with C<< fallback => 1 >>, so comparison,
concatenation, C<sprintf> and matching all work through it) and produces what
a plain C<croak> would have died with: the reason, followed by Carp's own
C< at FILE line N.> location suffix, naming the same frame.

The boolean overload is explicit rather than derived from the string, so it
cannot be made false by its own message.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

=attr message

The reason on its own, without the location suffix: the request it belongs to,
the timeout that expired and how much had arrived before it did.

The request is named without its query string, for the same reason the
C<< >= 400 >> croak names it that way -- C</build> carries its C<buildargs>
there, which can hold credentials and have no business in an exception.

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

has endpoint => (
  is      => 'ro',
  default => sub { '' },
);

=attr endpoint

The request that timed out, as C<"GET /v1.47/containers/json"> -- method and
path, no query string.

=cut

has phase => (
  is      => 'ro',
  default => sub { 'read' },
);

=attr phase

Which of the two bounds fired: C<'read'> for
L<API::Docker::Role::HTTP/read_timeout>, C<'connect'> for
L<API::Docker::Role::HTTP/connect_timeout>. C<'read'> is the default, so an
object built without it describes what every one of them used to describe.

One class rather than two, because the question a caller catches this to ask
-- "did the request finish in time?" -- has the same answer either way, and a
second class would make every such caller name two of them or find their
common base. What differs is one bit: whether the daemon was ever reached.
That bit is this attribute.

It is also the only thing that tells a C<'connect'> timeout apart from a
C<'read'> one that expired before the first byte: L</partial> is the empty
string and L</summary> is C<undef> for both.

=cut

has timeout => (
  is       => 'ro',
  required => 1,
);

=attr timeout

The number of seconds of silence that triggered this, i.e. the effective
C<read_timeout> of the request -- or, when L</phase> is C<'connect'>, the
C<connect_timeout> that expired. Not the total time the request took: a stream
that sent something every second for an hour and then stopped reports the same
value as one that never said anything.

=cut

has partial => (
  is      => 'ro',
  default => sub { '' },
);

=attr partial

The response body bytes that had arrived when the timeout fired, for a request
whose body was being buffered -- the empty string when none had.

These are B<not> a body: nothing was decoded, no chunk framing was verified and
the content may stop mid-value. They are here so a caller who wants them can
have them rather than because the transport thinks they are usable.

Always the empty string for a streamed request, which keeps no body by design.
Nothing is lost there either: the bytes of the read that ran out of time are
put through the same decoding as every other byte first, so the units they
complete reach the callback and are counted in L</summary> before this is
raised. That matters more than it sounds -- on the raw-stream endpoints a
single read holds the whole response, so dropping it would hand a caller with
a callback nothing at all.

=cut

has summary => (
  is => 'ro',
);

=attr summary

For a request streaming through C<on_event>, C<on_frame> or C<on_chunk>: the
same C<< { delivered => N, stopped => 0 } >> HashRef the call would have
returned, describing what reached the callback before the timeout. C<undef> for
a buffered request.

Every unit it counts was complete and was delivered; a unit still arriving when
the clock ran out was not, and is not counted and not delivered.

=cut

sub as_string { $_[0]->message . $_[0]->location }

=method as_string

    my $text = $err->as_string;   # same as "$err"

The message and the location suffix, concatenated. This is what the
stringification overload returns.

=cut

=seealso

=over

=item * L<API::Docker::Role::HTTP> - Raises this error; see its C<read_timeout>
attribute and option

=item * L<API::Docker::Error::HTTP> - Raised instead when the daemon answered,
with a status of 400 or above

=item * L<API::Docker::Error::Stream> - Raised instead for a failure reported
inside a stream the daemon already answered with HTTP 200

=back

=cut

1;
