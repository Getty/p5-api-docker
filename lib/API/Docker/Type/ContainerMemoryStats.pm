package API::Docker::Type::ContainerMemoryStats;
# ABSTRACT: Aggregates all memory stats since container inception on Linux
our $VERSION = '0.004';
use API::Docker::Type;
use namespace::clean;

=head1 DESCRIPTION

Generated from the C<ContainerMemoryStats> definition of C<spec/v1.51.yaml>.

Windows returns stats for commit and private working set only.

=cut

docker usage => Int, wire => 'usage', since => '1.51';

=attr usage

Current C<res_counter> usage for memory.

This field is Linux-specific and omitted for Windows containers. Serialised
as C<usage> -- spelled out, because deriving it from the Perl name would
produce C<Usage>.

=cut

docker max_usage => Int, wire => 'max_usage', since => '1.51';

=attr max_usage

Maximum usage ever recorded.

This field is Linux-specific and only supported on cgroups v1. It is omitted
when using cgroups v2 and for Windows containers. Serialised as C<max_usage>
-- spelled out, because deriving it from the Perl name would produce
C<MaxUsage>.

=cut

docker stats => { Str, Int }, wire => 'stats', since => '1.51';

=attr stats

All the stats exported via memory.stat.

The fields in this object differ between cgroups v1 and v2. On cgroups v1,
fields such as C<cache>, C<rss>, C<mapped_file> are available. On cgroups
v2, fields such as C<file>, C<anon>, C<inactive_file> are available.

This field is Linux-specific and omitted for Windows containers. B<The keys
are the caller's data> and are never translated. Serialised as C<stats> --
spelled out, because deriving it from the Perl name would produce C<Stats>.

=cut

docker failcnt => Int, wire => 'failcnt', since => '1.51';

=attr failcnt

Number of times memory usage hits limits.

This field is Linux-specific and only supported on cgroups v1. It is omitted
when using cgroups v2 and for Windows containers. Serialised as C<failcnt>
-- spelled out, because deriving it from the Perl name would produce
C<Failcnt>.

=cut

docker limit => Int, wire => 'limit', since => '1.51';

=attr limit

This field is Linux-specific and omitted for Windows containers. Serialised
as C<limit> -- spelled out, because deriving it from the Perl name would
produce C<Limit>.

=cut

docker commitbytes => Int, wire => 'commitbytes', since => '1.51';

=attr commitbytes

Committed bytes.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<commitbytes> -- spelled out, because deriving it from the Perl name
would produce C<Commitbytes>.

=cut

docker commitpeakbytes => Int, wire => 'commitpeakbytes', since => '1.51';

=attr commitpeakbytes

Peak committed bytes.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<commitpeakbytes> -- spelled out, because deriving it from the Perl name
would produce C<Commitpeakbytes>.

=cut

docker privateworkingset => Int, wire => 'privateworkingset', since => '1.51';

=attr privateworkingset

Private working set.

This field is Windows-specific and omitted for Linux containers. Serialised
as C<privateworkingset> -- spelled out, because deriving it from the Perl
name would produce C<Privateworkingset>.

=cut

1;
