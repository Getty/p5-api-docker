package API::Docker::Type::ImageInspect::Metadata;
# ABSTRACT: Additional metadata of the image in the local cache
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Metadata> schema of the C<ImageInspect>
definition in C<spec/v1.51.yaml>.

This information is local to the daemon, and not part of the image itself.

=cut

docker last_tag_time => Str;

=attr last_tag_time

Date and time at which the image was last tagged in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

This information is only available if the image was tagged locally, and
omitted otherwise.

=cut

1;
