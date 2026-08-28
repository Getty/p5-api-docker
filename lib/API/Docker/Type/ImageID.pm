package API::Docker::Type::ImageID;
# ABSTRACT: Image ID or Digest
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<ImageID> definition of C<spec/v1.51.yaml>. The only
C<$ref> to it in the whole spec is C<BuildInfo.aux>, so this is the object a
build stream reports the finished image's ID in; see
L<API::Docker::Type::BuildInfo/aux>.

=cut

docker id => Str, wire => 'ID';

=attr id

Undocumented upstream. The image ID or digest the definition's own
description names. The swagger's example is
C<sha256:85f05633ddc1c50679be2b16a0479ab6f7637f8884e0cfe0f4d20e1ebb3d6e7c>.
Serialised as C<ID> -- spelled out, because deriving it from the Perl name
would produce C<Id>.

=cut

1;
