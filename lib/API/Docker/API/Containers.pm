package API::Docker::API::Containers;
# ABSTRACT: Docker Engine Containers API
our $VERSION = '0.004';
use Moo;
with 'API::Docker::Role::Filters';
use API::Docker::Container;
use Carp qw( croak );
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # List containers
    my $containers = $docker->containers->list(all => 1);
    for my $container (@$containers) {
        say $container->Id;
        say $container->Status;
    }

    # Create and start a container
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        ExposedPorts => { '80/tcp' => {} },
    );
    $docker->containers->start($result->{Id});

    # Inspect container details
    my $container = $docker->containers->inspect($result->{Id});
    say $container->Name;

    # Stop and remove
    $docker->containers->stop($result->{Id}, timeout => 10);
    $docker->containers->remove($result->{Id});

    # View logs (ArrayRef of { stream => 'stdout'|'stderr'|'raw', data => ... })
    my $frames = $docker->containers->logs($result->{Id}, tail => 100);
    my $text = join '', map { $_->{data} } @$frames;

    # Attach to a container that exits by itself -- the same frames, one-way
    my $attached = $docker->containers->attach($result->{Id});

    # Copy a file out, and a tar archive in (what docker cp is built on)
    my $tar = $docker->containers->get_archive($result->{Id},
        path => '/etc/hostname');
    $docker->containers->put_archive($result->{Id}, $tar, path => '/tmp');

=head1 DESCRIPTION

This module provides methods for managing Docker containers including creation,
lifecycle operations (start, stop, restart), inspection, logs, and more.

All C<list> and C<inspect> methods return L<API::Docker::Container> objects
for convenient access to container properties and operations.

Accessed via C<< $docker->containers >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub _wrap {
  my ($self, $data) = @_;
  return API::Docker::Container->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

# A state-change endpoint answers 204 when it changed something and 304 when
# the container was already in the state asked for. Neither carries a body, so
# the return value of the request is undef either way and the two are
# indistinguishable from it. The status comes out through the `response`
# out-parameter (see API::Docker::Role::HTTP/"Reading the status line and the
# response headers") and becomes the documented 1/0.
sub _state_change {
  my ($self, $path, %opts) = @_;
  my %response;
  $self->client->post($path, undef, %opts, response => \%response);
  return 0 if defined $response{status} && $response{status} == 304;
  return 1;
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{all}     = $opts{all} ? 1 : 0  if defined $opts{all};
  $params{limit}   = $opts{limit}        if defined $opts{limit};
  $params{size}    = $opts{size} ? 1 : 0 if defined $opts{size};
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/containers/json', params => \%params);
  return $self->_wrap_list($result // []);
}

=method list

    my $containers = $containers->list(%opts);

List containers. Returns ArrayRef of L<API::Docker::Container> objects.

Options:

=over

=item * C<all> - Show all containers (default shows just running)

=item * C<limit> - Limit results to N most recently created containers

=item * C<size> - Include size information

=item * C<filters> - HashRef of filter name to ArrayRef of string values, e.g.
C<< { status => ['running'], label => ['stage=build'] } >>. Shape-checked and
normalised by L<API::Docker::Role::Filters>

=back

=cut

sub create {
  my ($self, %config) = @_;
  my %params;
  $params{name} = delete $config{name} if defined $config{name};
  my $result = $self->client->post('/containers/create', \%config, params => \%params);
  return $result;
}

=method create

    my $result = $containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        Cmd   => ['/bin/sh'],
        Env   => ['FOO=bar'],
    );

Create a new container. Returns hashref with C<Id> and C<Warnings>.

The C<name> parameter is extracted and passed as query parameter. All other
parameters are Docker container configuration (see Docker API documentation).

Common config keys: C<Image>, C<Cmd>, C<Env>, C<ExposedPorts>, C<HostConfig>.

=cut

sub inspect {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  my $result = $self->client->get("/containers/$id/json");
  return $self->_wrap($result);
}

=method inspect

    my $container = $containers->inspect($id);

Get detailed information about a container. Returns L<API::Docker::Container> object.

=cut

sub start {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/start");
}

=method start

    $containers->start($id);

    say 'was already running' unless $containers->start($id);

Start a container. Returns 1 when the container was started and 0 when it was
already running: the engine answers a state change with 204 and a no-op with
B<304 Not Modified>, and both carry an empty body, so until now both came back
as C<undef>.

The no-op keeps the falsy value this method always returned -- 0 where it used
to be C<undef> -- so a caller that ignores the return or tests it for falseness
is unaffected; only a caller testing C<defined> sees a difference. A failure is
still a croak, never a 0.

=cut

sub stop {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t}      = $opts{timeout} if defined $opts{timeout};
  $params{signal} = $opts{signal}  if defined $opts{signal};
  return $self->_state_change("/containers/$id/stop", params => \%params);
}

