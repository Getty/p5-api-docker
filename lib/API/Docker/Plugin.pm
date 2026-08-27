package API::Docker::Plugin;
# ABSTRACT: Docker plugin entity
our $VERSION = '0.004';
use Moo;
use namespace::clean;

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $plugins = $docker->plugins->list;
    my $plugin = $plugins->[0];

    say $plugin->Name;
    say $plugin->Enabled ? 'enabled' : 'disabled';
    say join ', ', @{ $plugin->Settings->{Env} };

    $plugin->disable;
    $plugin->configure(['DEBUG=1']);
    $plugin->enable;

=head1 DESCRIPTION

This class represents a Docker managed plugin. Instances are returned by
L<API::Docker::API::Plugins> methods.

Every method here threads L</Name> through to the method of the same name on
L<API::Docker::API::Plugins>, so the options, the return values and the
failure modes are that class's -- documented there, not repeated here.

Managed plugins are a Docker feature: none of these endpoints exist on
Podman, so nothing in this class works against it. See
L<API::Docker::API::Plugins/"Not available on Podman">.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<API::Docker> client.

=cut

has Id              => (is => 'ro');

=attr Id

Plugin ID.

=cut

has Name            => (is => 'ro');

=attr Name

Plugin name, as it is installed locally -- C<vieux/sshfs:latest>, or whatever
local name L<API::Docker::API::Plugins/install> was given. This is the value
every method of this class threads back to the engine, so it is the one
attribute the class cannot work without.

=cut

has Enabled         => (is => 'ro');

=attr Enabled

Whether the plugin is enabled. Always present, and a decoded JSON boolean
rather than C<1>/C<0> -- entity classes here mirror the daemon's fields
verbatim. It is true or false in boolean context either way.

=cut

has PluginReference => (is => 'ro');

=attr PluginReference

The remote reference the plugin was pulled from --
C<docker.io/vieux/sshfs:latest> where L</Name> is C<vieux/sshfs:latest>. It
differs from the name outright when the plugin was installed under a local
one, which is exactly the case where L</upgrade> needs C<remote> spelled out.

C<undef> for a plugin that never came from a registry: the engine sets this
on the pull, upgrade and create paths only, and omits the key entirely
otherwise rather than sending it as null.

=cut

has Config          => (is => 'ro');

=attr Config

HashRef: the plugin's own config, as the plugin declares it -- its interface,
entrypoint, and the mounts, devices and environment variables it describes.
L</configure> does not write here; it changes L</Settings>.

=cut

has Settings        => (is => 'ro');

=attr Settings

HashRef of the plugin's current settings -- the mutable fields L</configure>
changes. It always carries C<Mounts>, C<Env>, C<Args> and C<Devices>.

C<< $plugin->Settings->{Env} >> is a list of C<KEY=value> B<strings>, which is
what L</configure> takes. C<< $plugin->Config->{Env} >> is a list of HashRefs
describing those same variables -- same key, two shapes, one level apart. The
daemon flattens the one into the other when the plugin is installed.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->plugins->inspect($self->Name);
}

=method inspect

    my $updated = $plugin->inspect;

Get fresh plugin information. Returns a new L<API::Docker::Plugin>.

=cut

sub enable {
  my ($self, %opts) = @_;
  return $self->client->plugins->enable($self->Name, %opts);
}

=method enable

    $plugin->enable;
    $plugin->enable(timeout => 30);

Enable the plugin.

=cut

sub disable {
  my ($self, %opts) = @_;
  return $self->client->plugins->disable($self->Name, %opts);
}

=method disable

    $plugin->disable(force => 1);

Disable the plugin.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->plugins->remove($self->Name, %opts);
}

=method remove

    $plugin->remove(force => 1);

Remove the plugin. An enabled plugin is refused without C<force>.

=cut

sub configure {
  my ($self, @settings) = @_;
  return $self->client->plugins->configure($self->Name, @settings);
}

=method configure

    $plugin->configure(['DEBUG=1']);
    $plugin->configure('DEBUG=1', 'sshkey.source=/tmp');

Set the plugin's user-configurable settings. The plugin must be disabled
first.

=cut

sub upgrade {
  my ($self, %opts) = @_;
  return $self->client->plugins->upgrade($self->Name, %opts);
}

=method upgrade

    my $privileges = $docker->plugins->privileges($plugin->PluginReference);
    $plugin->upgrade(remote => $plugin->PluginReference,
        privileges => $privileges);

Upgrade the plugin in place. C<privileges> is required, as it is on
L<API::Docker::API::Plugins/upgrade>, and C<remote> defaults to L</Name> --
which is not what you want for a plugin installed under a local name, hence
L</PluginReference>.

=cut

sub push {
  my ($self, %opts) = @_;
  return $self->client->plugins->push($self->Name, %opts);
}

=method push

    $plugin->push(auth => { username => 'me', password => 'secret' });

Push the plugin to a registry. B<This writes to a real registry> under the
credentials given.

C<push> shadows the Perl builtin inside this package, which is why
L<namespace::clean> is loaded. Always call it as a method.

=cut

=seealso

=over

=item * L<API::Docker::API::Plugins> - Plugin API operations

=item * L<API::Docker> - Main Docker client

=back

=cut

1;
