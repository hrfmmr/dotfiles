---
name: desk
description: >
  Interactive task protocol driven by Obsidian task notes. The root session holds the task and dialogues with the user in real time; the task note keeps a fixed top-of-note view (現在地 / 設計 / Milestones / 論点) plus an Event Log that gains a Turn-N only when real progress occurs, mirrored to a bd issue.
  Use when user says "$desk", "desk", "$desk new", "$desk --sync" (alias "--flush"), "$desk-live", "desk-live", "create task", "start task", "resume work", or wants to start, resume, or update a desk-managed task note (planning Q&A, design decisions, milestone progress) for impl/research/adhoc tasks.
---

# Desk

## Overview

Interactive task protocol on an Obsidian task note. The root session holds the task and dialogues with the human in real time — no sub-agent spawn, no async signal cycle.

The task note is the human's state view. A fixed block at the top always answers "which phase are we in, which decisions remain, what is left, what should the human do next". Below it, an Event Log gains a Turn-N only when a real progress event occurs. The bd issue mirrors the same state so an agent can recover cold.

Delegate concrete work to existing skills ($wt / $rough-plan / $grill-me / $tk / $review / $commit / $join / $beads / $herdr-impl / $hunk-present).

### Architecture

| component | role |
|-----------|------|
| Task note | Human-facing state. Fixed head sections are the source of truth; the Event Log is the changelog of head-section changes. |
| bd issue | Agent-recoverable mirror. `design` field = latest snapshot (replace); comments = event summaries (append). |
| desk skill | Note contract, event gate, session lifecycle. |
| Root session | Single writer of the note and the bd issue. |

## Prerequisites

- cwd is an Obsidian vault root (works with any vault).
- For impl/research tasks, `BEADS_DIR` must be defined in the target repo's `.envrc`.
- When task frontmatter contains `beads_dir`, treat it as the source of truth for beads transport: derive `BEADS_DOLT_SERVER_SOCKET="$beads_dir/dolt-server.sock"` and `BEADS_DOLT_AUTO_START=0` before invoking `$beads` or raw `bd`. Never run raw `bd` with `BEADS_DIR` alone — it auto-starts a stale Dolt instance and existing issues appear missing.

## Invocation

| pattern | behavior |
|---------|----------|
| `$desk` | Scan daily-note (yyyy-mm-dd.md) for `[[task note]]` links and notes with `status: in_progress\|in_review`. Present candidates; human selects. |
| `` $desk `<task-note-name>` `` | Open an interactive session on the task (see Session Lifecycle). If the note does not exist, suggest `$desk new`. |
| `$desk new` | Create a new task (see Init). |
| `$desk --sync` (alias `--flush`) | Reconcile the note with the conversation (see `--sync`). |

Removed forms: `$desk ps` and `$desk run`. If the user types one, say it was removed and open the task via `` $desk `<task-note-name>` ``. For a cross-note overview use the Dataview "Active Tasks" query in `references/vault-integrations.md`.

## Task Types

| type | target repo | worktree | bd issue | PR |
|------|-------------|----------|----------|----|
| impl | required | required | required | optional |
| research | required | required | required | — |
| adhoc | — | — | — | — |

All types share the same note structure. For adhoc, keep 論点 few and skip every bd step.

## Standard impl workflow

For `task_type: impl`, follow this standard:

- **plan**: settle 論点 and draft the rough plan with `$rough-plan` (invokes `$grill-me` for requirement clarity, `$creative-problem-solver` for approach trade-offs, and at its Step 4.5 `$critique` — or `$herdr-critique-loop` when `HERDR_ENV=1` — to converge to no-HIGH before approval). The approved plan lands in 設計 > 設計方針・構成 and Milestones.
- **impl**: delegate to `$herdr-impl` when `HERDR_ENV=1`; otherwise run the fallback cycle (`$tk` → `$review` → `$commit`) in the root session. The commit standard on both paths is `$commit`.
- **verify**: internalized in `$herdr-impl` (its `herdr-review-loop`); on the fallback, use `$review`. Do not run a separate verify pass on the Herdr path.
- **pre-present grooming**: before any `$hunk-present` presentation, the branch must satisfy `$commit`'s pre-PR grooming contract — `$herdr-impl` internalizes this in its Step 7; on the fallback cycle, groom before presenting.
- **human review**: present the implemented diff with `$hunk-present` (sidecar reading map in a dedicated Herdr tab, questions as inline hunk comments, verdict recorded there). On the Herdr path, reuse `$herdr-impl`'s implementer worker as the hunk fix worker (no new spawn) and pass it the hunk session coordinates per `$hunk-present`'s Fix worker spawn contract.

