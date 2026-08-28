# The `docker` keyword, the registry, and serialisation

`API::Docker::Type` is imported, not inherited. Its `import` pulls Moo, the
type vocabulary and the serialisation role into the calling package, then
installs one keyword.

    package API::Docker::Type::Port;
    use API::Docker::Type;      # gives you Moo, the types, and `docker`

This mirrors `IO::K8s::Resource` in ../io-k8s-p5. Read that file — it is the
same design and it works.

## What `docker` does

    docker $perl_name => $type;
    docker $perl_name => $type, since => '1.44';
    docker $perl_name => $type, wire => 'CPUShares';
    docker $perl_name => $type, required => 1;

It declares a Moo attribute AND writes an entry into a package-level registry:

    $REGISTRY{$class}{$perl_name} = {
        type     => $type,       # the declared type
        wire     => 'PortBindings',
        since    => '1.41',      # or undef
        required => 0,
    };

Both halves matter. The attribute is what a caller uses; the registry is what
serialisation and `maint/spec-drift-check.pl` read. A field that is an
attribute but not in the registry is invisible to the drift checker, which is
the failure mode that makes the whole model untrustworthy.

## Deriving the wire name

The registry stores the spec's spelling. The Perl name is derived from it at
generation time, not at runtime:

    PortBindings   -> port_bindings
    CPUShares      -> cpu_shares
    OOMKillDisable -> oom_kill_disable
    ID             -> id
    NanoCpus       -> nano_cpus

Runs of capitals are one word. When the derivation produces something that
collides with another field in the same class, or reads wrong, pass `wire`
explicitly and choose the Perl name by hand — do not bend the derivation to
fit one case.

## Serialisation, both directions

`TO_JSON` walks the registry, not the object's keys:

- an attribute that was never set is omitted, not sent as null
- a nested object is serialised by its own `TO_JSON`
- an ArrayRef of objects maps over them
- a HashRef whose keys are caller data passes its keys through untouched
- anything the caller stored under a name the registry does not know is
  forwarded verbatim, so a newer engine's field still reaches the daemon

Inflation is the mirror: a known wire name becomes the typed attribute, an
unknown one is kept as-is under its original name.

## Booleans

Docker distinguishes an absent flag from a false one. `Bool` must serialise to
JSON `true`/`false` and never to `1`/`""`, and an unset Bool must be absent
rather than false. This is the same trap `IO::K8s` documents; borrow its
solution rather than inventing one.
