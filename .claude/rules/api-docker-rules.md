# API-Docker House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch (same
priority as `CLAUDE.md`); subagents get their conventions from `briefing.skills` — this file is
for the orchestrating agent, and skill content is not repeated here. Skill pointers:
`api-docker-core`, `docker-engine-api`, `api-docker-hazards` — don't duplicate them here.

## Engineering discipline

1. **Think before coding** — state assumptions; when uncertain, ask rather than guess; push back if simpler exists.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what you must. Match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one (more recent / more tested), flag the other; don't blend.
6. **Read before you write** — `Role::HTTP` is the seam every resource API and entity class hangs off.
7. **Tests verify intent** — reproduce a bug before fixing it and leave the regression behind; a test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — summarize: done / verified / left.
9. **Match conventions** — conformance > taste. Surface a harmful convention; don't fork silently.
10. **Fail loud** — "done" is wrong if anything was skipped; "tests pass" is wrong if any were skipped.
11. **A red test is a claim before it is a failure** — say what the test asserts and whether your fix keeps that claim or replaces it; if the claim is wrong, fix the claim and say so.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant code
  yourself — delegate, and when in doubt, delegate. Your lane: coordinate, inspect, plan, review
  diffs, run tests, edit non-behavioral docs. Only the `api-docker-*` agents get their skills force-loaded via `briefing.skills`.

  | Task | Agent |
  |---|---|
  | What the daemon does or expects — endpoints, wire formats, filters, registry auth, version gating | `api-docker-engine-worker` |
  | The Perl side — Moo, transport internals, entity classes, refactoring, cpanfile | `api-docker-worker` (default) |
  | Write/extend tests, add fixtures | `api-docker-test-writer` |
  | The generated type model, the `API::Docker::Type` DSL, the drift checker, `spec/` | `api-docker-type-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `api-docker-release-manager` |
  | POD and README | `api-docker-doc-writer` |

  The two workers split by *question*, not by file — only `api-docker-engine-worker` carries the Engine API reference.

- **You cannot spawn subagents** (an `api-docker-*` agent): the lock does not apply — implement, refactor, debug, test.

Behavior-relevant = the HTTP transport and everything it returns, the resource API method surface,
entity wrappers, request/response encoding, error handling, `cpanfile`, and tests — not prose, not `Changes`.

**Only `api-docker-release-manager` commits.** A worker leaves a commit-ready tree and hands its
card to `review`; you then dispatch `api-docker-release-manager` to cut the commit and close the card.

## Parallel fan-out — isolate the working tree

- **A subagent never mutates git** — no `stash`, `reset`, `checkout --`, `clean`, `add`, `commit`; the orchestrator owns git.
- **Two or more code-touching agents at once must be isolated** — `isolation: "worktree"` or sequentially, never in one tree.
- **A worktree may branch from a stale base.** Integrate by diff, never `git checkout <branch> -- <file>` — that reverts main.
- **Commit a verified-green checkpoint before the next mutating fan-out** — a committed HEAD survives a stray `reset`.

## Coordination — karr board (always in scope)

`karr` is always in scope for the orchestrating agent — just use it, don't invoke the
coordination skill first. State lives in `refs/karr/*`; one board, this repo. `karr list --compact`
/ `karr board` for open work, `karr show ID` for detail, `karr create/edit/move/handoff` for the
flow; mutating commands auto-sync. Use it for drift to reconcile and follow-up work that must not
block the current change. Full surface: skill `kanban-issues-karr-coordination`.

**Serialize board mutations when fanning out** — collect the results and loop `karr move`/`handoff`/`sync` sequentially.

## Release — never without permission

`dzil build`, `dzil test` and `prove -lr t/` are fine anytime. `dzil release` and any CPAN upload
are STRICTLY forbidden without the maintainer's explicit go-ahead — even if `Changes` or a plan
names "release" as the next step; for anything heading toward release: stop and ask.

## Public issues — never act without instruction

**karr** is the internal agent board, churned freely. **GitHub issues on `Getty/p5-api-docker`** and CPAN RT carry real humans' reports under the
maintainer's name. **Never act on a public issue on your own initiative — not even to read it.**
No listing, viewing, commenting, editing, closing or creating unless the user names a specific item to handle.

## API-Docker-specific hazards — mechanics in skill `api-docker-hazards`

- **Which engine is there is a fact about the machine.** `check_live_access` answers a missing socket with
  `skip_all`, so a live run can report success while testing nothing. A measurement names engine and version.
- **Live write tests mutate the real engine.** `API_DOCKER_TEST_WRITE=1` creates and removes real containers,
  images, networks and volumes; an interrupted run leaves them behind. Run only when the task is about live behavior.
- **No `prune` of any kind, no `rm -a`, no `system reset`, on either engine, ever, unless the user names the
  command.** `dangling => ['false']` removes every unused *tagged* image, locally built ones included.
- **`images->push` publishes.** With credentials it writes to a real registry under the maintainer's account. Never run it — or any test that does — without explicit instruction.
- **Streaming endpoints block until the daemon closes, unless given a callback.** Pass `on_event`/`on_frame`/`on_chunk` or bound the window; a callback still needs `$stop->()`.
- **`../p5-dist-zilla-plugin-docker-api` consumes this API.** A public signature or return-shape change is a cross-repo change: verify that repo or file a ticket there.
- **`[@Author::GETTY]` gathers through `Git::GatherDir` — tracked files only.** A new `.pm`, test or fixture is
  invisible to `dzil build`/`dzil test` until it is `git add`-ed; `prove -lr t/` stays green.
