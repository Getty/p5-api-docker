package API::Docker::Error::Truncated;
# ABSTRACT: The daemon closed before the response it announced was complete
our $VERSION = '0.004';
use Moo;
# namespace::clean has to come BEFORE "use overload" here, not after it as
# everywhere else in this distribution -- same reason as in
# API::Docker::Error::Stream, API::Docker::Error::HTTP and
# API::Docker::Error::Timeout. It sweeps the symbols `overload` installs --
# the `("" ` slot among them -- so with the two lines in the house order the
# class ends up not overloaded at all and stringifies as
# API::Docker::Error::Truncated=HASH(0x...). Nothing dies when that happens:
# every caller that only inspects $@ as a string silently starts seeing a
# reference address instead of the reason. Measured, not assumed:
# overload::Overloaded($err) is false with the lines swapped.
use namespace::clean;
use overload
  '""'     => sub { $_[0]->as_string },
  'bool'   => sub { 1 },
  fallback => 1;

=head1 SYNOPSIS

    # A tar the daemon stopped sending halfway is not a tar.
    my $tar = eval { $docker->images->get_tar('busybox') };
    if (my $err = $@) {
        die $err unless ref $err
            && $err->isa('API::Docker::Error::Truncated');
        warn 'got ' . length($err->partial) . ' of '
            . $err->expected . ' bytes; retrying';
        $tar = $docker->images->get_tar('busybox');
    }

=head1 DESCRIPTION

L<API::Docker::Role::HTTP> croaks with an object of this class when the daemon
closed the connection in the middle of a response it had already said how long
it would be -- a body shorter than its C<Content-Length>, a chunk shorter than
its own header, a chunk header cut in half, or a chunked body with no
terminating zero chunk.

It is a structural check, not a heuristic: the only thing it compares is the
body against what the response itself announced. A body delimited by nothing
but the close -- C<attach>, C<< logs(follow => 1) >>, C</exec/{id}/start>, the
whole C<application/vnd.docker.raw-stream> family -- announces no end, so
there an EOF B<is> the end and this is never raised.

=head2 Why it is fatal

For the same reason L<API::Docker::Error::Timeout> is, and the two are the
same defect reached by different routes: a short body satisfies every return
shape this role promises and is indistinguishable from a complete one.
C<ndjson> promises an ArrayRef of events and gets a shorter one; C<raw>
promises the response bytes and gets fewer of them; the default promises the
decoded body and gets whatever the truncated bytes happened to parse as. A
half tarball that looks whole is the worst of them, and it is the case this
exists for.

Nothing is lost by raising it: L</partial> carries the bytes a buffered read
had collected and L</summary> the count a streamed one had delivered, so a
caller who wants what arrived can have it. What it cannot do any more is
mistake it for everything.

=head2 What it is not

Not a timeout. Nothing waited and nothing expired -- the daemon answered, and
then the stream ended early. L<API::Docker::Error::Timeout> is raised when the
daemon goes B<quiet> for longer than a C<read_timeout>, which is a bound the
caller asked for; this needs no option and is on for every request.

Not a status. The status line arrived intact and said 200; the response after
it did not. An engine that reports a failure the normal way raises
L<API::Docker::Error::HTTP>, and one that reports it inside an HTTP 200 stream
raises L<API::Docker::Error::Stream>. This is the third thing: no report at
all, because the connection went away mid-sentence.

A response with a status of 400 or above raises this rather than
L<API::Docker::Error::HTTP> when B<its> body is the one cut short, which is
the same rule the timeout follows: the transport cannot tell a caller what the
engine said when it did not finish saying it. Read L</partial> for the part of
the error body that did arrive.

=head2 It is still the string it replaces

Like the other three error classes here, this one overloads stringification
(with C<< fallback => 1 >>, so comparison, concatenation, C<sprintf> and
matching all work through it) and produces what a plain C<croak> would have
died with: the reason, followed by Carp's own C< at FILE line N.> location
suffix, naming the same frame.

