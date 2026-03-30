---
name: desk
description: >
  Stateless task protocol driven by Obsidian task notes. Defines state transitions and cold resume procedures for the full task lifecycle — intake, planning, execution, completion. Each agent session is an independent, stateless worker that restores context from the task note and bd issue, executes, then terminates.
  Use when user says "$desk", "desk", "create task", "start task", "resume work", "$desk ps", "$desk run", or wants to manage implementation/research/ad-hoc tasks via Obsidian task notes with async human-agent dialogue or inspect/resume task execution.
---

# Desk

## Overview

Stateless task protocol that defines state transitions and cold resume procedures, using Obsidian task notes as the sole human interface.
Each agent session is an independent worker: restore context from task note + bd issue → execute → terminate.
Delegate concrete work to existing skills ($wt / $grill-me / $tk / $review / $commit / $join / $beads).

### Architecture

| component | role |
|-----------|------|
| Task note | State machine store (frontmatter=state, Dialogue=I/O channel) |
| bd issue | Agent-recoverable log for cold resume |
| desk skill | State transition rules + cold resume protocol |
| post-commit hook | Event-driven signal generation |
| Stop Hook | Auto-resume trigger on root session idle |
| `.desk/runtime/` | External observability (lock files + logs) |
| Each agent session | Stateless worker (restore → execute → terminate) |

## Prerequisites

- cwd is an Obsidian vault root (works with any vault).
- obsidian-git plugin enabled (auto-commit interval ≈ 3 min).
- For impl/research tasks, `BEADS_DIR` must be defined in the target repo's `.envrc`.

## Invocation

| pattern | behavior |
|---------|----------|
| `$desk` | Scan daily-note (yyyy-mm-dd.md) for `[[task note]]` links + detect notes with status in_progress/human_response_required. Present candidates; human selects to resume. |
| `$desk <task-note-name>` | Resume or init the specified task directly. |
| `$desk new` | Create a new task. |
| `$desk ps [--all\|--inactive]` | List desk-managed tasks with task status, milestone progress summary, runtime state, assigned sub-agent, and heartbeat. Default shows non-done tasks; `--inactive` narrows to tasks without an active sub-agent lease. |
| `$desk run <task-note-name> [--force]` | Explicitly ensure the specified task has an active sub-agent now. Use for inactive/stale tasks. `--force` marks an existing runtime lease stale and re-assigns the task. |

## Task Types

| type | target repo | worktree | bd issue | PR |
|------|-------------|----------|----------|----|
| impl | required | required | required | optional |
| research | required | required | required | — |
| adhoc | — | — | — | — |

## Frontmatter Spec

YAML frontmatter for task notes. Required/optional varies by task type.

```yaml
---
source_issue_link: ""      # impl/research: required, adhoc: optional
target_repo: ""            # impl/research: required
git_working_tree: ""       # impl/research: required
beads_dir: ""              # impl/research: required
bd_issue_id: ""            # impl/research: required
status: "not_started"      # required (all types)
current_status_summary: "" # required (all types)
pull_request_url: ""       # impl: optional
figma_url: ""              # optional (all types)
task_type: ""              # required: impl | research | adhoc
runtime_status: ""         # optional: idle | running | waiting_human | done | stale
runtime_subagent_id: ""    # optional: currently assigned sub-agent id
runtime_subagent_role: ""  # optional: planner | executor | reviewer | finisher
runtime_heartbeat_at: ""   # optional: ISO8601 UTC timestamp of latest agent checkpoint
---
```

### `current_status_summary` Contract

- Write the current critical-path progress in the task's milestone context.
- Describe what meaningful unit of work is underway, blocked, or just completed.
- Do not use orchestration mechanics as the summary body.
- Good:
  - `未コミット差分の意図確認を進めつつ、重要参考リンクのターゲット検証を実行中。`
  - `Milestone 2/4 完了。roundup の派生要約は通り、E2E の再確認待ち。`
- Bad:
  - `background sub-agent を再開`
  - `hook をセットアップした`

### Runtime Lease Contract

