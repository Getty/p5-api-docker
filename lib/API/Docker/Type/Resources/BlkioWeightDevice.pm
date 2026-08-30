package API::Docker::Type::Resources::BlkioWeightDevice;
# ABSTRACT: A per-device block IO weight
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Resources.BlkioWeightDevice>
in C<spec/v1.51.yaml>, which the swagger leaves undescribed. Neither the
schema nor its two fields carry a description upstream; the form the swagger
shows for the enclosing field is C<< [{"Path": "device_path", "Weight":
weight}] >>.

=cut

docker path => Str;

=attr path

Undocumented upstream. The device path, per the swagger's example form.

=cut

docker weight => Int;

=attr weight

Undocumented upstream. The relative weight for that device; the swagger
constrains it to 0 or above and nothing else.

=cut

1;
