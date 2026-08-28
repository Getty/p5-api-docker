package API::Docker::Type::ImageConfig;
# ABSTRACT: Configuration of the image
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::HealthConfig;

=head1 DESCRIPTION

Generated from the C<ImageConfig> definition of C<spec/v1.51.yaml>.

These fields are used as defaults when starting a container from the image.

=cut

docker user => Str;

=attr user

The user that commands are run as inside the container.

=cut

docker exposed_ports => { Str, Any };

=attr exposed_ports

An object mapping ports to an empty object in the form:

C<< {"<port>/<tcp|udp|sctp>": {}} >> B<The keys are the caller's data> and
are never translated.

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

docker shell => [Str];

=attr shell

Shell for when C<RUN>, C<CMD>, and C<ENTRYPOINT> uses a shell.

=cut

1;
