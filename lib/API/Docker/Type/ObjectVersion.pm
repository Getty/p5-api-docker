package API::Docker::Type::ObjectVersion;
# ABSTRACT: The version number of the object such as node, service, etc
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ObjectVersion> definition of C<spec/v1.51.yaml>.

This is needed to avoid conflicting writes. The client must send the version
number along with the modified specification when updating these objects.

This approach ensures safe concurrency and determinism in that the change on
the object may not be applied if the version number has changed from the
last read. In other words, if two update requests specify the same base
version, only one of the requests can succeed. As a result, two separate
update requests that happen at the same time will not unintentionally
overwrite each other.

=cut

docker index => Int;

=attr index

Undocumented upstream. The version number itself, the one the definition
above says must travel back with a modified specification so that two
updates from the same base version cannot overwrite each other. The
swagger's example is C<373531>; the C<GET /secrets> capture in
F<t/fixtures/secrets_list.json>, from Podman 5.4.2 (API 1.41), has C<1> on
both secrets. L<API::Docker::Role::Entity::Secret> and
L<API::Docker::Role::Entity::Config> read it out as C<version_index>.

=cut

1;