- Treat the runtime fields as the desk control-plane truth for "is a sub-agent actively assigned?".
- `runtime_status: running` means a sub-agent currently owns the task.
- `runtime_status: waiting_human` means the task is blocked on note input, even if no agent is actively computing.
- `runtime_status: stale` means the prior lease is no longer trusted and `$desk run ... --force` may reclaim it.
- Update `runtime_heartbeat_at` on spawn, before/after major checkpoints, and whenever ownership changes.
- When a sub-agent exits cleanly, clear `runtime_subagent_id`, set `runtime_subagent_role` appropriately or empty it, and set `runtime_status` to `idle`, `waiting_human`, or `done`.

### Status Transitions

```
not_started → plan_ready → planning → in_progress → human_response_required ⇄ in_progress → in_review → done
```

## Phase 0: Init (`$desk new`)

1. **Signal hook check**: Run `scripts/setup-hook.sh "$PWD"`. If hook is missing, prompt y/N for auto-install. On skip, warn that signal detection is inoperative and continue.
2. Confirm `source_issue_link` and `task_type` with the human.
3. Branch by `task_type`:
   - **impl/research**: Confirm `target_repo` → resolve `BEADS_DIR` from `.envrc` → create worktree via `$wt` (propose path/branch candidates, obtain approval) → create bd epic issue via `$beads`.
   - **adhoc**: No worktree or bd issue required. Leave corresponding frontmatter fields empty.
4. Create the task note at vault root (populate frontmatter + empty Planning / Milestones / Dialogue sections).
5. Transition to `status: plan_ready`.

### Initial Task Note Structure

```markdown
---
(frontmatter)
---

# <Task Name>

## Planning

### Snapshot
<!-- Written after grill-me snapshot is finalized -->

### Plan
<!-- Finalized execution plan -->

## Milestones

| bd_issue:: | summary:: | milestone_status:: |
|------------|-----------|-------------------|

## Dialogue
<!-- Turn-N headings appended here -->
```

## Phase 1: Planning

Spawn a sub-agent with the working tree as cwd to refine the plan. Before spawn, set `runtime_status: running`, `runtime_subagent_role: planner`, `runtime_subagent_id`, and `runtime_heartbeat_at`.

1. Write questions using the Q-ID scheme into the Planning section (see `references/async-dialogue-protocol.md`).
2. Insert async response guide into the note and fire a `terminal-notifier` notification.
3. Detect responses via **signal file mechanism** (below). On detection, resume deep-dive from questions marked `status:: done`. Add follow-up questions as `Q-n-m`.
4. Once all open questions are exhausted, write the raw Snapshot to Planning > Snapshot. Sync to bd issue.
5. Write the finalized plan to Planning > Plan.
6. Populate the Milestones table with a rough critical path using Dataview inline fields.
7. Transition to `status: in_progress`.

## Phase 2: Execution

Each executor session is a **stateless worker**: restore context → execute a unit of work → checkpoint → terminate.
Multiple executor sessions may run sequentially on the same task (cold resume chain).

Before spawn, the invoking `$desk run` must:
1. Create `.desk/runtime/<task-name>.lock` (see Lock File Protocol below).
2. Set frontmatter: `runtime_status: running`, `runtime_subagent_role: executor`, `runtime_subagent_id: pid:<PID>`, `runtime_heartbeat_at`.

### Executor Work Cycle (single session)

```
restore context (frontmatter + latest Turn + bd show)
  → $tk (reasonable incision)
  → $review (approval gate)
  → $commit
  → checkpoint
  → if human input needed: write Turn-N, terminate
  → if more work remains and context budget allows: loop
  → else: terminate (next session picks up)
```

### Checkpoint Contract

After each successful `/commit`:
- Append to bd issue: `bd edit <issue-id> --append-notes "<commit-hash>: <change summary>"`.
- Persist: `bd dolt commit` → `bd dolt push`.

On each status transition:
- Update task note frontmatter `status` and `current_status_summary`.
- Update runtime lease fields if ownership or wait-state changed.
- Update `milestone_status::` in the Milestones table.

### Human Input Required

When human input is needed during execution, the agent writes Turn-N and **terminates** (does not wait).

1. Append a `Turn-N` heading to the Dialogue section. The `input:: pending` inline field is **mandatory** — signal detection depends on it.

