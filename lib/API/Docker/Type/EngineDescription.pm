package API::Docker::Type::EngineDescription;
# ABSTRACT: EngineDescription provides information about an engine
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::EngineDescription::Plugin;

=head1 DESCRIPTION

Generated from the C<EngineDescription> definition of C<spec/v1.51.yaml>.

=cut

docker engine_version => Str;

=attr engine_version

Undocumented upstream. The engine's version as the node's agent reports it,
C<17.06.0> in the swagger's example -- the value C<GET /version> answers as
L<API::Docker::Type::SystemVersion/version>.

=cut

docker labels => { Str, Str };

=attr labels

Undocumented upstream. The engine's own labels, C<< {"foo": "bar"} >> in the
swagger's example. These are the C<engine.labels> a task placement
constraint can match on; see
L<API::Docker::Type::TaskSpec::Placement/constraints>. B<The keys are the
caller's data> and are never translated.

=cut

docker plugins => [ 'EngineDescription::Plugin' ];

=attr plugins

Undocumented upstream. One entry per plugin the engine has. The swagger's
example lists seventeen -- eight C<Log>, six C<Network> and three C<Volume>.
C<GET /info> reports the same ground in a different shape, as
L<API::Docker::Type::PluginsInfo>. See
L<API::Docker::Type::EngineDescription::Plugin>.

=cut

1;
