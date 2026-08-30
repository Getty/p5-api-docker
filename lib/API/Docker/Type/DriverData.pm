package API::Docker::Type::DriverData;
# ABSTRACT: Information about the storage driver used to store the container's and image's filesystem
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<DriverData> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str, since => '1.51', required => 1;

=attr name

Name of the storage driver. The swagger lists this field as required;
nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

docker data => { Str, Str }, since => '1.51', required => 1;

=attr data

Low-level storage metadata, provided as key/value pairs.

This information is driver-specific, and depends on the storage-driver in
use, and should be used for informational purposes only. B<The keys are the
caller's data> and are never translated. The swagger lists this field as
required; nothing here enforces that, see L<API::Docker::Type/C<since> is
documentation>.

=cut

1;
