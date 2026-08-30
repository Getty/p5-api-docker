package API::Docker::Type::BuildCache;
# ABSTRACT: Information about a build cache record
our $VERSION = '0.005';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<BuildCache> definition of C<spec/v1.51.yaml>.

=cut

docker id => Str, wire => 'ID';

=attr id

Unique ID of the build cache record. Serialised as C<ID> -- spelled out,
because deriving it from the Perl name would produce C<Id>.

=cut

docker parents => [Str], since => '1.44';

=attr parents

List of parent build cache record IDs.

=cut

docker type => Str,
  enum => [qw(
    internal frontend source.local source.git.checkout exec.cachemount regular
  )];

=attr type

Cache record type. The swagger enumerates C<internal>, C<frontend>,
C<source.local>, C<source.git.checkout>, C<exec.cachemount> and C<regular>.

=cut

docker description => Str;

=attr description

Description of the build-step that produced the build cache.

=cut

docker in_use => Bool;

=attr in_use

Indicates if the build cache is in use.

=cut

docker shared => Bool;

=attr shared

Indicates if the build cache is shared.

=cut

docker size => Int;

=attr size

Amount of disk space used by the build cache (in bytes).

=cut

docker created_at => Str;

=attr created_at

Date and time at which the build cache was created in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker last_used_at => Str;

=attr last_used_at

Date and time at which the build cache was last used in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=cut

docker usage_count => Int;

=attr usage_count

Undocumented upstream. A count of uses, C<26> in the swagger's example. The
record's two other usage fields, L</in_use> and L</last_used_at>, are
described upstream; this one is not.

=cut

1;
