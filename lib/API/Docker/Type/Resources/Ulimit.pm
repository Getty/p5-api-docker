package API::Docker::Type::Resources::Ulimit;
# ABSTRACT: One resource limit to set in a container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<items> schema of C<Resources.Ulimits> in
C<spec/v1.51.yaml>, which the swagger leaves undescribed. Upstream the
schema has no name at all: the class name is this one place where the model
does not follow from the spec mechanically, because C<Ulimits> had to be
made singular by hand. The mapping is recorded in
C<maint/spec-drift-exceptions.yaml>.

=cut

docker name => Str;

=attr name

Name of ulimit. C<nofile> for instance.

=cut

docker soft => Int;

=attr soft

Soft limit.

=cut

docker hard => Int;

=attr hard

Hard limit.

=cut

1;
