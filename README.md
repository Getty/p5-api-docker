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

# Container management
my $containers = $docker->containers->list(all => 1);
my $result = $docker->containers->create(
    Image => 'nginx:latest',
    name  => 'my-nginx',
);
$docker->containers->start($result->{Id});

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
- **Object-oriented entity classes** (Container, Image, Network, Volume,
  Secret, Config, Plugin)
- **HTTP/1.1 implementation** with chunked transfer encoding, including
  incremental delivery of a streaming response through a per-request
  callback (`on_event`/`on_frame`/`on_chunk`) for endpoints that never
  close on their own — `logs(follow => 1)`, `system->events`, `stats`
- **Comprehensive logging** via Log::Any

### Roles

Behaviour shared across the resource classes, each documented on its own
page:

- `API::Docker::Role::HTTP` — the HTTP transport layer every resource
  class and entity hangs off
- `API::Docker::Role::RegistryAuth` — X-Registry-Auth / AuthConfig
  encoding, shared by Images, Plugins, Distribution and System
- `API::Docker::Role::Filters` — the `filters` query parameter, normalised
  into the one shape the engine reads, shared by every `list`/`prune`
  method

## Methods

### new(%opts)

Create a new Docker client. Options:

- `host` — connection URL, defaults to `$ENV{DOCKER_HOST}` or `unix:///var/run/docker.sock`
- `api_version` — Docker API version (auto-negotiated if not set)
- `tls` — speak TLS on a `tcp://` connection (default `0`, plaintext; croaks
  on a `unix://` host). Verifies the daemon's certificate and hostname by
  default, against the system trust store when no certificates are given —
  not an error, and not a silent downgrade. See `cert_path` and
  `tls_insecure`
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
`/tasks`) is deliberately out of scope: Podman, the engine this
distribution is tested against, implements none of it, and no consumer
asks for it. `secrets` and `configs` are covered despite belonging to
that same Engine API family, because they stand on their own rather than
on an orchestrator.

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
