# spec/

Docker's published swagger for the Engine API, checked in **verbatim**. These
files are the source the classes under `lib/API/Docker/Type/` are generated
from, and `maint/spec-drift-check.pl` reads them to prove the classes still
match.

| file | source |
|---|---|
| `v1.41.yaml` | <https://docs.docker.com/reference/api/engine/version/v1.41.yaml> |
| `v1.44.yaml` | <https://docs.docker.com/reference/api/engine/version/v1.44.yaml> |
| `v1.51.yaml` | <https://docs.docker.com/reference/api/engine/version/v1.51.yaml> |

Fetched 2026-08-28. Re-fetch and `diff` to confirm nothing here was edited:

```bash
curl -s https://docs.docker.com/reference/api/engine/version/v1.51.yaml | diff - spec/v1.51.yaml
```

`v1.51` is the newest version Docker publishes a swagger for and is what the
model is generated against; it carries 132 entries under `definitions:`.

The older two are not history for its own sake. **The swagger carries no
per-field version information at all**, so the only way to say when a field
appeared is to diff two specs against each other — which is what
`maint/spec-drift-check.pl --from ... --to ...` does, and where every `since`
in the model comes from. With three specs the resolution is three steps wide:
`since => '1.51'` means "not in v1.44, present in v1.51", so the field
appeared somewhere in v1.45..v1.51. An attribute with no `since` is already
in v1.41.

**Do not convert these to JSON and do not reformat them.** The `diff` above is
the whole point. One consequence: `YAML::PP` 0.41 cannot parse them — the
`example:` blocks are multi-line flow maps whose closing brace is indented
less than the key that opens it (line 1364 of `v1.51.yaml` is the first of
twelve). `libyaml` accepts it, so the tooling uses `YAML::XS`.
