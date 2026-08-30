package API::Docker::Type::EventMessage;
# ABSTRACT: The information an event contains
our $VERSION = '0.005';
use API::Docker::Type;
use API::Docker::Type::EventActor;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<EventMessage> definition of C<spec/v1.51.yaml>.

=cut

docker type => Str,
  enum => [qw(
    builder config container daemon image network node plugin secret service
    volume
  )];

=attr type

The type of object emitting the event. The swagger enumerates C<builder>,
C<config>, C<container>, C<daemon>, C<image>, C<network>, C<node>,
C<plugin>, C<secret>, C<service> and C<volume>.

=cut

docker action => Str;

=attr action

The type of event.

=cut

docker actor => 'EventActor';

=attr actor

Actor describes something that generates events, like a container, network,
or a volume. See L<API::Docker::Type::EventActor>.

=cut

docker scope => Str, wire => 'scope', enum => [qw( local swarm )];

=attr scope

Scope of the event. Engine events are C<local> scope. Cluster (Swarm) events
are C<swarm> scope. Serialised as C<scope> -- spelled out, because deriving
it from the Perl name would produce C<Scope>.

=cut

docker time => Int, wire => 'time';

=attr time

Timestamp of event. Serialised as C<time> -- spelled out, because deriving
it from the Perl name would produce C<Time>.

=cut

docker time_nano => Int, wire => 'timeNano';

=attr time_nano

Timestamp of event, with nanosecond accuracy. Serialised as C<timeNano> --
spelled out, because deriving it from the Perl name would produce
C<TimeNano>.

=cut

1;
