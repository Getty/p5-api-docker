package API::Docker::Type::SystemVersion::Component;
# ABSTRACT: One entry of C<SystemVersion.Components>
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<SystemVersion.Components> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed.

=cut

docker name => Str;

=attr name

Name of the component.

=cut

docker version => Str;

=attr version

Version of the component.

=cut

docker details => Any;

=attr details

Key/value pairs of strings with additional information about the component.
These values are intended for informational purposes only, and their content
is not defined, and not part of the API specification.

These messages can be printed by the client as information to the user.

=cut

1;