## Task Note Contract

### Frontmatter

```yaml
---
source_issue_link: ""      # impl/research: required, adhoc: optional
target_repo: ""            # impl/research: required
git_working_tree: ""       # impl/research: required
beads_dir: ""              # impl/research: required; source path for BEADS_DOLT_SERVER_SOCKET=<beads_dir>/dolt-server.sock
bd_issue_id: ""            # impl/research: required
status: "not_started"      # required: not_started | in_progress | in_review | done
current_status_summary: "" # required: one-line projection of 現在地
pull_request_url: ""       # impl: optional
figma_url: ""              # optional
task_type: ""              # required: impl | research | adhoc
---
```

### `current_status_summary` Contract

- One line describing the critical-path progress in milestone context: what meaningful unit of work is underway, blocked, or just completed.
- Refresh it whenever 現在地 is refreshed.
- Do not use orchestration mechanics as the summary body.
- Good: `Milestone 2/4 complete. Roundup derivation passed; awaiting E2E re-confirmation.`
- Bad: `Resumed session`, `Set up hook`.

### Status Transitions

```
not_started → in_progress → in_review → done
                   ↑            │
                   └────────────┘  (review requests changes)
```

Flip `not_started` → `in_progress` when the first substantive work begins.

### Sections (fixed order)

Exact template: `references/note-templates.md`.

| section | holds | update style |
|---------|-------|--------------|
| `## 現在地` | Derived view: 位置 (Milestone-based, e.g. `M3/5 <name>`), 未決の論点 (D-ids), 残TODO (count + next one), Next Action (human), Next Action (agent), as of (`Turn-N`, the last Turn this view reflects). | Rewrite in place. Refresh with every head update. |
| `## 設計` | Fixed sub-sections: 問題定義 (one line) / 成功基準 / 前提 (Facts) / 設計方針・構成. | Rewrite in place. |
| `## Milestones` | Dataview table (`bd_issue::`, `summary::`, `milestone_status::` = open \| in_progress \| done \| skipped). | Update rows in place; keep each row's bd child issue consistent (`done` → `bd close`; `skipped` → `bd close --reason skipped`). Rows without a bd issue (adhoc) carry `—`. |
| `## 論点` | One `#### D-n <topic>` sub-section per substantial decision topic (see below). | Edit in place; overturn by supersede. |
| `## Event Log` | `### Turn-N` entries, newest last. | Append only. |

**論点 entry**: `decision_status:: open | decided | superseded | dropped`, then 問い / 選択肢 / 判断 / 根拠 / 影響先. Use `decision_status::` (never bare `status::`) so it cannot collide with the frontmatter `status` in Dataview.

- Overturning a decided 論点: mark the original `superseded → D-m` and add `D-m` (noting `supersedes D-n`). Never overwrite the trail.
- Closing a 論点 without deciding: `dropped`, with the reason; if it is carried to a separate bd issue, name that issue.
- Grain: substantial topics — a decision that would change design, plan, or scope. Not per-file or per-function nitpicks.

**grill-me mapping**: `$grill-me` Snapshot fields land as Problem statement / Success criteria / Facts → 設計; Decisions / Open questions → 論点.

## Event Gate

An event is a change a human re-reading the note later would need in order to know where things stand.

**Events** (Turn required):
- 論点 added, decided, superseded, or dropped (or its options materially changed).
- 設計 changed substantively.
- Milestone status transition, or a row added/removed (scope change).
- Blocker or unexpected failure occurred/resolved. Errors during task execution are always events.
- Artifact or external event: PR created/merged, derived note, branch task note, human review verdict.
- Status change to `in_review` or `done`, or back to `in_progress`. The initial `not_started` → `in_progress` flip rides with whichever event triggers it and gets no Turn of its own.

**Non-events** (write nothing): Q&A or investigation that settled nothing; session mechanics, protocol semantics, skill invocation chatter; a 現在地-only refresh; for impl, per-commit and per-review-cycle detail (bd note only — see Checkpoint).

### Gate procedure

At the end of every task-substantive response, run the event check. If an event occurred, do all three **in the same response, before yielding**, in this order. The head is the truth, so an interrupted gate leaves the truth intact and the Turn and bd recoverable through `--sync`. Multiple events in one response share one Turn. Before step 1, run the note-drift test from the Drift check: if `as of` is ahead of the last Event Log Turn, an earlier gate was interrupted, so write its missing Turn first.

