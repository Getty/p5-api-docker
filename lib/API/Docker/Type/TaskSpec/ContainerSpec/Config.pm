package API::Docker::Type::TaskSpec::ContainerSpec::Config;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Configs>
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Config::File;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Configs> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker file => 'TaskSpec::ContainerSpec::Config::File';

=attr file

File represents a specific target that is backed by a file.

> B<Note>: C<Configs.File> and C<Configs.Runtime> are mutually exclusive.
See L<API::Docker::Type::TaskSpec::ContainerSpec::Config::File>.

=cut

docker runtime => Any;

=attr runtime

Runtime represents a target that is not mounted into the container but is
used by the task

> B<Note>: C<Configs.File> and C<Configs.Runtime> are mutually > exclusive.

=cut

docker config_id => Str, wire => 'ConfigID';

=attr config_id

ConfigID represents the ID of the specific config that we're referencing.
Serialised as C<ConfigID> -- spelled out, because deriving it from the Perl
name would produce C<ConfigId>.

=cut

docker config_name => Str;

=attr config_name

ConfigName is the name of the config that this references, but this is just
provided for lookup/display purposes. The config in the reference will be
identified by its ID.

=cut

1;