=method stop

    $containers->stop($id, timeout => 10);

    say 'was already stopped' unless $containers->stop($id);

Stop a container. Returns 1 when the container was stopped and 0 when it was
already stopped -- the engine answers the no-op with B<304 Not Modified>. See
L</start> for what that 0 replaces.

Options:

=over

=item * C<timeout> - Seconds to wait before killing (default 10)

=item * C<signal> - Signal to send (default SIGTERM)

=back

=cut

sub restart {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t} = $opts{timeout} if defined $opts{timeout};
  return $self->_state_change("/containers/$id/restart", params => \%params);
}

=method restart

    $containers->restart($id, timeout => 10);

Restart a container. Optionally specify C<timeout> in seconds.

Reports 1/0 like L</start>, but a restart has no no-op state to report: the
engine restarts a stopped container as readily as a running one. Measured
against Podman 5.4.2 (API 1.41) it answers 204 in both cases, and the Docker
Engine API documents no 304 for this endpoint either, so 0 is not expected
here. The value is reported the same way rather than specially, so an engine
that does answer 304 is not silently read as a change.

=cut

sub kill {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{signal} = $opts{signal} if defined $opts{signal};
  return $self->client->post("/containers/$id/kill", undef, params => \%params);
}

=method kill

    $containers->kill($id, signal => 'SIGKILL');

Send a signal to a container. Default signal is C<SIGKILL>.

=cut

sub remove {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{v}     = $opts{volumes} ? 1 : 0 if defined $opts{volumes};
  $params{force} = $opts{force} ? 1 : 0   if defined $opts{force};
  $params{link}  = $opts{link} ? 1 : 0    if defined $opts{link};
  return $self->client->delete_request("/containers/$id", params => \%params);
}

=method remove

    $containers->remove($id, force => 1, volumes => 1);

Remove a container.

Options:

=over

=item * C<force> - Force removal (kill if running)

=item * C<volumes> - Remove associated volumes

=item * C<link> - Remove specified link

=back

=cut

sub logs {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{follow}     = $opts{follow} ? 1 : 0 if defined $opts{follow};
  $params{stdout}     = defined $opts{stdout} ? ($opts{stdout} ? 1 : 0) : 1;
  $params{stderr}     = defined $opts{stderr} ? ($opts{stderr} ? 1 : 0) : 1;
  $params{since}      = $opts{since}      if defined $opts{since};
  $params{until}      = $opts{until}      if defined $opts{until};
  $params{timestamps} = $opts{timestamps} ? 1 : 0 if defined $opts{timestamps};
  $params{tail}       = $opts{tail}       if defined $opts{tail};
  # exists, not truth: an unset callback is a caller bug, and quietly falling
  # back to the buffered path for it would answer a follow with a hang.
  return $self->client->stream_frames('GET', "/containers/$id/logs",
    params => \%params,
    defined $opts{tty} ? ( tty => $opts{tty} ) : (),
    exists $opts{on_frame} ? ( on_frame => $opts{on_frame} ) : (),
  );
}

=method logs

    my $frames = $containers->logs($id, tail => 100, timestamps => 1);

    # stdout and stderr, in the order the engine emitted them
    my $text = join '', map { $_->{data} } @$frames;

    # stderr only
    my @errors = grep { $_->{stream} eq 'stderr' } @$frames;

Get container logs. Returns an ArrayRef of frames, each a HashRef with
C<stream> and C<data>:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

