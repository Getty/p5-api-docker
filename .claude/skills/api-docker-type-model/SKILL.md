---
name: api-docker-type-model
description: "Use when writing or changing a class under API::Docker::Type::*, the API::Docker::Type DSL, maint/spec-drift-check.pl, or anything under spec/ — generating typed classes from Docker's swagger, mapping snake_case attributes to the daemon's CamelCase, or deciding what a field's type and version note should say."
---

# API::Docker::Type — generated classes over the Docker Engine API

Every class under `API::Docker::Type::*` is a Perl mirror of one `definitions:`
entry in Docker's swagger. They are written from the spec, not from a running
daemon, and `maint/spec-drift-check.pl` is what keeps that claim true.

The working reference is `../io-k8s-p5`, which does this for Kubernetes.
Read `lib/IO/K8s/Resource.pm` and `maint/spec-drift-check.pl` there before
writing the DSL — the load-bearing idea is the attribute **registry**, not the
classes.

## The shape of a class

```perl
package API::Docker::Type::HostConfig;
# ABSTRACT: Container configuration that depends on the host
our $VERSION = '0.004';
use API::Docker::Type;

docker binds => [Str];

=attr binds

A list of volume bindings for this container. Serialised as C<Binds>.

=cut

docker port_bindings => { Str, ['Core::PortBinding'] }, since => '1.41';

=attr port_bindings

Port mapping, keyed by the container port. Serialised as C<PortBindings>.
The keys are the caller's data and are never translated.

=cut
```

Four things every attribute states: the **snake_case name**, the **type**,
the **CamelCase wire name** (derived, not written — see below), and a POD
block taken from the spec's own `description`.

## The rules that are not obvious

**The wire name is derived, and the derivation is one-way.** `port_bindings` →
`PortBindings` works; `PortBindings` → `port_bindings` does not round-trip for
every field (`CPUShares`, `OOMKillDisable`, `ID`). So the registry stores the
spec's spelling verbatim and derives the Perl name from it — never the other
way. When the derivation would produce a name that collides or reads wrong,
the DSL takes an explicit `wire => 'CPUShares'`.

**Some keys are the caller's data and must never be translated.** In
`Labels`, `ExposedPorts`, `PortBindings`, `Volumes`, `StorageOpt`, `Tmpfs`,
`Sysctls` and `Annotations` the *keys* come from the user. A `HashRef` type
whose keys are data is written `{ Str, $value_type }` and the DSL leaves those
keys alone. Getting this wrong turns a label `com.example.Some-Label` into
something the caller never wrote. This is the single most damaging mistake in
the whole model.

**An unknown field passes through unchanged.** A caller who sets a field this
model has never heard of — because their engine is newer than the spec we
generated from — must still reach the daemon. The model translates what it
knows and forwards the rest verbatim. A model that drops unknown fields would
cost this distribution the property that a newer engine works on day one.

**`since` is documentation, never a check.** It records which API version
introduced the field, derived by diffing two specs. Nothing is validated,
warned about or dropped at runtime. Podman serves fields its announced version
does not promise, and refuses ones it does — we are not the authority on what
an engine can do.

## Where the values come from

`spec/` holds the swagger, checked in. Generate against the newest published
version; keep the older ones for the diff that produces `since`.

    https://docs.docker.com/reference/api/engine/version/v1.51.yaml

The `description` of a field in the spec is the `=attr` text. Rewrap it, fix
its grammar, keep its meaning. Do not invent a description for a field the
spec leaves undescribed — say it is undocumented upstream.

## Completion criteria

A class is done when `maint/spec-drift-check.pl` reports it with no missing
and no extra fields, every attribute has an `=attr` block, and `prove -lr t/`
is green. A class nobody can check against the spec is not done, however good
it looks.

## Related

- `references/dsl.md` — the `docker` keyword, the registry, serialisation
- `references/types.md` — the type vocabulary and the data-key list in full
- `api-docker-core` — the transport and the resource classes these feed
- `getty-perl-moo` — Moo conventions this distribution follows
