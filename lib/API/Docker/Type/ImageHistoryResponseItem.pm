package API::Docker::Type::ImageHistoryResponseItem;
# ABSTRACT: individual image layer information in response to ImageHistory operation
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ImageHistoryResponseItem> definition of
C<spec/v1.51.yaml>.

=cut

docker id => Str, required => 1;

=attr id

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker created => Int, required => 1;

=attr created

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker created_by => Str, required => 1;

=attr created_by

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker tags => [Str], required => 1;

=attr tags

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker size => Int, required => 1;

=attr size

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker comment => Str, required => 1;

=attr comment

Undocumented upstream. The swagger lists this field as required; nothing
here enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

1;