A container created without a TTY multiplexes stdout and stderr into a single
framed stream, and this method demultiplexes it -- without that, the 8-byte
frame headers end up in the caller's log text. A container created B<with> a
TTY writes to one pty and the engine sends no frame headers, so its whole
output arrives as a single frame with C<< stream => 'raw' >>: with a TTY there
is no stdout/stderr distinction left to report. C<stream> is always a plain
string, so C<< $_->{stream} eq 'stderr' >> is safe on any frame.

Framing is detected from the response bytes, because the engine's
C<Content-Type> cannot be trusted for it -- see
L<API::Docker::Role::HTTP/"Detecting a framed stream"> for the rule and its one
failure mode.

Options:

=over

=item * C<follow> - Keep the connection open and send new output as the
container writes it. Only usable with C<on_frame>; see below

=item * C<stdout> - Include stdout (default 1)

=item * C<stderr> - Include stderr (default 1)

=item * C<since> - Show logs since timestamp

=item * C<until> - Show logs before timestamp

=item * C<timestamps> - Include timestamps

=item * C<tail> - Number of lines from end (e.g., C<100> or C<all>)

=item * C<tty> - Set to 1 when the container was created with a TTY and its
output is binary, to skip demultiplexing. Not needed for text output. The
container's own setting is C<Config.Tty> from C<< $containers->inspect($id) >>.
With C<on_frame> it is a declaration rather than a hint; see below

=item * C<on_frame> - CodeRef called with each frame as it arrives, instead of
the ArrayRef being collected and returned; see below

=back

=head2 Following the log

C<< follow => 1 >> asks the daemon to keep sending as the container writes.
Pass C<on_frame> with it and the frames are handed over as they arrive:

    my $summary = $containers->logs($id,
        follow   => 1,
        tail     => 0,
        on_frame => sub {
            my ($frame, $stop) = @_;
            print $frame->{data};
            $stop->() if $frame->{data} =~ /listening on/;
        },
    );

    $summary;   # { delivered => 4, stopped => 1 }

With a callback the return value is that summary HashRef, not the frames:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated --
a followed log is unbounded by construction, and the callback has been handed
every frame already. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

B<Without a callback, C<< follow => 1 >> blocks> until the container exits or
the daemon closes the connection, because the whole response is read before
anything is parsed. Use it with C<on_frame> or not at all.

C<tty> means something stronger on this path. The buffered path decides
framing by walking the whole body (see
L<API::Docker::Role::HTTP/"Detecting a framed stream">), which is exactly what
a streamed one does not have; so with C<on_frame> the flag is a promise about
the container rather than a hint, and an undeclared stream that turns out not
to be framed croaks instead of being handed back raw. Read C<Config.Tty> from
C<< $containers->inspect($id) >> and pass it. The frame shape is the same
either way -- a TTY stream arrives as a series of C<< stream => 'raw' >>
frames rather than the single one the buffered path builds.

=cut

sub attach {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{stream} = defined $opts{stream} ? ($opts{stream} ? 1 : 0) : 1;
  $params{stdout} = defined $opts{stdout} ? ($opts{stdout} ? 1 : 0) : 1;
  $params{stderr} = defined $opts{stderr} ? ($opts{stderr} ? 1 : 0) : 1;
  $params{stdin}  = $opts{stdin} ? 1 : 0 if defined $opts{stdin};
  $params{logs}   = $opts{logs}  ? 1 : 0 if defined $opts{logs};
  return $self->client->stream_frames('POST', "/containers/$id/attach",
    params => \%params,
    defined $opts{tty} ? ( tty => $opts{tty} ) : (),
    exists $opts{on_frame} ? ( on_frame => $opts{on_frame} ) : (),
  );
}

=method attach

    my $frames = $containers->attach($id);

    my $text = join '', map { $_->{data} } @$frames;

Attach to a container's streams and return everything they produced, as an
ArrayRef of frames in the same shape L</logs> returns:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

A container created without a TTY multiplexes its output into one framed
stream, which this method demultiplexes; one created with a TTY arrives as a
single C<< stream => 'raw' >> frame. See L</logs> and
L<API::Docker::Role::HTTP/"Detecting a framed stream">.

=head2 This is the one-way attach

The engine has two attach protocols behind one path. Sent with
C<Upgrade: tcp> and C<Connection: Upgrade>, C<< POST /containers/{id}/attach >>
answers B<101 Switching Protocols> and hands over a bidirectional connection:
that is what C<docker attach> uses, and it is what lets a caller type into the
container's stdin. Sent B<without> those headers -- which is what this method
does -- the engine answers B<200> and streams the container's output one way,
in exactly the frames L</logs> returns.