```markdown
### Turn-N
input:: pending

**Context**: <why this decision is needed>
**Question**: <specific question requiring judgment>
**Options**: <enumerate choices if applicable>

> Write your response here. Change `input:: pending` to `input:: done` when finished.
```

2. Transition to `status: human_response_required`. Update frontmatter `current_status_summary`.
3. Set `runtime_status: waiting_human`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`.
4. Delete `.desk/runtime/<task-name>.lock`.
5. Fire `terminal-notifier` with obsidian:// URL.
6. **Terminate**. The agent session ends here.

Resume happens via cold resume (see Signal Mechanism + Stop Hook Auto-Resume below).

### Sub-issue Discovery

When a derived sub-issue surfaces during execution:
- Create via `bd create "<title>" --parent <epic-id>`.
- Add a row to the Milestones table.
- Address the sub-issue, logging context in its bd issue.

## Phase 3: Completion

1. After all milestones are complete, append a final human-check `Turn-N` to the Dialogue section.
2. Transition to `status: in_review`. Set `runtime_status: waiting_human`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`, and fire notification.
3. On human approval:
   - impl tasks: Create PR via `$join` if needed. Update frontmatter `pull_request_url`.
   - Close the bd epic issue.
4. Transition to `status: done`, set `runtime_status: done`, clear `runtime_subagent_id`, and refresh `runtime_heartbeat_at`.

## Runtime Visibility

### `$desk ps`

Run `scripts/desk_ps.sh <vault-root>` to display the unified status table:

```
task                       | status                  | agent     | heartbeat | alive?
---------------------------|-------------------------|-----------|-----------|-------
ios-kenko ヘルスケア連携UI  | human_response_required | —         | 2h        | —
ios-kenko Sourcery退役      | in_progress             | pid:12345 | 3m        | ✓
```

- Default: notes where `status != done`.
- `--inactive`: only tasks whose status suggests work remains but runtime lease is absent or stale.
- `--all`: include done tasks.

### `$desk run`

1. Read task note frontmatter → choose spawned role:
   - `plan_ready` or `planning` → planner
   - `in_progress` → executor
   - `human_response_required` with `input:: done` in latest Turn → executor (cold resume)
   - `human_response_required` with `input:: pending` → do not spawn; report blocked
   - `in_review` → finisher only after the required human check is satisfied
2. Guard: if `.desk/runtime/<task>.lock` exists and PID is alive → report existing lease, do not spawn. (`--force` overrides: delete stale lock, proceed.)
3. **Pre-spawn**: create `.desk/runtime/<task>.lock` with PID, timestamp, role.
4. **Spawn** Agent tool with `run_in_background: true` and cold resume context (see below).
5. **Post-spawn**: delete consumed `.desk/signals/<task>.ready` if present.
6. On agent completion: delete `.desk/runtime/<task>.lock`, update frontmatter.

### Cold Resume Context (executor spawn prompt)

Include exactly:
- Task note frontmatter (full)
- Latest Dialogue Turn (most recent `Turn-N` section)
- `bd show <bd_issue_id>` output
- Working tree path and branch
- Instruction to follow Turn-N protocol with mandatory `input:: pending` inline field

## Signal Mechanism

### Layer 1: obsidian-git post-commit Hook (signal generation)

Event-driven detection leveraging obsidian-git auto-commit (≈ 3 min interval).

```
auto-commit fires
  → .git/hooks/post-commit executes
    → scripts/check-signals.sh
      → Determine if changed files match a task note awaiting input
        → Match found & inline field `input:: done` detected
          → Create .desk/signals/<task-name>.ready
          → Fire terminal-notifier
```

### Layer 2: Stop Hook Auto-Resume (signal consumption)

Claude Code `hooks.Stop` fires when the root session goes idle. `scripts/desk_stop_hook.sh` runs and:

1. Checks `.desk/signals/*.ready` — if found (FIFO, oldest first), returns `{"decision":"block","reason":"$desk run <task>"}`.
2. Checks `.desk/runtime/*.lock` for dead PIDs (`kill -0`) — if found, returns `{"decision":"block","reason":"$desk run <task> --force"}`.
3. Checks heartbeat staleness (>15 min with `runtime_status: running`) — fires `terminal-notifier` (does NOT block).
4. If nothing found, returns `{"decision":"allow"}`.

