package API::Docker::Type::EventActor;
# ABSTRACT: Actor describes something that generates events, like a container, network, or a volume
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<EventActor> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID';

=attr id

The ID of the object emitting the event. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=cut

docker attributes => { Str, Str };

=attr attributes

Various key/value attributes of the object, depending on its type. B<The
keys are the caller's data> and are never translated.

=cut

1;
