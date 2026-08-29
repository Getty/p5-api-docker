package API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec;
# ABSTRACT: CredentialSpec for managed service account (Windows only)
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<CredentialSpec> schema of
C<TaskSpec.ContainerSpec.Privileges> in C<spec/v1.51.yaml>.

=cut

docker config => Str;

=attr config

Load credential spec from a Swarm Config with the given ID. The specified
config must also be present in the Configs field with the Runtime property
set.

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

=cut

docker file => Str;

=attr file

Load credential spec from this file. The file is read by the daemon, and
must be present in the C<CredentialSpecs> subdirectory in the docker data
directory, which defaults to C<C:\ProgramData\Docker\> on Windows.

For example, specifying C<spec.json> loads
C<C:\ProgramData\Docker\CredentialSpecs\spec.json>.

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

=cut

docker registry => Str;

=attr registry

Load credential spec from this value in the Windows registry. The specified
registry value must be located in:

C<HKLM\SOFTWARE\Microsoft\Windows
NT\CurrentVersion\Virtualization\Containers\CredentialSpecs>

> B<Note>: C<CredentialSpec.File>, C<CredentialSpec.Registry>, > and
C<CredentialSpec.Config> are mutually exclusive.

=cut

1;