1. **Head**: first set 現在地 `as of` to the Turn number you are about to write (so the marker exists as soon as any head edit does), then update the affected head sections, then refresh the rest of 現在地 and `current_status_summary`.
2. **Turn**: append `### Turn-N` to the Event Log (format below).
3. **bd sync** (if `bd_issue_id` is set; run in background):

   ```bash
   # run_in_background: true — transport per $beads Session Start Protocol (socket-only)
   export BEADS_DIR=<beads_dir> BEADS_DOLT_SERVER_SOCKET="<beads_dir>/dolt-server.sock" BEADS_DOLT_AUTO_START=0
   bd update <bd_issue_id> --design-file - <<'EOF' && bd comment <bd_issue_id> "Turn-N: <event summary — decisions, identifiers, state transitions>" && bd dolt commit
   <現在地 + 設計 + 論点 snapshot>
   EOF
   ```

   The `&&` chain makes the comment a reliable marker: it exists only if the `design` replace succeeded. The `design` snapshot is self-contained: 現在地 (as of this event; between events bd may lag and the note is authoritative), 設計 (all four sub-sections), then 論点 (decided: 判断 + 根拠 in one line; superseded: the chain; open: 問い). On a milestone transition, also update the bd child issue (see Milestones).

   - **Verify replace semantics** on the first write in a session that replaces a non-empty `design` (known from Open's `bd show` or your earlier write): run that write in the foreground, then `bd show <bd_issue_id> --json` and require `design` to equal the snapshot exactly (not old + new). If not, stop writing `design` and tell the human. A write over an empty `design` proves nothing.
   - **Failure path**: check the background result when it finishes. On failure retry only the failed command (before re-running the comment, check that bd does not already have it), then tell the human and leave the drift for the next Open or `--sync` to repair.

**⚠ MOST COMMONLY VIOLATED**: the three steps are one atomic operation. Never yield after step 1 or 2 without verifying the rest was launched.

If no event occurred, write nothing. Refresh 現在地 and `current_status_summary` silently when a Next Action changed (no Turn, no bd sync, `as of` unchanged).

### Turn format

```markdown
### Turn-N <yyyy-MM-dd HH:mm JST> — <event title>
- <what happened>
  - <nested detail: finding, pointer to rationale, identifiers (bead IDs, commit SHAs, paths)>
- Updated: D-2 → decided; M3 → done; status → in_review; 設計 > 設計方針・構成
```

- The *why* lives in 論点 (判断 / 根拠); a Turn states what changed and points there.
- Never record raw Q&A, transcripts, or tool-call chatter.
- Turns are append-only and numbered monotonically. Fix a mistake with a new Turn.
- Append artifact callouts at the end of the Turn (formats in `references/note-templates.md`); one per artifact.

### Drift check

Used by Open and `--sync` on non-legacy notes. Two independent signals:

- **Note drift**: 現在地 `as of` is ahead of the last Event Log Turn (a head update whose Turn was never written), or a Turn's `Updated:` line is not reflected in the head. Recover: write the missing Turn, reconstructing its content from the head (`git log -p -- <note>` when the vault is a git repo) and marking it `(recovered)`; reconcile the head in the second case. A human's direct edit does not change `as of`, so it is not drift.
- **bd drift**: some Turn-N in the Event Log has no marker in bd: a comment starting `Turn-N:` (read with `bd comments <bd_issue_id> --json`) or, for legacy Turns, a `[Turn-N]` line in the issue notes (`bd show <bd_issue_id> --json`; use the JSON forms and do not rely on plain `bd show` for comment bodies). Check every Turn, not only the latest. Recover: replace `design` once, then, only after that succeeds, write one comment per missing Turn.

A 現在地-only refresh is never drift.

### Checkpoint (impl)

After each successful `$commit`: `bd note <bd_issue_id> "<sha>: <change summary>"` then `bd dolt commit`. Write a Turn only when the commit completes a milestone or is itself an event.

## Session Lifecycle

### 1. Open

1. Read frontmatter, all head sections, and the latest Turn.
2. If the note is legacy (see Legacy Notes), offer distillation first. Until it is distilled, skip step 5 and every `design` write.
3. If `bd_issue_id` is set, first establish bd transport per the `$beads` Session Start Protocol, then run `bd show <bd_issue_id>`.
4. If `git_working_tree` is set, cd to it.
5. Run the Drift check and repair what it finds.
6. Present 現在地 (especially Next Action) and begin the dialogue. Write nothing else on open.

### 2. Loop

For each user message:

1. Process the input (research, answer, discuss, execute).
2. **Native ask mode (MUST when available)**: for any human judgment call — plan direction, design, scope, trade-offs — ask through the host's native structured-question tool (e.g. `AskUserQuestion`), 2–4 concrete options, recommended first, each option's consequence stated. Fall back to prose only when no such tool exists; then use callout blocks with one bullet per question:

   ````markdown
   > [!question]
   > - **Q-1**: <question>
   > - **Q-2**: <question>
   ````
3. A settled question is recorded by updating its 論点 — not by logging the Q&A.
4. If a delegated skill (`$grill-me`, `$rough-plan`, `$herdr-impl`, …) produced the outcome, the desk session — not the skill — writes the note and bd. Suppress the skill's own writes (e.g. `$grill-me`'s bd issue reflection, Turns); the Event Gate covers them.
5. Run the Event Gate.