Unlike the other three it replaces no string, because there was nothing here
to replace -- a truncated response used to be returned rather than raised.
That makes it the one exception in this distribution that existing code cannot
have been catching, which is why it is a documented behaviour change and not a
bug fix in passing.

The boolean overload is explicit rather than derived from the string, so it
cannot be made false by its own message.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

=attr message

The reason on its own, without the location suffix: the request it belongs to,
where in the response framing the stream ended, and how much had arrived.

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

The request that was cut short, as C<"GET /v1.47/images/get"> -- method and
path, no query string. The empty string for a reader driven directly with no
request context, which is how the transport's own tests drive them.

=cut

has phase => (
  is       => 'ro',
  required => 1,
);

=attr phase

Which piece of the response framing the stream ended inside. One of:

=over

=item * C<'content-length'> - fewer bytes arrived than the C<Content-Length>
header announced

=item * C<'chunk-header'> - the stream ended inside a chunk size line, or at a
chunk boundary with no terminating zero chunk after it

=item * C<'chunk-data'> - the stream ended inside a chunk, short of the size
that chunk's own header announced

=item * C<'chunk-terminator'> - a chunk's data arrived in full and the CRLF
that ends it did not

=back

Informational rather than something to branch on: every value means the same
thing to a caller, which is that the response is incomplete. It is here
because "which of the four" is the first question when a real engine starts
raising this, and reading it off the object beats parsing L</message>.

=cut

has expected => (
  is => 'ro',
);

=attr expected

The byte count the framing announced for the piece that was cut short: the
C<Content-Length> for C<'content-length'>, the chunk's own size for
C<'chunk-data'>. C<undef> for the two phases where nothing had been announced
yet.

=cut

has received => (
  is => 'ro',
);

=attr received

How many of L</expected> arrived. C<undef> whenever L</expected> is.

Note that this counts the piece, not the response: on a chunked body it is the
bytes of the unfinished chunk, while L</partial> holds every chunk before it
as well.

=cut

has partial => (
  is      => 'ro',
  default => sub { '' },
);

=attr partial

The response body bytes that had arrived when the stream ended, for a request
whose body was being buffered -- the empty string when none had.

These are B<not> a body: nothing was decoded, no chunk framing was verified
beyond what was needed to find the truncation, and the content stops
mid-value. They are here so a caller who wants them can have them rather than
because the transport thinks they are usable.

Always the empty string for a streamed request, which keeps no body by design.
Nothing is lost there either: every byte that arrived went through the same
decoding as every other byte, so the units it completed reached the callback
and are counted in L</summary> before this is raised.

=cut

has summary => (
  is => 'ro',
);

=attr summary

For a request streaming through C<on_event>, C<on_frame> or C<on_chunk>: the
same C<< { delivered => N, stopped => 0 } >> HashRef the call would have
returned, describing what reached the callback before the stream was cut off.
C<undef> for a buffered request.

C<stopped> is always 0 here. A stream the caller ended with C<< $stop->() >>
leaves the rest of the response unread on purpose and is never truncation --
the check is skipped entirely once the callback has said stop.

=cut

sub as_string { $_[0]->message . $_[0]->location }

=method as_string

    my $text = $err->as_string;   # same as "$err"

The message and the location suffix, concatenated. This is what the
stringification overload returns.

=cut

=seealso

=over

=item * L<API::Docker::Role::HTTP> - Raises this error; see
L<API::Docker::Role::HTTP/"Failure in the middle of a response">

=item * L<API::Docker::Error::Timeout> - Raised instead when the daemon went
quiet for longer than a C<read_timeout>, rather than closing

=item * L<API::Docker::Error::HTTP> - Raised instead when the daemon answered,
completely, with a status of 400 or above

=item * L<API::Docker::Error::Stream> - Raised instead for a failure reported
inside a stream the daemon already answered with HTTP 200

=back

=cut

1;
