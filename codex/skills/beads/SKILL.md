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

## Issue ID Hierarchy

When creating issues manually (not via `bd create` auto-ID), use a hierarchical integer suffix `<prefix>.M.N.O`:

| Level | Format | Meaning | Example |
|-------|--------|---------|---------|
| Epic | `<prefix>.M` | Top-level work stream | `5km.7` |
| Task | `<prefix>.M.N` | Deliverable unit within an epic | `5km.7.1` |
| Sub-task | `<prefix>.M.N.O` | Atomic step within a task | `5km.7.1.1` |

Rules:
- Increment N within the same epic, O within the same task.
- When using `bd create --parent`, mirror the parent's suffix and append the next integer.
- The prefix portion (e.g., `5km`, `healthcare-infra-g8b`) comes from the bd database or project convention; the `.M.N.O` suffix is the hierarchy.
- Keep depth at 3 levels maximum. If deeper nesting is needed, create a new epic instead.

## Execution Protocol

- Discovery: create follow-up work and link with `discovered-from`.
- Ideation logging rule: when a turn expands alternatives, trade-offs, or exploratory Q&A for a bd-scoped topic, append a durable summary to the relevant issue before ending the turn. Capture at least `Background`, `Problem`, `Options`, `Review`, `Recommendation`, and any material Q&A that changed the framing.
- Default discussion logging rule: unless the user explicitly asks not to, treat substantive background/problem/solution dialogue as issue context that should be preserved in notes or comments rather than left only in chat history.
- Validation frontier rule: when proof still depends on real credentials, external services, CI runs, manual review, or any other non-mocked execution, treat that proof as unfinished work. Create explicit child tasks for each remaining validation frontier (for example local smoke test, CI workflow validation, manual review) instead of closing the parent graph on code-only evidence.
- Troubleshooting incident rule: when any error or unexpected operational problem appears during work, create a derived bd sub-issue even if it is incidental to the main task.
- Troubleshooting issue shape: create it under the active issue when possible, add the `troubleshooting` label, and preserve provenance with `discovered-from` when it does not conflict with an existing parent-child edge.
- Troubleshooting evidence rule: record the problem, suspected cause, workaround, and execution log in the issue description or notes before resuming the main task.
- Blocking condition: set `--status blocked` and document the blocker in notes.
- Async waits: use `bd gate create` and `bd gate eval`.
- Parallel isolation: use `bd worktree create` for concurrent workers.
- Backend safety rule: even if Dolt backend operations crash, do not switch to `--db` ephemeral SQLite (for example `.beads/ephemeral.sqlite3`).
- On Dolt failure, recover on Dolt path only (for example `bd dolt start`, `bd dolt test`, `bd dolt set mode server`) and then retry.
- Git worktree fallback rule: if `bd` fails inside a git worktree because `.beads` resolution or `bd dolt` points at a broken worktree-local repo, stop troubleshooting in that worktree and switch all `bd` commands to the main repository checkout that owns the shared `.beads` database. Use the main checkout to run `bd show`, `bd ready`, `bd update`, `bd dolt status`, `bd dolt commit`, and `bd dolt push`, then continue code changes in the worktree.
- Closure gate rule: before closing an issue or allowing an epic to auto-close, compare the acceptance criteria and current proof. If the remaining gap is "real run still not executed" rather than "code not written", do not close. Create or reopen follow-up validation issues immediately so the bd graph remains the source of truth.
- Commit granularity rule: after each logically atomic bd issue mutation set (same unit as a proper git commit boundary), run `bd dolt commit` immediately.
- Push pairing rule: whenever `bd dolt commit` succeeds, run `bd dolt push` in the same operation block.

## Session End Protocol

1. Update notes in `COMPLETED / IN_PROGRESS / NEXT` form.
2. Optional (when Dolt remote is configured): `bd dolt push`.

## References

- Operational guides: `references/guides/*.md`
- Codex runtime snippets: `references/runtime/*.md`
- Optional scripts: `scripts/*.sh`
