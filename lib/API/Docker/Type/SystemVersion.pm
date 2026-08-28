package API::Docker::Type::SystemVersion;
# ABSTRACT: Response of Engine API: GET "/version"
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::SystemVersion::Component;
use API::Docker::Type::SystemVersion::Platform;

=head1 DESCRIPTION

Generated from the C<SystemVersion> definition of C<spec/v1.51.yaml>.

=cut

docker platform => 'SystemVersion::Platform';

=attr platform

Undocumented upstream. One field, a name the engine gives itself. What the
two engines put in it has nothing in common; see
L<API::Docker::Type::SystemVersion::Platform/name>. See
L<API::Docker::Type::SystemVersion::Platform>.

=cut

docker components => [ 'SystemVersion::Component' ];

=attr components

Information about system components. See
L<API::Docker::Type::SystemVersion::Component>.

=cut

docker version => Str;

=attr version

The version of the daemon.

=cut

docker api_version => Str;

=attr api_version

The default (and highest) API version that is supported by the daemon.

=cut

docker min_api_version => Str, wire => 'MinAPIVersion';

=attr min_api_version

The minimum API version that is supported by the daemon. Serialised as
C<MinAPIVersion> -- spelled out, because deriving it from the Perl name
would produce C<MinApiVersion>.

=cut

docker git_commit => Str;

=attr git_commit

The Git commit of the source code that was used to build the daemon.

=cut

docker go_version => Str;

=attr go_version

The version Go used to compile the daemon, and the version of the Go runtime
in use.

=cut

docker os => Str;

=attr os

The operating system that the daemon is running on ("linux" or "windows").

=cut

docker arch => Str;

=attr arch

Architecture of the daemon, as returned by the Go runtime (C<GOARCH>).

A full list of possible values can be found in the L<Go
documentation|https://go.dev/doc/install/source#environment>.

=cut

docker kernel_version => Str;

=attr kernel_version

The kernel version (C<uname -r>) that the daemon is running on.

This field is omitted when empty.

=cut

docker experimental => Bool;

=attr experimental

Indicates if the daemon is started with experimental features enabled.

This field is omitted when empty / false.

=cut

docker build_time => Str;

=attr build_time

The date and time that the daemon was compiled.

=cut

1;
