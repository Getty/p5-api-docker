package API::Docker::Type::HostConfig::LogConfig;
# ABSTRACT: The logging configuration for a container
our $VERSION = '0.004';
use API::Docker::Type;

=head1 DESCRIPTION

Generated from the inline C<LogConfig> schema of the C<HostConfig>
definition in C<spec/v1.51.yaml>.

=cut

docker type => Str,
  enum => [qw(
    local json-file syslog journald gelf fluentd awslogs splunk etwlogs none
  )];

=attr type

Name of the logging driver used for the container, or C<none> if logging is
disabled. The swagger enumerates C<local>, C<json-file>, C<syslog>,
C<journald>, C<gelf>, C<fluentd>, C<awslogs>, C<splunk>, C<etwlogs> and
C<none>.

=cut

docker config => { Str, Str };

=attr config

Driver-specific configuration options for the logging driver, C<<
{"max-file": "5", "max-size": "10m"} >> for instance. B<The keys are the
caller's data> and are never translated.

=cut

1;