This method implements the second one only, because the transport here buffers
a whole response before returning it (see
L<API::Docker::Role::HTTP/"What the transport does not do">). Two consequences
a caller has to plan around:

=over

=item * B<You cannot write to the container.> C<< stdin => 1 >> is passed to
the engine, but this client sends no bytes after the request headers and then
reads until the daemon closes, so there is no moment at which input could be
supplied. Use L<API::Docker::API::Exec> to run something interactive-shaped,
or wait for the upgraded variant

=item * B<Without a callback it returns when the stream ends, not before.>
Attaching to a container that keeps running blocks until it exits or the
daemon closes the connection. Pass C<on_frame> to read it as it arrives and
stop where you like, exactly as L</logs> does under
L</"Following the log">; the return value is then the summary HashRef
C<< { delivered => N, stopped => 0|1 } >> rather than the frames, and C<tty>
becomes a declaration the transport takes at its word -- an undeclared
unframed stream croaks. For a running container that need not be attached to,
L</logs> with C<tail> reads the same output and returns immediately

=back

C</containers/{id}/attach/ws>, the WebSocket variant, is not implemented
either.

Options:

=over

=item * C<stream> - Stream output as the container produces it. Default 1.
B<The engine defaults it to false>, and with both C<stream> and C<logs> false
the response is empty -- so this method defaults it on, the way L</logs>
defaults its stdout and stderr on. Pass 0 to turn it off

=item * C<stdout> - Attach stdout. Default 1 (engine default: false)

=item * C<stderr> - Attach stderr. Default 1 (engine default: false)

=item * C<stdin> - Attach stdin. Sent as asked, but nothing can be written to
it here; see above

=item * C<logs> - Replay what the container has already written before
streaming what comes next

=item * C<tty> - Set to 1 when the container was created with a TTY and its
output is binary, to skip demultiplexing. Same meaning as in L</logs>, and
with C<on_frame> the same promise

=item * C<on_frame> - CodeRef called with each frame as it arrives, instead of
the ArrayRef being collected and returned. Same contract as in L</logs>

=back

=cut

sub top {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{ps_args} = $opts{ps_args} if defined $opts{ps_args};
  return $self->client->get("/containers/$id/top", params => \%params);
}

=method top

    my $processes = $containers->top($id, ps_args => 'aux');

List running processes in a container. Returns hashref with C<Titles> and C<Processes> arrays.

=cut

sub stats {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my $stream = $opts{stream} ? 1 : 0;
  my %params = ( stream => $stream );
  # one-shot asks the engine not to wait for a second sampling cycle, which
  # only means anything to a single reading. It is sent for the one-shot call
  # alone, the way it always was, and never beside stream => 1.
  $params{'one-shot'} = 1 unless $stream;
  return $self->client->get("/containers/$id/stats",
    params => \%params,
    exists $opts{on_event} ? ( on_event => $opts{on_event} )
      : $stream            ? ( ndjson   => 1 )
      : (),
  );
}

=method stats

    my $stats = $containers->stats($id);

Get container resource usage statistics (CPU, memory, network, I/O). With no
options this is the one-shot call it always was: a single reading, returned as
a HashRef.

=head2 Following the stats

C<< stream => 1 >> asks the engine for a reading per sampling cycle for as long
as the container runs. Pass C<on_event> with it and the readings are handed
over as they arrive:

    my $summary = $containers->stats($id,
        stream   => 1,
        on_event => sub {
            my ($stats, $stop) = @_;
            printf "%.1f MB\n", $stats->{memory_stats}{usage} / 1024 ** 2;
            $stop->() if ++$seen >= 5;
        },
    );

    $summary;   # { delivered => 5, stopped => 1 }

With a callback the return value is that summary HashRef, not the readings:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated.
See L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

B<Without a callback, C<< stream => 1 >> blocks> until the container stops or
the daemon closes the connection: the whole response is read before anything
is parsed. It then returns an ArrayRef of readings rather than the single
HashRef the one-shot call returns, which is the other reason to pass a
callback instead.

