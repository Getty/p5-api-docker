# ADR 0001 — The generated type model is public API, evolved additively

Status: Accepted (2026-08-29). Governs karr k112 and every later ceiling bump.

## Context

The `API::Docker::Type::*` classes are generated from Docker's swagger under
`spec/` by `maint/spec-to-type.pl`. They are not an internal detail: `list`
and `inspect` return them, and a caller `use`s them, checks `isa`, and reads
their field accessors. **The generated type model is public API.**

Docker publishes a new swagger every so often. `spec/v1.55.yaml` is checked in
next to `v1.51.yaml` (k110), and the delta is large and partly structural:

- `Network` splits into `NetworkSummary` (list) and `NetworkInspect` (inspect,
  carrying `Containers`, `Services` and a new `Status`).
- `Port` splits into `PortSummary`, with a type change on
  `ContainerSummary.Ports`.
- `VolumeCreateOptions` is renamed `VolumeCreateRequest`.
- 28 new definitions (signature/attestation, the DiskUsage split, ...), 8 new
  fields, 29 dropped fields.

Mirroring that decomposition on a ceiling bump would rename and remove classes
callers depend on — a breaking change forcing a major bump or deprecation
shims. It would also invite the false idea that supporting two engine levels
needs two models.

It does not. The client negotiates a version and speaks it, and any engine
serves its range down to `MinAPIVersion`. The `unknown_fields` passthrough
(k101, k104) absorbs whatever the model has not heard of. Measured (k110): the
**v1.51 model against a real v1.55 engine** put the new fields in
`unknown_fields` with `rejected_fields` empty — nothing broke. One model, plus
negotiation and passthrough, already covers the whole engine range.

## Decision

Treat the generated type model as public API and evolve it **additively**.

1. **Existing class names and field accessors are kept** across a ceiling bump.
2. **New fields and genuinely new nested classes are added** — additive, so
   nothing already in use moves.
3. **Where the swagger renames or splits a class, the existing name stays** as
   the class the resource API returns. If the new name is wanted too, it is
   added as an alias or subclass, never as a replacement.
4. **Where the swagger drops a field, the accessor stays.** It simply goes
   unset when the engine omits it — the same shape passthrough already gives an
   optional field.
5. **New definitions nothing references yet are left out** until a resource API
   returns them (Simplicity — nothing speculative). Checking the swagger in is
   not the same as modelling all of it.
6. Every deliberate divergence from the swagger's decomposition is recorded in
   `maint/spec-drift-exceptions.yaml` (and named in
   `maint/spec-to-type-names.yaml` where a Perl name is chosen), each with a
   WHY pointing here or to a karr ticket / `Changes` bullet — the file already
   demands that.
7. The generation ceiling may rise, but only additively per the above. A bump
   that **cannot** be made additive is a breaking change and gets its own
   deliberate major/minor decision — never a silent ride-along in an otherwise
   non-breaking release.

## Consequences

- **+** Caller code that embeds a class name, `isa`-checks it, or reads a field
  keeps working across engine and model bumps.
- **+** "Support both Docker levels" needs one model, not two (measured, k110).
- **+** v1.55 (and later) field coverage becomes non-breaking additive work,
  not a forced major bump.
- **−** The model deliberately diverges from the swagger's class
  decomposition; the drift checker needs exception entries — the mechanism
  exists for exactly this — and a reader consults them to see why.
- **−** A class kept unified carries fields only some responses populate (unset
  otherwise); already the norm here.
- **−** A field the swagger dropped lingers as an accessor. Harmless, but
  intentional, and recorded in the exceptions file so it reads as a decision.

## Alternatives considered

- **Mirror the swagger (rename/split on bump).** Rejected: breaks callers,
  forces a major bump or deprecation machinery, and buys nothing the passthrough
  does not already give for talking to newer engines.
- **Model each version separately and ship several.** Rejected: negotiation +
  passthrough already span the range from one model; two models is maintenance
  with no reachable benefit.

## References

- karr k110 — `spec/v1.55.yaml` checked in, delta measured.
- karr k112 — the v1.55 migration this ADR governs.
- karr k101, k104 — the `unknown_fields`/`rejected_fields` passthrough invariant.
- `maint/spec-drift-exceptions.yaml`, `maint/spec-to-type-names.yaml` — where a
  deviation is recorded and a name is chosen.
