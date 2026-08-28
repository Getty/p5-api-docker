package API::Docker::Type::TaskSpec::ContainerSpec::Secret;
# ABSTRACT: One entry of C<TaskSpec.ContainerSpec.Secrets>
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::ContainerSpec::Secret::File;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.ContainerSpec.Secrets> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker file => 'TaskSpec::ContainerSpec::Secret::File';

=attr file

File represents a specific target that is backed by a file. See
L<API::Docker::Type::TaskSpec::ContainerSpec::Secret::File>.

=cut

docker secret_id => Str, wire => 'SecretID';

=attr secret_id

SecretID represents the ID of the specific secret that we're referencing.
Serialised as C<SecretID> -- spelled out, because deriving it from the Perl
name would produce C<SecretId>.

=cut

docker secret_name => Str;

=attr secret_name

SecretName is the name of the secret that this references, but this is just
provided for lookup/display purposes. The secret in the reference will be
identified by its ID.

=cut

1;
