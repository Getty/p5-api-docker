package API::Docker::Type::ObjectVersion;
# ABSTRACT: The version number of the object such as node, service, etc
our $VERSION = '0.004';
use API::Docker::Type;

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

Undocumented upstream.

=cut

1;
