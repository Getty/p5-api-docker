package API::Docker::Type::ServiceSpec::Mode::ReplicatedJob;
# ABSTRACT: The mode used for services with a finite number of tasks that run to a completed state
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the inline C<ReplicatedJob> schema of C<ServiceSpec.Mode> in
C<spec/v1.51.yaml>.

=cut

docker max_concurrent => Int;

=attr max_concurrent

The maximum number of replicas to run simultaneously. The daemon defaults it
to 1.

=cut

docker total_completions => Int;

=attr total_completions

The total number of replicas desired to reach the Completed state. If unset,
will default to the value of C<MaxConcurrent>.

=cut

1;
