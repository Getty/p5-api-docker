package API::Docker::Type::VolumeListResponse;
# ABSTRACT: Volume list response
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::Volume;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<VolumeListResponse> definition of C<spec/v1.51.yaml>.

=cut

docker volumes => [ 'Volume' ];

=attr volumes

List of volumes. See L<API::Docker::Type::Volume>.

=cut

docker warnings => [Str];

=attr warnings

Warnings that occurred when fetching the list of volumes.

=cut

1;
