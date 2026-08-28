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

Undocumented upstream.

=cut

docker labels => { Str, Str };

=attr labels

Undocumented upstream. B<The keys are the caller's data> and are never
translated.

=cut

docker plugins => [ 'EngineDescription::Plugin' ];

=attr plugins

Undocumented upstream. See L<API::Docker::Type::EngineDescription::Plugin>.

=cut

1;