Unlike L<API::Docker::API::System/events>, this does not turn the stream's
error check off. C</events> is a feed of engine records, where an
C<errorDetail> object would still be data; a stats stream is one container's
readings, and the transport's default is to croak on a failure reported inside
a 200 body (L<API::Docker::Role::HTTP/"Failure inside a 200 response">).

The default is kept on a measurement rather than on that analogy. Against
Podman 5.4.2 (API 1.41) every object a running container's stream carries is
a complete reading -- C<read>, C<cpu_stats>, C<memory_stats>, C<networks> and
the rest -- and killing the container and then removing it while the stream
was open ended the stream on a whole reading, with nothing appended after it.
No C<errorDetail> was sent in either case, and the Engine API reference names
that key for C</build>, C</images/create> and C</images/{name}/push> alone.
So the check has no legitimate reading here it could turn into a croak, and
that -- not an unexamined default -- is why it stays on.

Options:

=over

=item * C<stream> - Ask for a reading per sampling cycle instead of one.
Defaults off and is always sent, so a call with no options is the single
reading it has always been

=item * C<on_event> - CodeRef called with each reading as it arrives, instead
of them being collected and returned; see above

=back

=head2 A container that is not running answers 200 with an error object

Podman refuses the stats of a stopped container B<inside> a 200 response, and
not in the shape the error check looks for:

    { cause    => 'container is stopped',
      message  => 'container is stopped',
      response => 500 }

Measured for the one-shot call and for C<< stream => 1 >> alike: chunked, with
the status line already committed to 200. The stream check triggers on
C<errorDetail> and on nothing else, so this passes it -- the one-shot call
returns that HashRef where a reading was expected, and a callback is handed it
as though it were a reading. Where the container may have stopped, test for
C<read> or C<cpu_stats> before using what comes back.

=cut

sub changes {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  my $result = $self->client->get("/containers/$id/changes");
  # A container with nothing changed answers with a JSON null, which the
  # transport decodes to undef. Normalised here so the return is always
  # something a caller can iterate.
  return ref $result eq 'ARRAY' ? $result : [];
}

=method changes

    for my $change (@{ $containers->changes($id) }) {
        say $KIND[ $change->{Kind} ], ' ', $change->{Path};
    }

Report which paths in the container's filesystem differ from the image it was
created from -- the endpoint behind C<docker diff>. Returns an ArrayRef of
HashRefs, each with C<Path> and C<Kind>:

    [ { Path => '/etc/hostname', Kind => 0 },
      { Path => '/tmp/new',      Kind => 1 },
      { Path => '/etc/gone',     Kind => 2 } ]

C<Kind> is an integer, not a word, and the engine documents no names for the
three values:

=over

=item * C<0> - B<modified>. The path exists in both and its contents or
metadata changed

=item * C<1> - B<added>. The path exists only in the container

=item * C<2> - B<deleted>. The path existed in the image and is gone

=back

A container with nothing changed comes back as an empty ArrayRef; the engine
answers that case with a JSON C<null> rather than an empty list.

Measured against Podman 5.4.2 (API 1.41): the endpoint is served, but an
unknown container is answered with B<500> and
C<< {"cause":"layer not known","message":"<id> not found: layer not known"} >>
rather than the 404 every other container endpoint gives -- so a caller
distinguishing "no such container" from a real failure cannot do it on the
status code alone on that engine.

=cut

sub export {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->client->get("/containers/$id/export", raw => 1);
}

=method export

    use Path::Tiny;
    path('container.tar')->spew_raw($containers->export($id));

Export the container's whole filesystem as a tar archive -- the endpoint
behind C<docker export>. Returns the raw archive bytes, never decoded and
never modified.

The archive is buffered whole in memory, so this costs the size of the
container's filesystem in RAM. There is no streaming variant here.

Unlike L<API::Docker::API::Images/get>, the result is a plain filesystem tar:
no C<manifest.json>, no layers, no image metadata. L<API::Docker::API::Images/load>
will not take it back -- importing a flat filesystem is
C<< POST /images/create?fromSrc=- >>, which this distribution does not expose.

=cut

sub resize {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{h} = $opts{h} if defined $opts{h};
  $params{w} = $opts{w} if defined $opts{w};
  return $self->client->post("/containers/$id/resize", undef, params => \%params);
}