The human may edit the note directly in Obsidian; their text wins. Re-read the section you are about to update first.

### 3. Close

Triggered by "done" / "end" / "close" / "exit", or the user switching to another task or topic.

1. If an unrecorded event exists, run the Event Gate (or `--sync`).
2. Refresh 現在地 so Next Action is current (`current_status_summary` too).

No lock, lease, or heartbeat exists to clean up.

## `--sync`

Reconciliation for missed or half-written events.

1. Run the Drift check and repair what it finds.
2. Scan the conversation since the last Turn (or session start) against the head sections and Event Log, and collect events that meet the event test but are unrecorded.
3. For wholly missed events, first reconcile the head sections; then set `as of` to the number of the last Turn you are about to write, and write one Turn per distinct event in chronological order. Finally replace the bd `design` once and, only after that succeeds, write one bd comment per Turn.

## Init (`$desk new`)

1. Confirm `source_issue_link` and `task_type` with the human.
2. Branch by `task_type`:
   - **impl/research**: confirm `target_repo` → resolve `BEADS_DIR` from `.envrc` → derive socket vars → create the worktree via `$wt` (propose path/branch candidates, obtain approval) → create the bd epic via `$beads`.
   - **adhoc**: no worktree or bd issue; leave the fields empty.
3. **Seed 論点**: research the source issue and repo read-only, list the topics that need a decision, and present them via native ask for the human to add, remove, or merge. Fix the result as placeholders (`decision_status:: open`, other fields blank) so later work knows where each conclusion belongs.
4. Create the note at vault root from `references/note-templates.md`: fill 問題定義 and 前提 with what is known, leave the rest as placeholders, draft Milestones as a rough critical path, set `status: not_started`.
5. Treat creation as an event: write Turn-1 (`Task initialized`) and run the bd sync. Before the first `design` write, read `bd show`; fold any existing `design` content into 設計, because the replace would discard it.

## Planning

- impl: run `$rough-plan` unless the change is trivial. Trivial skip (1 file, a few lines, self-evident fix): record the skip and reason as one line in 設計 > 設計方針・構成 and treat it as an event.
- research/adhoc: settle open 論点 with `$grill-me` in the root session as needed.
- Plan approval is a native-ask decision recorded as an event.
- Once Milestones are derived, create a bd child issue per row (`bd create --parent <epic-id>` via `$beads`) and fill `bd_issue::`.
- If the approved plan is too long to keep the head readable, put it in a derived note and link it from 設計方針・構成.

## Execution

- `HERDR_ENV=1`: delegate to `$herdr-impl`, reusing the worktree created in Init. Its worker and reviewer panes never write the note or bd; the root session relays results as events.
- Otherwise run the fallback cycle in the root session: `$tk` → `$review` → `$commit`, with a Checkpoint after each commit.
- impl Turns cover milestone transitions, PR create/merge, review verdicts, blockers, and deviations from the design.

### Sub-issue discovery

When a derived sub-issue surfaces: `bd create "<title>" --parent <epic-id>`, create a dedicated branch task note for it, add a Milestones row, and treat it as an event (`> [!info] Branch` callout).

### Derived notes

When the work produces a substantial artifact (design doc, investigation report, decision record):

