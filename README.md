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
- **Unix socket and TCP transport** support
- **Automatic API version negotiation** with Docker daemon
- **Object-oriented entity classes** (Container, Image, Network, Volume)
- **HTTP/1.1 implementation** with chunked transfer encoding
- **Comprehensive logging** via Log::Any

## Methods

### new(%opts)

Create a new Docker client. Options:

- `host` — connection URL, defaults to `$ENV{DOCKER_HOST}` or `unix:///var/run/docker.sock`
- `api_version` — Docker API version (auto-negotiated if not set)
- `tls` — enable TLS (experimental)
- `cert_path` — path to TLS certs, defaults to `$ENV{DOCKER_CERT_PATH}`

### system

Returns L<API::Docker::API::System> for system operations (info, version, ping, df, events).

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

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
