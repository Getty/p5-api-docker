package API::Docker::Type::SwarmSpec::EncryptionConfig;
# ABSTRACT: Parameters related to encryption-at-rest
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<EncryptionConfig> schema of the C<SwarmSpec>
definition in C<spec/v1.51.yaml>.

=cut

docker auto_lock_managers => Bool;

=attr auto_lock_managers

If set, generate a key and use it to lock data stored on the managers.

=cut

1;
