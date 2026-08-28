package API::Docker::API::Exec;
# ABSTRACT: Docker Engine Exec API
our $VERSION = '0.004';
use Moo;
use Carp qw( croak );
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create an exec instance
    my $exec = $docker->exec->create($container_id,
        Cmd         => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
    );

    # Start the exec -- ArrayRef of { stream => ..., data => ... } frames
    my $frames = $docker->exec->start($exec->{Id});
    my $output = join '', map { $_->{data} } @$frames;

    # The exit status comes from a separate call
    my $exit = $docker->exec->inspect($exec->{Id})->{ExitCode};

    # Inspect exec instance
    my $info = $docker->exec->inspect($exec->{Id});

=head1 DESCRIPTION

This module provides methods for executing commands inside running containers
using the Docker Exec API.

Accessed via C<< $docker->exec >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub create {
  my ($self, $container_id, %config) = @_;
  croak "Container ID required" unless $container_id;
  croak "Cmd required" unless $config{Cmd};
  return $self->client->post("/containers/$container_id/exec", \%config);
}

=method create

    my $exec = $exec->create($container_id,
        Cmd          => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
        Tty          => 0,
    );

Create an exec instance. Returns hashref with C<Id>.

Required config: C<Cmd> (ArrayRef of command and arguments).

Common config keys: C<AttachStdin>, C<AttachStdout>, C<AttachStderr>, C<Tty>,
C<Env>, C<User>, C<WorkingDir>.

=cut

sub start {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my $body = {
    Detach => $opts{Detach} ? \1 : \0,
    Tty    => $opts{Tty}    ? \1 : \0,
  };
  # exists, not truth: an unset callback is a caller bug, and falling back to
  # the buffered path for it would answer a long-running command by waiting
  # for it in silence. Handed over as it is, the transport says so instead.
  return $self->client->stream_frames('POST', "/exec/$exec_id/start",
    body => $body,
    $opts{Tty} ? ( tty => 1 ) : (),
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
    exists $opts{on_frame} ? ( on_frame => $opts{on_frame} ) : (),
  );
}

=method start

    my $frames = $exec->start($exec_id, Detach => 0);

    my $output = join '', map { $_->{data} } @$frames;

Start an exec instance. Returns an ArrayRef of frames in the same shape as
L<API::Docker::API::Containers/logs>:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

An exec instance created without a TTY multiplexes stdout and stderr into one
framed stream, which this method demultiplexes. One created with a TTY has no
frame headers and its output arrives as a single C<< stream => 'raw' >> frame.
A detached start produces no output, so it returns an empty ArrayRef.

The exit status is B<not> part of this response. It comes from a separate call
once the exec has finished:

    my $exit = $exec->inspect($exec_id)->{ExitCode};

Options:

=over

=item * C<Detach> - Run detached; the engine returns immediately and no output
is streamed

=item * C<Tty> - Declares that this exec instance was created with a TTY. It is
sent in the request body, where the engine expects it to match the C<Tty> given
to L</create>, and it also suppresses demultiplexing of the response. Framing is
otherwise detected from the response bytes -- see
L<API::Docker::Role::HTTP/"Detecting a framed stream">

=item * C<on_frame> - CodeRef called with each frame as it arrives, instead of
the ArrayRef being collected and returned; see below

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=head2 Watching the output as it is produced

Without a callback this returns when the command has finished and the daemon
has closed the stream -- a command that runs for a minute is a minute of
silence, and one that never finishes never returns. Pass C<on_frame> and the
frames are handed over as they arrive:

    my $summary = $exec->start($exec_id,
        on_frame => sub {
            my ($frame, $stop) = @_;
            print $frame->{data};
            $stop->() if $frame->{data} =~ /ready/;
        },
    );

    $summary;   # { delivered => 9, stopped => 1 }

With a callback the return value is that summary HashRef, not the frames:
C<delivered> is how many went to the callback, C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated,
so joining the output is the callback's job. See
L<API::Docker::Role::HTTP/"Streaming a response as it arrives">.

A detached start produces no output, so its summary is
C<< { delivered => 0, stopped => 0 } >> where the buffered call returns an
empty ArrayRef.

C<Tty> means something stronger on this path. The buffered path decides
framing by walking the whole body, which is exactly what a streamed one does
not have; so with C<on_frame> it is a promise about the exec instance rather
than a hint, and an undeclared stream that turns out not to be framed croaks
instead of being handed back raw. Pass the same C<Tty> that went to L</create>
-- the engine expects them to agree in any case.

=cut

sub resize {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my %params;
  $params{h} = $opts{h} if defined $opts{h};
  $params{w} = $opts{w} if defined $opts{w};
  return $self->client->post("/exec/$exec_id/resize", undef,
    params => \%params,
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
}

=method resize

    $exec->resize($exec_id, h => 40, w => 120);

Resize the TTY for an exec instance.

Options:

=over

=item * C<h> - New height in character rows

=item * C<w> - New width in character columns

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

sub inspect {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  return $self->client->get("/exec/$exec_id/json",
    exists $opts{read_timeout} ? ( read_timeout => $opts{read_timeout} ) : (),
    exists $opts{connect_timeout} ? ( connect_timeout => $opts{connect_timeout} ) : (),
  );
}

=method inspect

    my $info = $exec->inspect($exec_id);

Get information about an exec instance.

Options:

=over

=item * C<read_timeout> - Seconds of silence after which the request gives up
and croaks with an L<API::Docker::Error::Timeout>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding a request that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Off by default; see
L<API::Docker::Role::HTTP/"Bounding the connection itself">

=back

=cut

=seealso

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::API::Containers> - Container management

=back

=cut

1;
