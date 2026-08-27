package Test::API::Docker::Mock;
use strict;
use warnings;
use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny;
use Carp qw( croak );
use Test::More;

use Exporter 'import';
our @EXPORT = qw(
  test_docker
  load_fixture
  load_fixture_raw
  mock_response
  is_live
  can_write
  skip_unless_write
  check_live_access
  register_cleanup
);

my $FIXTURES_DIR = path(__FILE__)->parent->parent->parent->parent->parent->child('fixtures');

my @_cleanups;

sub load_fixture {
  my ($name) = @_;
  my $file = $FIXTURES_DIR->child("$name.json");
  croak "Fixture not found: $file" unless $file->exists;
  return decode_json($file->slurp_utf8);
}

# Some fixtures are not JSON: the framed log/exec streams are captured
# engine bytes, and the build/pull event streams are newline-delimited JSON
# whose line framing is the thing under test. Both must come back byte-exact.
sub load_fixture_raw {
  my ($name) = @_;
  my $file = $FIXTURES_DIR->child($name);
  croak "Fixture not found: $file" unless $file->exists;
  return $file->slurp_raw;
}

# The status line and the response headers reach a caller through the
# `response` out-parameter of _request, which the mock replaces wholesale --
# so without this a mocked route cannot say 304, and the very distinction
# API::Docker::API::Containers/start now makes would be untestable offline.
# A plain route keeps working and gets a status inferred from its value.
my %REASON = (
  200 => 'OK',
  204 => 'No Content',
  304 => 'Not Modified',
);

sub mock_response {
  my (%args) = @_;
  my $status = $args{status} // 200;
  # _read_response lowercases every header name it collects; a mock that kept
  # the wire capitalisation would let a test pass against a key the real
  # transport never produces.
  my %headers = map { lc($_) => $args{headers}{$_} } keys %{ $args{headers} || {} };
  return bless {
    status  => $status,
    reason  => $args{reason} // $REASON{$status} // 'Unknown',
    headers => \%headers,
    data    => $args{data},
    stream  => $args{stream},
  }, 'Test::API::Docker::Mock::Response';
}

# The units a route hands to an on_event/on_frame/on_chunk callback. A route
# that says nothing gets them inferred from its data, so an existing ndjson
# route -- whose value is already the ArrayRef of events -- streams without
# being rewritten; `stream => [...]` is for a route whose buffered value and
# whose stream units differ, and for one that has to deliver more units than
# its return value has elements.
sub _mock_stream_units {
  my ($response) = @_;

  return $response->{stream} if defined $response->{stream};
  return [] unless defined $response->{data};
  return $response->{data} if ref $response->{data} eq 'ARRAY';
  return [ $response->{data} ];
}

# The mock replaces _request wholesale, so the callback path exists here only
# because it is written here too. It is the transport's contract and not a
# second one: one unit per call, a $stop closure as the second argument, the
# return value ignored, and the summary HashRef back.
sub _mock_stream {
  my ($cb, $response) = @_;

  my $units     = _mock_stream_units($response);
  my $delivered = 0;
  my $stopped   = 0;
  my $stop      = sub { $stopped = 1; return };

  for my $unit (@$units) {
    $delivered++;
    $cb->($unit, $stop);
    last if $stopped;
  }

  return { delivered => $delivered, stopped => $stopped ? 1 : 0 };
}

sub is_live {
  return !!$ENV{API_DOCKER_TEST_HOST};
}

sub can_write {
  return is_live() && !!$ENV{API_DOCKER_TEST_WRITE};
}

sub skip_unless_write {
  if (is_live() && !can_write()) {
    plan skip_all => 'Write tests skipped (set API_DOCKER_TEST_WRITE=1 to enable)';
  }
}

sub check_live_access {
  return unless is_live();

  my $host = $ENV{API_DOCKER_TEST_HOST};
  if ($host =~ m{^unix://(.+)$}) {
    unless (-S $1) {
      plan skip_all => "Docker socket $1 not available";
    }
  }

  eval {
    require API::Docker;
    my $docker = API::Docker->new(host => $host);
    my $result = $docker->system->ping;
    die "ping failed" unless $result eq 'OK';
  };
  if ($@) {
    plan skip_all => "Docker daemon not reachable at $host: $@";
  }
}

sub register_cleanup {
  my ($code) = @_;
  push @_cleanups, $code;
}

sub _run_cleanups {
  for my $cleanup (reverse @_cleanups) {
    eval { $cleanup->() };
    warn "Cleanup failed: $@" if $@;
  }
  @_cleanups = ();
}

sub test_docker {
  my (%routes) = @_;

  if (is_live()) {
    require API::Docker;
    return API::Docker->new(host => $ENV{API_DOCKER_TEST_HOST});
  }

  return _mock_docker(%routes);
}

sub _mock_docker {
  my (%routes) = @_;

  unless (grep { /version/ } keys %routes) {
    $routes{'GET /version'} = load_fixture('system_version');
  }

  require API::Docker;

  my $docker = API::Docker->new(
    host        => 'unix:///var/run/docker.sock',
    api_version => '1.47',
  );

  my $mock_request = sub {
    my ($self, $method, $path, %opts) = @_;

    my $clean_path = $path;
    $clean_path =~ s{^/v[\d.]+}{};

    my $key = "$method $clean_path";

    my $handler;
    my $matched = 0;
    if (exists $routes{$key}) {
      $handler = $routes{$key};
      $matched = 1;
    }
    else {
      for my $pattern (keys %routes) {
        my ($route_method, $route_path) = split /\s+/, $pattern, 2;
        next unless $method eq $route_method;
        next unless $clean_path =~ m{^$route_path$};
        $handler = $routes{$pattern};
        $matched = 1;
        last;
      }
    }

    croak "No mock route for: $key (available: " . join(', ', sort keys %routes) . ")"
      unless $matched;

    my $result = ref $handler eq 'CODE'
      ? $handler->($method, $clean_path, %opts)
      : $handler;

    # A route that says nothing about the status gets the one the daemon
    # would have sent for that body: 200 with one, 204 without. A route built
    # with mock_response() carries its own status and headers.
    my $response = ref $result eq 'Test::API::Docker::Mock::Response'
      ? $result
      : mock_response(status => (defined $result ? 200 : 204), data => $result);

    if (my $out = $opts{response}) {
      %$out = (
        status  => $response->{status},
        reason  => $response->{reason},
        headers => $response->{headers},
      );
    }

    my @streaming = grep { exists $opts{$_} } qw( on_event on_frame on_chunk );
    croak "Mock route $key got more than one of on_event, on_frame, on_chunk: "
      . join(' and ', @streaming) if @streaming > 1;
    return _mock_stream($opts{$streaming[0]}, $response) if @streaming;

    return $response->{data};
  };

  my $mock_pkg = "API::Docker::Mock::" . int(rand(1_000_000));
  {
    no strict 'refs';
    @{"${mock_pkg}::ISA"} = ('API::Docker');
    *{"${mock_pkg}::_request"} = $mock_request;
  }

  bless $docker, $mock_pkg;
  return $docker;
}

END { _run_cleanups() }

1;
