---
name: beads
description: Use this skill when working with `bd` beads issue tracking in Codex, especially for multi-session work, dependency-driven execution, recurring troubleshooting knowledge capture, and resumable task orchestration via CLI or configured MCP tools.
---

# beads

Run a durable beads workflow in Codex using AGENTS.md guidance, `codex exec`, and a session checklist for short-horizon execution.

## When To Use

- Work spans multiple sessions and must survive context compaction.
- Tasks have dependency constraints and need `bd ready`/`bd blocked` control.
- You need explicit handoff notes and resumable execution.
- You are coordinating multiple workers against one shared beads graph.
- You are handling recurring beads or Dolt failures and need to consolidate fixes into a durable runbook issue.

## Session Start Protocol

1. Run a socket-mode preflight before any `bd` read:
   - require `BEADS_DIR` for workspace targeting
   - resolve `BEADS_DOLT_SERVER_SOCKET` in this order:
     1. if a caller such as `$desk` already supplied `beads_dir`, derive `BEADS_DOLT_SERVER_SOCKET="$BEADS_DIR/dolt-server.sock"`
     2. otherwise prefer repo-level env loading such as `.envrc`
   - if `BEADS_DOLT_SERVER_SOCKET` is still unset after that resolution, set it to `"$BEADS_DIR/dolt-server.sock"`
   - confirm whether an externally managed authoritative `dolt sql-server --socket <path>` is available at that path
   - if the socket file is missing, start or ask for startup of the external `dolt sql-server --socket <path> --data-dir <repo>/.beads/dolt` before any `bd` read
   - set `BEADS_DOLT_AUTO_START=0` for the session
   - do not treat existing TCP host/port config or a live localhost TCP listener as the default path until socket mode has been checked and rejected
2. Optional (when Dolt remote is configured): `bd dolt pull`.
3. `bd prime`
4. `bd ready --json`
5. Inspect target work with `bd show <id>`.
6. Claim work with `bd update <id> --claim`.

## Hierarchy Bootstrap Rule

- Before creating a new leaf task, identify the durable artifact hierarchy that the work belongs to.
- If the work is part of a document, note, plan, feature stream, or other long-lived artifact, create or locate the parent chain first:
  - root epic for the top-level artifact stream
  - child task for the specific artifact being edited
  - sub-task for the current critique/refactor/validation pass
- Prefer `bd create --parent <id>` over standalone tasks when the parent artifact is knowable.
- When the root epic already exists, prefer explicit descendant IDs that inherit the epic ID as a visible prefix instead of accepting unrelated auto-generated sibling IDs.
- For known hierarchies, create descendants with both `--parent <id>` and `--id <epic-id>.<n>` / `--id <epic-id>.<n>.<m>` so the graph is readable from the ID alone.
- If earlier flat tasks already exist for the same artifact, attach them under the correct parent with `parent-child` dependencies instead of leaving them as siblings.
- Keep hierarchy depth at 3 levels maximum: epic -> task -> sub-task. If a fourth level seems necessary, open a new sibling task under the epic instead.
- For note-driven work, use this default mapping unless the repo already defines a stronger convention:
  - parent note / root document -> epic
  - per-note deliverable -> task
  - critique / structure / readability / validation pass -> sub-task

## Issue ID Hierarchy

When creating issues manually, use IDs that visibly inherit the root epic ID:

| Level | Format | Meaning | Example |
|-------|--------|---------|---------|
| Epic | `<epic-id>` | Top-level work stream | `obsidian-baq` |
| Task | `<epic-id>.<N>` | Deliverable unit within an epic | `obsidian-baq.1` |
| Sub-task | `<epic-id>.<N>.<M>` | Atomic step within a task | `obsidian-baq.1.1` |

