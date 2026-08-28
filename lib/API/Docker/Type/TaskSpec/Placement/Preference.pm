package API::Docker::Type::TaskSpec::Placement::Preference;
# ABSTRACT: One scheduling preference of a task
our $VERSION = '0.004';
use API::Docker::Type;
use API::Docker::Type::TaskSpec::Placement::Preference::Spread;

=head1 DESCRIPTION

Generated from the inline C<items> schema of
C<TaskSpec.Placement.Preferences> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker spread => 'TaskSpec::Placement::Preference::Spread';

=attr spread

Undocumented upstream. See
L<API::Docker::Type::TaskSpec::Placement::Preference::Spread>.

=cut

1;