=method resize

    $containers->resize($id, h => 40, w => 120);

Resize the TTY of a container, so a program inside it sees the new terminal
size. Form-identical to L<API::Docker::API::Exec/resize>, which resizes the
TTY of an exec instance instead.

Only meaningful for a container created with C<< Tty => 1 >>; the engine
rejects the call otherwise.

Options:

=over

=item * C<h> - New height in character rows

=item * C<w> - New width in character columns

=back

=cut

sub wait {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{condition} = $opts{condition} if defined $opts{condition};
  return $self->client->post("/containers/$id/wait", undef, params => \%params);
}

=method wait

    my $result = $containers->wait($id, condition => 'not-running');

Block until container stops, then return exit code. Optional C<condition> parameter.

=cut

sub pause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/pause");
}

=method pause

    $containers->pause($id);

Pause all processes in a container.

Reports 1/0 like L</start>, but pausing an already-paused container is an
error rather than a 304: measured against Podman 5.4.2 (API 1.41) it answers
C<500> with C<< "..." is already paused: container state improper >>, which
croaks. The Docker Engine API documents no 304 for this endpoint either. So
this method returns 1 or croaks in practice.

=cut

sub unpause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->_state_change("/containers/$id/unpause");
}

=method unpause

    $containers->unpause($id);

Unpause all processes in a container. Reports 1/0 like L</start>; as with
L</pause>, the no-op is an error and not a 304 -- Podman 5.4.2 answers
unpausing a running container with C<500>.

=cut

sub rename {
  my ($self, $id, $name) = @_;
  croak "Container ID required" unless $id;
  croak "New name required" unless $name;
  return $self->client->post("/containers/$id/rename", undef, params => { name => $name });
}

=method rename

    $containers->rename($id, 'new-name');

Rename a container.

=cut

sub update {
  my ($self, $id, %config) = @_;
  croak "Container ID required" unless $id;
  return $self->client->post("/containers/$id/update", \%config);
}

=method update

    $containers->update($id, Memory => 314572800);

Update container resource limits and configuration.

=cut

# The engine reports what a path is in a response header rather than a body,
# so both GET and HEAD carry it and only HEAD has nothing else to say. The
# header is base64-encoded JSON; handing the caller the base64 would make
# every one of them write this.
sub _decode_path_stat {
  my ($self, $response) = @_;

  my $header = $response->{headers}{'x-docker-container-path-stat'};
  return undef unless defined $header && length $header;

  # Docker encodes this one with Go's base64.StdEncoding -- unlike
  # X-Registry-Auth, which is URLEncoding. Decoded tolerantly rather than
  # strictly: translating the two URL-safe characters first costs nothing and
  # means an engine that reached for the other alphabet is still read.
  $header =~ tr{-_}{+/};
  my $stat = eval { decode_json(decode_base64($header)) };
  croak "Cannot decode X-Docker-Container-Path-Stat header: $@"
    unless ref $stat eq 'HASH';

  return $stat;
}

sub get_archive {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};
  croak "The stat option must be a HashRef"
    if exists $opts{stat} && ref $opts{stat} ne 'HASH';

  my %response;
  my $tar = $self->client->get("/containers/$id/archive",
    params   => { path => $opts{path} },
    raw      => 1,
    response => \%response,
  );

  if (my $out = $opts{stat}) {
    %$out = %{ $self->_decode_path_stat(\%response) // {} };
  }

  return $tar;
}

=method get_archive

    use Path::Tiny;
    my $tar = $containers->get_archive($id, path => '/etc/hostname');
    path('hostname.tar')->spew_raw($tar);

    # and what the path was, without a second request
    my %stat;
    my $tar = $containers->get_archive($id, path => '/var/log', stat => \%stat);
    say $stat{name};

Read a path out of a container as a tar archive -- the outbound half of
C<docker cp>. Returns the raw archive bytes, never decoded and never modified.

A file comes back as a one-member archive named after its basename; a
directory comes back as the directory and everything under it, with paths
relative to its parent. The whole archive is buffered in memory.

Options:

=over

=item * C<path> - Path inside the container to read. Required

