package API::Docker::Type::TaskSpec::Placement::Preference;
# ABSTRACT: One scheduling preference of a task
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::Placement::Preference::Spread;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.Placement.Preferences> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker spread => 'TaskSpec::Placement::Preference::Spread';

=attr spread

Undocumented upstream. The only kind of preference the swagger defines, and
the only field of this object. Its own C<SpreadDescriptor> is described
upstream as a label descriptor; the example under
L<API::Docker::Type::TaskSpec::Placement/preferences> spreads over
C<node.labels.datacenter> first and C<node.labels.rack> second, preferences
being listed from highest precedence to lowest. See
L<API::Docker::Type::TaskSpec::Placement::Preference::Spread>.

=cut

1;
