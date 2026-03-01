---
name: beads
description: Use this skill when working with `bd` beads issue tracking in Codex, especially for multi-session work, dependency-driven execution, and resumable task orchestration via CLI or configured MCP tools.
---

# beads

Run a durable beads workflow in Codex using AGENTS.md guidance, `codex exec`, and a session checklist for short-horizon execution.

## When To Use

- Work spans multiple sessions and must survive context compaction.
- Tasks have dependency constraints and need `bd ready`/`bd blocked` control.
- You need explicit handoff notes and resumable execution.
- You are coordinating multiple workers against one shared beads graph.

## Session Start Protocol

1. Optional (when Dolt remote is configured): `bd dolt pull`.
2. `bd prime`
3. `bd ready --json`
4. Inspect target work with `bd show <id>`.
5. Claim work with `bd update <id> --claim`.

## Execution Protocol

- Discovery: create follow-up work and link with `discovered-from`.
- Blocking condition: set `--status blocked` and document the blocker in notes.
- Async waits: use `bd gate create` and `bd gate eval`.
- Parallel isolation: use `bd worktree create` for concurrent workers.
- Backend safety rule: even if Dolt backend operations crash, do not switch to `--db` ephemeral SQLite (for example `.beads/ephemeral.sqlite3`).
- On Dolt failure, recover on Dolt path only (for example `bd dolt start`, `bd dolt test`, `bd dolt set mode server`) and then retry.
- Commit granularity rule: after each logically atomic bd issue mutation set (same unit as a proper git commit boundary), run `bd dolt commit` immediately.
- Push pairing rule: whenever `bd dolt commit` succeeds, run `bd dolt push` in the same operation block.

## Session End Protocol

1. Update notes in `COMPLETED / IN_PROGRESS / NEXT` form.
2. Optional (when Dolt remote is configured): `bd dolt push`.

## References

- Operational guides: `references/guides/*.md`
- Codex runtime snippets: `references/runtime/*.md`
- Optional scripts: `scripts/*.sh`