Execution time must be <1 second (no fswatch wait). Install via project settings:

```json
{
  "hooks": {
    "Stop": [{"hooks": [{"type": "command", "command": "bash <skill-dir>/scripts/desk_stop_hook.sh <vault-root>", "timeout": 10}]}]
  }
}
```

### Dedup: signal consumed → `.ready` file deleted before spawn. Lock + PID check prevents double spawn.

## Lock File Protocol

### `.desk/runtime/<task-name>.lock`

Created by `$desk run` **before** Agent tool invocation. Deleted by executor on clean exit or by `$desk run --force` on stale reclaim.

```
pid=<PID of claude CLI session>
started_at=<ISO8601 UTC>
role=<planner|executor|reviewer|finisher>
```

### `.desk/runtime/<task-name>.log`

Agent stdout/stderr. Useful for post-mortem debugging.

### Health check matrix

| lock exists | PID alive | heartbeat fresh | verdict |
|-------------|-----------|-----------------|---------|
| yes | yes | yes | ✓ running |
| yes | no | — | ✗ stale (auto-reclaim via Stop Hook) |
| no | — | — | — idle |
| yes | yes | no (>15 min) | ? hung (notify only) |

## Cold Resume Protocol

Cold resume is the **canonical** way agents resume work. Every `$desk run` is a cold resume.

0. **Signal hook check**: Run `scripts/setup-hook.sh "$PWD"`. If missing, prompt y/N for install.
1. On `$desk` invocation, run `scripts/desk_ps.sh "$PWD"` to show current state. Also collect:
   - `[[task note]]` links from daily-note (yyyy-mm-dd.md)
   - Consume any `.desk/signals/*.ready` files (mark as actionable)
2. Present candidates, prioritizing signal-ready tasks, then daily-note links.
3. After human selection (or auto-selection via Stop Hook), execute `$desk run <task>`.
4. `$desk run` reads: task note frontmatter + latest Dialogue Turn + `bd show <issue-id>`.
5. Spawn new agent session with this context. Agent restores from the appropriate Phase based on `status` + `current_status_summary`.

## Notification

```bash
VAULT_NAME=$(basename "$PWD")
terminal-notifier \
  -title "desk: <task-name>" \
  -message "<status summary>" \
  -open "obsidian://open?vault=${VAULT_NAME}&file=<task-note-name>&heading=<target_heading>"
```

## Dataview Integration

### Pending Input View

Cross-note query aggregating `input:: pending`:

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  input AS "Input Status",
  current_status_summary AS "Summary"
FROM ""
WHERE input = "pending"
SORT file.mtime DESC
```

### Active Tasks

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  status AS "Status",
  task_type AS "Type",
  current_status_summary AS "Summary"
FROM ""
WHERE status AND status != "done" AND status != "not_started"
SORT file.mtime DESC
```

## Skill Delegation Map

| phase | delegated skill | purpose |
|-------|----------------|---------|
| Init | `$wt` | worktree creation |
| Init | `$beads` | bd epic issue creation |
| Planning | `$grill-me` (async adapted) | requirement clarification via Q&A |
| Execution | `$tk` | minimal-diff incision |
| Execution | `$review` | approval gate |
| Execution | `$commit` | micro-commit |
| Completion | `$join` | PR creation |
| All phases | `$beads` | bd issue CRUD & sync |

## Guardrails

- **Stateless workers**: Each agent session terminates after its work unit. No agent waits or polls.
- **Turn-N `input:: pending` is mandatory**: Signal detection depends on this inline field. Omitting it breaks the resume chain.
- All human dialogue is async via task note Turn-N. No synchronous interrupts.
- Dual writes to task notes and bd issues are by design (human-facing view vs agent-recoverable log).
- bd issue body/notes must be self-contained enough for cold resume after session death.
- Concurrent agent assignment to all in_progress tasks is permitted. Accept write-contention risk on shared BEADS_DIR.
- Prefer milestone-progress wording in `current_status_summary`; runtime mechanics belong in the runtime lease fields.
- Root epic closure always requires a human check gate.
- Lock files in `.desk/runtime/` are the external truth for agent liveness. Frontmatter `runtime_status` is self-reported.
