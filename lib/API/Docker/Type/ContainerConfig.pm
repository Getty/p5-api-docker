package API::Docker::Type::ContainerConfig;
# ABSTRACT: Configuration for a container that is portable between hosts
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;

=head1 DESCRIPTION

Generated from the C<ContainerConfig> definition of C<spec/v1.51.yaml>.

=cut

docker hostname => Str;

=attr hostname

The hostname to use for the container, as a valid RFC 1123 hostname.

=cut

docker domainname => Str;

=attr domainname

The domain name to use for the container.

=cut

docker user => Str;

=attr user

Commands run as this user inside the container. If omitted, commands run as
the user specified in the image the container was started from.

Can be either user-name or UID, and optional group-name or GID, separated by
a colon (C<< <user-name|UID>[<:group-name|GID>] >>).

=cut

docker attach_stdin => Bool;

=attr attach_stdin

Whether to attach to C<stdin>. The daemon defaults it to false.

=cut

docker attach_stdout => Bool;

=attr attach_stdout

Whether to attach to C<stdout>. The daemon defaults it to true.

=cut

docker attach_stderr => Bool;

=attr attach_stderr

Whether to attach to C<stderr>. The daemon defaults it to true.

=cut

docker exposed_ports => { Str, Any };

=attr exposed_ports

An object mapping ports to an empty object in the form:

C<< {"<port>/<tcp|udp|sctp>": {}} >> B<The keys are the caller's data> and
are never translated.

=cut

docker tty => Bool;

=attr tty

Attach standard streams to a TTY, including C<stdin> if it is not closed.
The daemon defaults it to false.

=cut

docker open_stdin => Bool;

=attr open_stdin

Open C<stdin> The daemon defaults it to false.

=cut

docker stdin_once => Bool;

=attr stdin_once

Close C<stdin> after one attached client disconnects. The daemon defaults it
to false.

=cut

docker env => [Str];

=attr env

A list of environment variables to set inside the container in the form
C<["VAR=value", ...]>. A variable without C<=> is removed from the
environment, rather than to have an empty value.

=cut

docker cmd => [Str];

=attr cmd

Command to run specified as a string or an array of strings.

=cut

docker healthcheck => 'HealthConfig';

=attr healthcheck

A test to perform to check that the container is healthy. See
L<API::Docker::Type::HealthConfig>.

=cut

docker args_escaped => Bool;

=attr args_escaped

Command is already escaped (Windows only). The daemon defaults it to false.

=cut

docker image => Str;

=attr image

The name (or reference) of the image to use when creating the container, or
which was used when the container was created.

=cut

docker volumes => { Str, Any };

=attr volumes

An object mapping mount point paths inside the container to empty objects.
B<The keys are the caller's data> and are never translated.

=cut

docker working_dir => Str;

=attr working_dir

The working directory for commands to run in.

=cut

docker entrypoint => [Str];

=attr entrypoint

The entry point for the container as a string or an array of strings.

If the array consists of exactly one empty string (C<[""]>) then the entry
point is reset to system default (i.e., the entry point used by docker when
there is no C<ENTRYPOINT> instruction in the C<Dockerfile>).

=cut

docker network_disabled => Bool;

=attr network_disabled

Disable networking for the container.

=cut

docker mac_address => Str;

=attr mac_address

MAC address of the container.

Deprecated: this field is deprecated in API v1.44 and up. Use
EndpointSettings.MacAddress instead.

=cut

docker on_build => [Str];

=attr on_build

C<ONBUILD> metadata that were defined in the image's C<Dockerfile>.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker stop_signal => Str;

=attr stop_signal

Signal to stop a container as a string or unsigned integer.

=cut

docker stop_timeout => Int;

=attr stop_timeout

Timeout to stop a container in seconds. The daemon defaults it to 10.

=cut

docker shell => [Str];

=attr shell

Shell for when C<RUN>, C<CMD>, and C<ENTRYPOINT> uses a shell.

=cut

1;
