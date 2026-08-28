# API-Docker

[![CPAN Version](https://img.shields.io/cpan/v/API-Docker.svg)](https://metacpan.org/pod/API::Docker)
[![License](https://img.shields.io/cpan/l/API-Docker.svg)](https://metacpan.org/pod/API::Docker)

Perl client for the Docker Engine API.

## Installation

```bash
cpanm API::Docker
```

Or from source:

```bash
dzil build
dzil test
dzil install
```

## Synopsis

```perl
use API::Docker;

# Connect to local Docker daemon via Unix socket
my $docker = API::Docker->new;

# Or connect to remote Docker daemon
my $docker = API::Docker->new(
    host => 'tcp://192.168.1.100:2375',
);

# System information
my $info = $docker->system->info;
my $version = $docker->system->version;

# Container management -- list/inspect return generated
# API::Docker::Type::* objects with snake_case accessors, not hashrefs
my $containers = $docker->containers->list(all => 1);
for my $container (@$containers) {
    say $container->id;
    say $container->status;
}

my $result = $docker->containers->create(
    Image => 'nginx:latest',
    name  => 'my-nginx',
);
$docker->containers->start($result->{Id});

my $inspected = $docker->containers->inspect($result->{Id});
say $inspected->state->running ? 'running' : 'not running';

# Image operations
$docker->images->pull(fromImage => 'nginx', tag => 'latest');
my $images = $docker->images->list;

# Network and volume management
my $networks = $docker->networks->list;
my $volumes = $docker->volumes->list;
```

## Description

API::Docker is a pure Perl client for the Docker Engine API. It provides a clean
object-oriented interface to manage Docker containers, images, networks, and
volumes without the overhead of heavy HTTP client libraries.

### Key Features

- **Pure Perl implementation** with minimal dependencies (no LWP)
- **Unix socket and TCP transport**, the latter in the clear or over TLS
  with client certificates (see `tls`, `cert_path` below)
- **Automatic API version negotiation** with Docker daemon
- **A typed object model generated from Docker's own swagger**
  (`API::Docker::Type::*`) -- containers today, the remaining resources
  incrementally; see [Typed object model](#typed-object-model) below
- **HTTP/1.1 implementation** with chunked transfer encoding, including
  incremental delivery of a streaming response through a per-request
  callback (`on_event`/`on_frame`/`on_chunk`) for endpoints that never
  close on their own — `logs(follow => 1)`, `system->events`, `stats`
- **Comprehensive logging** via Log::Any

### Typed object model

Docker publishes its own machine-readable API description (its swagger),
listing around 200 shapes -- containers, images, networks, host configs,
mounts, and everything nested inside them. `API::Docker::Type::*` mirrors
every one of them as a generated Perl class, one class per swagger
definition, so a deeply nested response comes back as real objects instead
of a hashref tree to dig through by hand:

```perl
my $container = $docker->containers->inspect($id);
say $container->state->running;      # not $container->{State}{Running}
say $container->host_config->privileged;
```

Fields are snake_case on the Perl side (`host_config`, `size_root_fs`) and
the daemon's own CamelCase on the wire (`HostConfig`, `SizeRootFs`); the
mapping is mechanical, and spelled out by hand where it is not.

Two things set this apart from a plain generated hashref-to-object mapper:

- **An unrecognised field is not dropped.** Anything a response carries
  under a name the model does not know -- an engine newer than the
  swagger this model was generated from -- is kept under the name it
  arrived with and written back out unchanged. A caller's own data is
  never silently discarded just because this client has not caught up
  yet.
- **`since` is documentation, not a runtime check.** Every attribute's POD
  records the API version that introduced it, but nothing is validated,
  warned about, or stripped at request or response time on that basis.
  Real engines have been measured serving fields their announced version
  does not promise, and omitting ones it does -- this client is
  deliberately not the authority on what a given engine can do.

`containers->list` and `containers->inspect` return these generated
classes today (`API::Docker::Type::ContainerSummary` and
`API::Docker::Type::ContainerInspectResponse`), with the same convenience
methods (`->start`, `->stop`, `->logs`, `->remove`, ...) composed onto
both, so a list entry and an inspect result behave the same way. The
other resources -- images, networks, volumes, secrets, configs, plugins
-- still return their earlier hand-written entity classes
(`API::Docker::Image` and friends) and are being moved onto the same
generated model one at a time.

### Roles

Behaviour composed into more than one class, each documented on its own
page:

- `API::Docker::Role::HTTP` — the HTTP transport layer every resource
  class and entity hangs off
- `API::Docker::Role::RegistryAuth` — X-Registry-Auth / AuthConfig
  encoding, shared by Images, Plugins, Distribution and System
- `API::Docker::Role::Filters` — the `filters` query parameter, normalised
  into the one shape the engine reads, shared by every `list`/`prune`
  method
- `API::Docker::Role::Using` — `using`, the resource class clone that
  bounds a run of calls with its own timeout
- `API::Docker::Role::Type` — the instance behaviour of every generated
  `API::Docker::Type::*` class: serialisation both ways and
  `unknown_fields`
- `API::Docker::Role::Entity` — the client reference an entity delegates
  through
- `API::Docker::Role::Entity::Container` — the container convenience
  methods (`->start`, `->logs`, ...), composed onto the generated
  `ContainerSummary` and `ContainerInspectResponse` classes at load time

## Methods

### new(%opts)

Create a new Docker client. Options:

- `host` — connection URL, defaults to `$ENV{DOCKER_HOST}` or `unix:///var/run/docker.sock`
- `api_version` — Docker API version (auto-negotiated if not set)
- `tls` — speak TLS on a `tcp://` connection (croaks on a `unix://` host).
  Defaults to `1` when `$ENV{DOCKER_TLS_VERIFY}` holds any non-empty value —
  `0` included, following the `docker` CLI's own rule — and `host` is
  `tcp://`; ignored on a socket host, and `0` (plaintext) otherwise. An
  explicit `tls => ...` outranks the environment in both directions.
  Verifies the daemon's certificate and hostname by default, against the
  system trust store when no certificates are given — not an error, and not
  a silent downgrade. See `cert_path` and `tls_insecure`
- `cert_path` — directory holding TLS certificates in the layout the
  `docker` CLI writes (`ca.pem`, `cert.pem`, `key.pem`), each used if
  present; read only when `tls` is set. Defaults to `$ENV{DOCKER_CERT_PATH}`
- `tls_insecure` — turn certificate verification off (default `0`); only
  meaningful with `tls`, and croaks without it

### system

Returns L<API::Docker::API::System> for system operations (info, version, ping, df, events, auth).

### containers

Returns L<API::Docker::API::Containers> for container management.

### images

Returns L<API::Docker::API::Images> for image management.

### networks

Returns L<API::Docker::API::Networks> for network management.

### volumes

Returns L<API::Docker::API::Volumes> for volume management.

### exec

Returns L<API::Docker::API::Exec> for executing commands in containers.

### distribution

Returns L<API::Docker::API::Distribution> for registry manifest lookups
without pulling: `inspect` and `exists`.

### secrets

Returns L<API::Docker::API::Secrets> for secret operations: `list`,
`create`, `inspect`, `update` and `remove`.

### configs

Returns L<API::Docker::API::Configs> for config operations: `list`,
`create`, `inspect`, `update` and `remove`.

### plugins

Returns L<API::Docker::API::Plugins> for managed-plugin operations:
`list`, `privileges`, `install`, `inspect`, `remove`, `enable`, `disable`,
`upgrade`, `push` and `configure`.

The Swarm orchestration family (`/swarm`, `/nodes`, `/services`,
`/tasks`) is deliberately out of scope, and staying that way is the plan:
Swarm sees too little practical use to be worth the surface, Podman — the
engine this distribution is tested against — implements none of it, and
no consumer asks for it. Docker has not withdrawn Swarm; this
distribution simply chooses not to follow it. `secrets` and `configs`
are covered despite belonging to that same Engine API family, because
they stand on their own rather than on an orchestrator — see
`API::Docker::API::Secrets` for what that looks like against Docker and
Podman, single-node 503 included. Anyone who actually needs Swarm
orchestration should reach for a client built around it.

## Container engines

This client speaks the Docker Engine HTTP API over a socket and never
shells out to the `docker` binary, so any engine serving that API works
— Podman included, which needs nothing but `DOCKER_HOST`. Where the
engine is Docker itself, prefer the official packages from
[docs.docker.com/engine/install](https://docs.docker.com/engine/install/)
over a distribution package such as Debian/Ubuntu's `docker.io`, which is
typically a good deal older: API version negotiation only negotiates
within whatever version the daemon itself reports, so an older daemon
still works, but endpoints and query parameters that need a newer API
version are then simply not there.

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