Rules:
- Once a root epic exists, descendants must inherit that exact epic ID as their prefix.
- Increment `N` for sibling tasks under the epic, and increment `M` for sibling sub-tasks under the task.
- When creating descendants under a known epic, do not rely on unrelated auto-generated IDs; pass both `--parent` and an explicit `--id`.
- Use `bd create --parent <epic-id> --id <epic-id>.<N>` for tasks, and `bd create --parent <epic-id>.<N> --id <epic-id>.<N>.<M>` for sub-tasks.
- If the repo or database convention requires a custom prefix for the root epic, preserve that root epic ID verbatim and extend only with numeric suffixes.
- Keep depth at 3 levels maximum. If deeper nesting is needed, create a new epic instead.

## Execution Protocol

- Discovery: create follow-up work and link with `discovered-from`.
- Ideation logging rule: when a turn expands alternatives, trade-offs, or exploratory Q&A for a bd-scoped topic, append a durable summary to the relevant issue before ending the turn. Capture at least `Background`, `Problem`, `Options`, `Review`, `Recommendation`, and any material Q&A that changed the framing.
- Default discussion logging rule: unless the user explicitly asks not to, treat substantive background/problem/solution dialogue as issue context that should be preserved in notes or comments rather than left only in chat history.
- Validation frontier rule: when proof still depends on real credentials, external services, CI runs, manual review, or any other non-mocked execution, treat that proof as unfinished work. Create explicit child tasks for each remaining validation frontier (for example local smoke test, CI workflow validation, manual review) instead of closing the parent graph on code-only evidence.
- Troubleshooting incident rule: when any error or unexpected operational problem appears during work, create a derived bd sub-issue even if it is incidental to the main task.
- Troubleshooting issue shape: create it under the active issue when possible, add the `troubleshooting` label, and preserve provenance with `discovered-from` when it does not conflict with an existing parent-child edge.
- Troubleshooting evidence rule: record the problem, suspected cause, workaround, and execution log in the issue description or notes before resuming the main task.
- Recurring incident knowledge rule: when a beads, Dolt, or backend-access failure mode recurs or is likely to recur, consolidate the durable knowledge into a dedicated runbook issue instead of leaving evidence fragmented across isolated incident tickets.
- Runbook issue pattern: create or reuse one stable knowledge issue with a clear title such as `bd dolt db access corruption runbook`, link incident issues to it, and keep the runbook updated as the primary reference.
- Runbook evidence shape: preserve symptom signatures, detection commands, failed hypotheses, successful recovery commands, verification checks, root-cause confidence, and open questions so later incidents can skip first-pass rediscovery.
- Db-down fallback rule: if `bd` itself is unavailable because Dolt access is broken, gather evidence directly from `.beads/issues.jsonl`, `.beads/interactions.jsonl`, `.beads/metadata.json`, `.beads/config.yaml`, and `dolt-server.log`, then backfill the runbook issue after `bd` access is restored.
- Transport rule: separate `localhost` reachability from beads/Dolt correctness before treating the database as broken.
- Managed-server bind rule: do not assume `bd dolt start` will honor a non-localhost client host override. When validating sandbox access, verify the actual listen address with process or log evidence instead of inferring it from `metadata.json` or env overrides alone.
- Sandbox socket rule: treat one externally managed `dolt sql-server --socket <path>` plus clients that require `BEADS_DOLT_SERVER_SOCKET=<path>` and set `BEADS_DOLT_AUTO_START=0` as the default operating pattern. Use host-bound TCP rebinding only as a secondary fallback.
- Socket derivation rule: when a caller already knows `BEADS_DIR` structurally, prefer deriving `BEADS_DOLT_SERVER_SOCKET="$BEADS_DIR/dolt-server.sock"` over inventing a second explicit socket source. This keeps task-note state, repo env, and live server path aligned.
- Socket path rule: prefer a repo-scoped socket path such as `.beads/dolt-server.sock`. Avoid shared socket paths such as `/tmp/mysql.sock` unless a repo-scoped path is impossible.
- Transport precedence rule: check socket viability before trusting live TCP repo settings, existing localhost listeners, or TCP-oriented diagnostics. Use TCP only after socket mode has been checked and rejected.
- Sandbox socket validation rule: validate the socket path with store-backed commands first. Prefer `bd show <id>`, `bd ready --json`, one safe write such as `bd update <id> --notes ...`, and when remotes matter `bd dolt remote list`, `bd dolt pull`, and `bd dolt push`. Do not rely on `bd dolt test`, `bd dolt show`, or `bd context` as the primary health signal in socket mode because some diagnostics remain host/port-oriented.
- Socket permission rule: if socket access fails with `operation not permitted`, treat the socket path, file location, and session-level permissions as the primary suspects before treating the Dolt server as down.
- Socket missing rule: if socket access fails with `no such file or directory`, treat external server setup as the primary suspect. Verify the expected repo-local socket path and start the external `dolt sql-server --socket <path>` before attempting TCP fallback.
- No-helper-script rule: do not require repo-local wrapper scripts for normal beads startup or access. Prefer `.envrc` plus direct `dolt sql-server --socket <path> --data-dir <repo>/.beads/dolt` setup so a fresh session can recover from first principles.
- Blocking condition: set `--status blocked` and document the blocker in notes.
- Async waits: use `bd gate create` and `bd gate eval`.
- Parallel isolation: use `bd worktree create` for concurrent workers.
- Backend safety rule: even if Dolt backend operations crash, do not switch to `--db` ephemeral SQLite (for example `.beads/ephemeral.sqlite3`).
- On Dolt failure, recover on Dolt path only (for example `bd dolt start`, `bd dolt test`, `bd dolt set mode server`) and then retry.
- Sandbox auth rule: if sandbox clients use an external Dolt server, scope credentials deliberately. Prefer a dedicated read-only SQL user for read-mostly validation, and only reuse maintainer/write credentials after explicit ownership, auth, and rollback decisions are recorded in the active issue.
- Git worktree fallback rule: if `bd` fails inside a git worktree because `.beads` resolution or `bd dolt` points at a broken worktree-local repo, stop troubleshooting in that worktree and switch all `bd` commands to the main repository checkout that owns the shared `.beads` database. Use the main checkout to run `bd show`, `bd ready`, `bd update`, `bd dolt status`, `bd dolt commit`, and `bd dolt push`, then continue code changes in the worktree.
- Closure gate rule: before closing an issue or allowing an epic to auto-close, compare the acceptance criteria and current proof. If the remaining gap is "real run still not executed" rather than "code not written", do not close. Create or reopen follow-up validation issues immediately so the bd graph remains the source of truth.
- Commit granularity rule: after each logically atomic bd issue mutation set (same unit as a proper git commit boundary), run `bd dolt commit` immediately.
- Push pairing rule: whenever `bd dolt commit` succeeds, run `bd dolt push` in the same operation block.

## Misc

- Source-of-truth rule for beads implementation checks: when you need to inspect beads source to explain or validate runtime behavior, prefer the local repo at `$HOME/src/github.com/steveyegge/beads` and confirm the checked-out tag or commit before drawing conclusions. Do not rely on unrelated Go module cache paths under `$HOME/pkg/mod/...` as the primary source of truth for the installed `bd` binary.
- Socket-source rule: if you need one explicit place to store the socket contract, prefer `BEADS_DIR` plus the deterministic suffix `dolt-server.sock`. Avoid adding a second task-note field for the full socket path unless a repo cannot use the standard repo-local socket layout.

## Session End Protocol

1. Update notes in `COMPLETED / IN_PROGRESS / NEXT` form.
2. Optional (when Dolt remote is configured): `bd dolt push`.

## References

- Socket mode guide: `references/guides/SOCKET_MODE.md`
- Operational guides: `references/guides/*.md`
- Codex runtime snippets: `references/runtime/*.md`
