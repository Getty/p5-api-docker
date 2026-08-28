package API::Docker::Type::Runtime;
# ABSTRACT: An L<OCI compliant|https://github.com/opencontainers/runtime-spec> runtime
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<Runtime> definition of C<spec/v1.51.yaml>.

The runtime is invoked by the daemon via the C<containerd> daemon. OCI
runtimes act as an interface to the Linux kernel namespaces, cgroups, and
SELinux.

=cut

docker path => Str, wire => 'path';

=attr path

Name and, optional, path, of the OCI executable binary.

If the path is omitted, the daemon searches the host's C<$PATH> for the
binary and uses the first result. Serialised as C<path> -- spelled out,
because deriving it from the Perl name would produce C<Path>.

=cut

docker runtime_args => [Str], wire => 'runtimeArgs';

=attr runtime_args

List of command-line arguments to pass to the runtime when invoked.
Serialised as C<runtimeArgs> -- spelled out, because deriving it from the
Perl name would produce C<RuntimeArgs>.

=cut

docker status => { Str, Str }, wire => 'status', since => '1.44';

=attr status

Information specific to the runtime.

While this API specification does not define data provided by runtimes, the
following well-known properties may be provided by runtimes:

C<org.opencontainers.runtime-spec.features>: features structure as defined
in the L<OCI Runtime
Specification|https://github.com/opencontainers/runtime-spec/blob/main/features.md>,
in a JSON string representation.

> B<Note>: The information returned in this field, including the >
formatting of values and labels, should not be considered stable, > and may
change without notice. B<The keys are the caller's data> and are never
translated. Serialised as C<status> -- spelled out, because deriving it from
the Perl name would produce C<Status>.

=cut

1;