=item * C<stat> - HashRef the C<X-Docker-Container-Path-Stat> header is
decoded into. The engine sends it on this response as well as on the HEAD
one, so asking for it here saves the extra round trip L</stat_archive> would
cost. Emptied when the engine sent no such header. See L</stat_archive> for
the keys

=back

=cut

sub put_archive {
  my ($self, $id, $tar, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};
  croak "Tar archive required (raw bytes or a scalar ref)" unless defined $tar;

  my %params = ( path => $opts{path} );
  $params{noOverwriteDirNonDir} = $opts{noOverwriteDirNonDir} ? 1 : 0
    if defined $opts{noOverwriteDirNonDir};
  $params{copyUIDGID} = $opts{copyUIDGID} ? 1 : 0
    if defined $opts{copyUIDGID};

  my $raw = ref $tar eq 'SCALAR' ? $$tar : $tar;

  return $self->client->put("/containers/$id/archive", undef,
    params       => \%params,
    raw_body     => $raw,
    content_type => 'application/x-tar',
  );
}

=method put_archive

    use Path::Tiny;
    $containers->put_archive($id, path('payload.tar')->slurp_raw,
        path => '/opt/app');

Write a tar archive into a path inside the container -- the inbound half of
C<docker cp>. The archive is the request body; pass it as raw bytes or as a
scalar reference to them, the way L<API::Docker::API::Images/load> takes its
archive. Returns nothing: the engine answers a success with an empty body.

C<path> must name a B<directory that already exists> in the container; the
archive's members are unpacked into it. Writing a single file means putting
that file in a one-member archive and naming its parent directory as C<path> --
there is no "write these bytes to this filename" form of this endpoint.

The archive is sent as one buffered request body, so this costs its full size
in RAM.

Options:

=over

=item * C<path> - Directory inside the container to unpack into. Required

=item * C<noOverwriteDirNonDir> - Refuse the request rather than replace an
existing directory with a non-directory, or the other way round. Without it
the engine replaces either with the other

=item * C<copyUIDGID> - Keep the UID and GID recorded in the archive instead
of mapping the members to the container user

=back

=cut

sub stat_archive {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  croak "Path required" unless defined $opts{path} && length $opts{path};

  my %response;
  $self->client->head("/containers/$id/archive",
    params   => { path => $opts{path} },
    response => \%response,
  );

  return $self->_decode_path_stat(\%response);
}

=method stat_archive

    my $stat = $containers->stat_archive($id, path => '/etc/hostname');

    say $stat->{name};                        # hostname
    say $stat->{size};                        # 13
    printf "%04o\n", $stat->{mode} & 0777;    # 0644

Stat a path inside a container without transferring it -- C<HEAD> on the same
endpoint L</get_archive> uses. Returns a HashRef, or C<undef> when the engine
answered without the header. A path that does not exist is a croak from the
transport's status handling, not an C<undef>.

The response has no body at all: the answer is the
C<X-Docker-Container-Path-Stat> header, base64-encoded JSON, which this method
decodes. Its keys are the engine's, passed through as they arrive:

=over

=item * C<name> - The path's basename

=item * C<size> - Size in bytes

=item * C<mode> - Go's C<os.FileMode> bits, B<not> a POSIX mode word. The
permission bits are the low nine (C<< $stat->{mode} & 0777 >>); the type bits
above them are Go's own numbering, so C<0x80000000> is a directory rather than
C<S_IFDIR>

=item * C<mtime> - Modification time, RFC 3339

=item * C<linkTarget> - Target of a symlink, empty otherwise

=back

Those key names are the Docker Engine API's. They are not verified against
Podman here: reading them needs a container to stat, and the work that added
this method was held to read-only probes. What B<was> measured against Podman
5.4.2 (API 1.41) is that the route is served, that it answers an unknown
container with 404, and that its 404 announces a C<Content-Length> while
sending no body -- which is why L<API::Docker::Role::HTTP/head> never reads
one.

Options:

=over

=item * C<path> - Path inside the container to stat. Required

=back

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/containers/prune', undef, params => \%params);
}

=method prune

    my $result = $containers->prune(filters => { until => ['24h'] });

Delete stopped containers. Returns hashref with C<ContainersDeleted> and C<SpaceReclaimed>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<until> and C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Container> - Container entity class

=item * L<API::Docker::API::Exec> - Execute commands in containers

=back

=cut

1;