1. Create a new note in the vault root with a descriptive name.
2. **Tag inheritance**: copy all `#prj-*` tags from the parent task note's first line into the derived note's first line.
3. Link it from the relevant Turn with Obsidian wikilink syntax only (`[[Derived Note]]`) and a `> [!note] Derived Note` callout.
4. If `bd_issue_id` is set, reference it in the bd issue notes.

## Completion

1. When every Milestone is `done` or `skipped` and no 論点 is `open`, set `status: in_review` and run the Event Gate. For impl, present the final diff via `$hunk-present`; the verdict is recorded there.
2. **Done gate** — `status: done` requires all of: (a) no `open` 論点 (carry-over topics are closed as `dropped` with the follow-up issue named), (b) every Milestone `done` or `skipped`, (c) an explicit human verdict. If the human requests more work, return to `in_progress`, add Milestones or 論点 as needed, and record the event.
3. On pass, impl: verify the branch satisfies `$commit`'s pre-PR grooming contract (semantic-unit commits, English subjects); groom and re-sync if not. Create the PR via `$join` if needed and update `pull_request_url`.
4. Set `status: done` and run the Event Gate (head, Turn, bd sync), then close the bd epic (the human verdict is the required human check gate).

## Legacy Notes

A note without `## 現在地` (old `## Planning` / `## Dialogue` layout, possibly with `runtime_*`, `input::`, or `agent_instruction::`) is legacy. Do not rewrite it unprompted.

- **On open**: offer distillation via native ask, unless the Event Log already holds a `Legacy distillation declined` Turn.
- **If approved**: draft 現在地 / 設計 / 論点 from the Turns, `bd show`, and old Planning content (Snapshot and Plan → 設計, moving long content to a derived note linked from 設計方針・構成; decisions found in Turns → 論点, marked as reconstructed). Show the draft and write only after approval. Then rename `## Dialogue` to `## Event Log`, leave old Turns untouched, continue numbering, drop `runtime_*`, and map legacy status (`plan_ready` / `planning` → `not_started` or `in_progress`; `human_response_required` → `in_progress`).
- **If declined**: record a one-line `Legacy distillation declined` Turn so Open stops re-offering. The note has no head sections, so the event rule applies to Turn appends (below the existing Dialogue) and bd comments only — skip head updates and the bd `design` replace — and the done gate reduces to the human verdict. Map legacy status values on any status flip as above.

## Skill Delegation Map

| phase | delegated skill | purpose |
|-------|----------------|---------|
| Init | `$wt` | worktree creation |
| Init | `$beads` | bd epic issue creation |
| Planning | `$rough-plan` (grill-me + creative-problem-solver + critique) | rough plan + critique convergence + approval |
| Planning (research/adhoc) | `$grill-me` | requirement clarification |
| Execution | `$herdr-impl` (HERDR_ENV=1) / `$tk` + `$review` + `$commit` (fallback) | implement issue |
| Verify | `herdr-review-loop` (inside `$herdr-impl`) / `$review` (fallback) | review convergence |
| Human review | `$hunk-present` | diff reading map, hunk comment Q&A, verdict |
| Completion | `$join` | PR creation |
| All phases | `$beads` | bd issue CRUD & sync |

## Guardrails

- **Root session only**: the root session holds the task and is the single writer of the note and bd issue. Workers and reviewers spawned by delegated skills never write either.
- **Event Gate is a hard gate**: every task-substantive response ends with the event check; when an event occurred, head update + Turn + bd sync land in the same response. Batching or retroactive writes are a violation, except through `--sync`.
- **Head is truth**: head sections hold current state and the Event Log holds the change history; they must never contradict each other.
- **No raw logs**: never write verbatim Q&A, transcripts, or per-round narration into the note.
- **Done gate**: `done` requires no `open` 論点, all Milestones `done`/`skipped`, and an explicit human verdict.
- **Native ask mode is the default question channel** for plan- or direction-refining Q&A; prose is the fallback.
- **`$beads` mandatory for `bd` commands**: before the first `bd` read or write in a session, follow the `$beads` Session Start Protocol — export `BEADS_DIR` (from `beads_dir` or `.envrc`), derive `BEADS_DOLT_SERVER_SOCKET="$BEADS_DIR/dolt-server.sock"`, set `BEADS_DOLT_AUTO_START=0`. Never issue raw `bd` with `BEADS_DIR` alone.
- Dual writes to the note and bd are by design (human-facing view vs agent-recoverable mirror). The bd `design` snapshot must be self-contained enough for cold resume after session death.
- Prefer milestone-progress wording in `current_status_summary`.
- Root epic closure always requires a human check gate.
