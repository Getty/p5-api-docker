package API::Docker::Type::TaskSpec::ContainerSpec::Privileges;
# ABSTRACT: Security options for the container
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext;
use API::Docker::Type::TaskSpec::ContainerSpec::Privileges::Seccomp;

=head1 DESCRIPTION

Generated from the inline C<Privileges> schema of C<TaskSpec.ContainerSpec>
in C<spec/v1.51.yaml>.

=cut

docker credential_spec => 'TaskSpec::ContainerSpec::Privileges::CredentialSpec',
  ;

=attr credential_spec

CredentialSpec for managed service account (Windows only). See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::CredentialSpec>.

=cut

docker selinux_context => 'TaskSpec::ContainerSpec::Privileges::SELinuxContext',
  wire => 'SELinuxContext';

=attr selinux_context

SELinux labels of the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::SELinuxContext>.
Serialised as C<SELinuxContext> -- spelled out, because deriving it from the
Perl name would produce C<SelinuxContext>.

=cut

docker seccomp => 'TaskSpec::ContainerSpec::Privileges::Seccomp',
  since => '1.44';

=attr seccomp

Options for configuring seccomp on the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::Seccomp>.

=cut

docker app_armor => 'TaskSpec::ContainerSpec::Privileges::AppArmor',
  since => '1.44';

=attr app_armor

Options for configuring AppArmor on the container. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Privileges::AppArmor>.

=cut

docker no_new_privileges => Bool, since => '1.44';

=attr no_new_privileges

Configuration of the no_new_privs bit in the container.

=cut

1;
