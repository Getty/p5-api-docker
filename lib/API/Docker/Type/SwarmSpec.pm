package API::Docker::Type::SwarmSpec;
# ABSTRACT: User modifiable swarm configuration
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::SwarmSpec::CAConfig;
use API::Docker::Type::SwarmSpec::Dispatcher;
use API::Docker::Type::SwarmSpec::EncryptionConfig;
use API::Docker::Type::SwarmSpec::Orchestration;
use API::Docker::Type::SwarmSpec::Raft;
use API::Docker::Type::SwarmSpec::TaskDefaults;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<SwarmSpec> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str;

=attr name

Name of the swarm.

=cut

docker labels => { Str, Str };

=attr labels

User-defined key/value metadata. B<The keys are the caller's data> and are
never translated.

=cut

docker orchestration => 'SwarmSpec::Orchestration';

=attr orchestration

Orchestration configuration. See
L<API::Docker::Type::SwarmSpec::Orchestration>.

=cut

docker raft => 'SwarmSpec::Raft';

=attr raft

Raft configuration. See L<API::Docker::Type::SwarmSpec::Raft>.

=cut

docker dispatcher => 'SwarmSpec::Dispatcher';

=attr dispatcher

Dispatcher configuration. See L<API::Docker::Type::SwarmSpec::Dispatcher>.

=cut

docker ca_config => 'SwarmSpec::CAConfig', wire => 'CAConfig';

=attr ca_config

CA configuration. See L<API::Docker::Type::SwarmSpec::CAConfig>. Serialised
as C<CAConfig> -- spelled out, because deriving it from the Perl name would
produce C<CaConfig>.

=cut

docker encryption_config => 'SwarmSpec::EncryptionConfig';

=attr encryption_config

Parameters related to encryption-at-rest. See
L<API::Docker::Type::SwarmSpec::EncryptionConfig>.

=cut

docker task_defaults => 'SwarmSpec::TaskDefaults';

=attr task_defaults

Defaults for creating tasks in this cluster. See
L<API::Docker::Type::SwarmSpec::TaskDefaults>.

=cut

1;
