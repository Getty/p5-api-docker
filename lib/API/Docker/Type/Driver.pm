package API::Docker::Type::Driver;
# ABSTRACT: A driver (network, logging, secrets)
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the C<Driver> definition of C<spec/v1.51.yaml>.

=cut

docker name => Str, required => 1;

=attr name

Name of the driver. The swagger lists this field as required; nothing here
enforces that, see L<API::Docker::Type/C<since> is documentation>.

=cut

docker options => { Str, Str };

=attr options

Key/value map of driver-specific options. B<The keys are the caller's data>
and are never translated.

=cut

1;
