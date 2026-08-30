package API::Docker::Type::TaskSpec::Placement::Preference::Spread;
# ABSTRACT: The node attribute a task is spread over
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<Spread> schema of
C<TaskSpec.Placement.Preferences> in C<spec/v1.51.yaml>, which the swagger
leaves undescribed.

=cut

docker spread_descriptor => Str;

=attr spread_descriptor

Label descriptor, such as C<engine.labels.az>.

=cut

1;
