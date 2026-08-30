package API::Docker::Type::ContainerTopResponse;
# ABSTRACT: Container "top" response
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerTopResponse> definition of C<spec/v1.51.yaml>.

=cut

docker titles => [Str], since => '1.51';

=attr titles

The ps column titles.

=cut

docker processes => [[Str]], since => '1.51';

=attr processes

Each process running in the container, where each process is an array of
values corresponding to the titles.

=cut

1;
