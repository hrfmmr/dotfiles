---
name: desk
description: >
  Stateless task protocol driven by Obsidian task notes. Defines state transitions and cold resume procedures for the full task lifecycle — intake, planning, execution, completion. Each agent session is an independent, stateless worker that restores context from the task note and bd issue, executes, then terminates.
  Use when user says "$desk", "desk", "create task", "start task", "resume work", "$desk ps", "$desk run", "$desk --flush", or wants to manage implementation/research/ad-hoc tasks via Obsidian task notes with async human-agent dialogue or inspect/resume task execution.
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
| Stop Hook | Auto-resume trigger on root session idle in Claude Code / Codex |
| `.desk/runtime/` | External observability (lock files + logs) |
| Each agent session | Stateless worker (restore → execute → terminate) |

## Prerequisites

- cwd is an Obsidian vault root (works with any vault).
- obsidian-git plugin enabled (auto-commit interval ≈ 3 min).
- [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) plugin enabled (for heading-level deep links in notifications).
- **Signal hooks installed** (both are required for async auto-resume):
  1. **post-commit hook**: `scripts/setup-hook.sh <vault-root>` — generates `.desk/signals/*.ready` on `input:: done`.
  2. **Stop Hook**:
     - Claude Code: `hooks.Stop` in `<vault-root>/.claude/settings.json`
     - Codex: `hooks.Stop` in `<vault-root>/.codex/hooks.json` (requires `[features] codex_hooks = true` in `~/.codex/config.toml`)
     Run `scripts/setup-hook.sh <vault-root>` to install both, or manually add this JSON to either config file:
     ```json
     {"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash <skill-dir>/scripts/desk_stop_hook.sh <vault-root>","timeout":10}]}]}}
     ```
- For impl/research tasks, `BEADS_DIR` must be defined in the target repo's `.envrc`.

## Invocation

| pattern | behavior |
|---------|----------|
| `$desk` | Scan daily-note (yyyy-mm-dd.md) for `[[task note]]` links + detect notes with status in_progress/human_response_required. Present candidates; human selects to resume. |
| `$desk <task-note-name>` | Resume or init the specified task directly. |
| `$desk new` | Create a new task. |
| `$desk ps [--all\|--inactive]` | List desk-managed tasks with task status, milestone progress summary, runtime state, assigned sub-agent, and heartbeat. Default shows non-done tasks; `--inactive` narrows to tasks without an active sub-agent lease. |
| `$desk run <task-note-name> [--force] [--no-plan]` | Explicitly ensure the specified task has an active sub-agent now. Use for inactive/stale tasks. `--force` marks an existing runtime lease stale and re-assigns the task. `--no-plan` skips plan-first approval and transitions directly to executor (use when bd issue already contains explicit steps). |
| `$desk --flush` | Catch-up sync: scan current session for unlogged discussion context, write a Turn-N summarizing decisions/findings/actions since the last Turn, and append a `bd comment` to the corresponding bd issue. Run as a background Agent. Use when Turn-N updates have been deferred or when the user explicitly requests a log flush. |

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
runtime_heartbeat_at: ""   # optional: ISO8601 JST (Asia/Tokyo, +09:00) timestamp of latest agent checkpoint
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
                 │                                        ↑
                 └─ (plan-first) → human_response_required ┘  (Turn-N with execution plan, approved via input:: done)
                 └─ (--no-plan)  → in_progress directly
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

## Plan-First Flow (default for initial `$desk run` on `plan_ready` tasks)

Lightweight plan approval gate. A planner sub-agent reads the worktree and bd issue, then writes a 3-5 line execution plan into a Dialogue Turn for human approval. Use Phase 1 instead for large tasks requiring deep requirement clarification.

### Trigger

`$desk run <task>` when `status == plan_ready` and `--no-plan` is **not** set.

### Steps

1. **Pre-spawn**: set `runtime_status: running`, `runtime_subagent_role: planner`, `runtime_subagent_id`, `runtime_heartbeat_at`. Create lock file.
2. **Spawn planner sub-agent** (background, cwd = working tree). The planner:
   a. Read bd issue description, task note frontmatter, and relevant code in the worktree.
   b. Write a Turn-N to the Dialogue section with a 3-5 line execution plan as a numbered list.
   c. Set `input:: pending` on the Turn and include an always-present `agent_instruction::` field. The plan Turn format:
   ```markdown
   ### Turn-N
   input:: pending
   agent_instruction::

   **Execution Plan**:
   1. <step>
   2. <step>
   3. <step>

   > Approve, modify, or reject. If you have an extra instruction for the next agent session, write it in `agent_instruction::` before changing `input:: pending` to `input:: done`.
   ```
   d. **bd sync** (Turn-N ↔ bd Sync Invariant): `bd note <bd_issue_id> "[Turn-N] <plan summary>"` + `bd dolt commit`.
   e. Update frontmatter: `status: human_response_required`, update `current_status_summary` with plan gist.
   f. Set `runtime_status: waiting_human`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`.
   g. Delete lock file. Fire `terminal-notifier`. Terminate.
3. **On approval** (`input:: done` detected via signal mechanism): next `$desk run` reads the approved Turn, spawns executor with the plan in the cold resume context.

### `--no-plan` bypass

When `$desk run <task> --no-plan` is invoked on a `plan_ready` task:
- Skip planner spawn. Transition `status` directly to `in_progress`.
- Spawn executor immediately. The executor derives its work from bd issue description and task note context.

## Phase 1: Planning (deep — for large tasks)

Spawn a sub-agent with the working tree as cwd to refine the plan via extended Q&A. Before spawn, set `runtime_status: running`, `runtime_subagent_role: planner`, `runtime_subagent_id`, and `runtime_heartbeat_at`. Use this instead of Plan-First when the task requires multi-round requirement clarification ($grill-me).

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
  loop:
    → $tk (reasonable incision)
    → $review (approval gate)
    → $commit
    → checkpoint
    → if human input needed: exit loop
    → if more work remains and context budget allows: continue loop
    → else: exit loop
  write Exit Turn (MANDATORY — see Exit Turn Contract)
  terminate
```

### Turn-N ↔ bd Sync Invariant

**Every Turn-N write to the task note MUST be paired with a `bd note` append to the corresponding bd issue.** This is a hard invariant — no Turn-N may exist in the Dialogue section without a matching bd note entry. The sync is the agent's responsibility at the point of Turn write, not deferred to a later phase.

**When**: Immediately after writing/appending any Turn-N content to the task note (plan Turn, exit Turn, intermediate Turn, critique summary, etc.).

**What to sync**: A compact summary of the Turn content, prefixed with the Turn identifier. Format:
```
[Turn-N] <one-line summary of what the Turn contains>
<optional 2-3 bullet points for key decisions/findings>
```

**How**:
```bash
BEADS_DIR=<beads_dir> bd note <bd_issue_id> --stdin <<'EOF'
[Turn-N] <summary>
EOF
BEADS_DIR=<beads_dir> bd dolt commit
```

**Applies to all agents**: planner, executor, reviewer, finisher — any role that writes a Turn.

**Background execution OK**: The bd sync may run in background (`run_in_background: true` for Agent, or `&` in bash) since it is append-only and does not block subsequent task note operations. But it MUST be initiated before the agent terminates.

### Checkpoint Contract

After each successful `/commit`:
- Append to bd issue: `bd note <issue-id> "<commit-hash>: <change summary>"`.
- Persist: `bd dolt commit`.

On each status transition:
- Update task note frontmatter `status` and `current_status_summary`.
- Update runtime lease fields if ownership or wait-state changed.
- Update `milestone_status::` in the Milestones table.

### Exit Turn Contract

Every executor session MUST append a Turn-N to the Dialogue section before terminating. **No silent exits.** This Turn is the human-visible record and the cold resume anchor for the next session.

Two exit patterns:

#### Pattern A: Blocking exit (human judgment needed)

Use when the next step requires human decision, verification, or approval (including CI verification, merge approval, design review).

```markdown
### Turn-N
input:: pending
agent_instruction::

**Context**: <what was done and why this decision is needed>
**Question**: <specific question requiring judgment>
**Options**: <enumerate choices if applicable>

> Write your response here. If you want the next agent session to follow an extra instruction, write it in `agent_instruction::`. Change `input:: pending` to `input:: done` when finished.
```

1. **bd sync** (Turn-N ↔ bd Sync Invariant): `bd note <bd_issue_id> "[Turn-N] <context summary>"` + `bd dolt commit`.
2. Transition to `status: human_response_required`. Update frontmatter `current_status_summary`.
3. Set `runtime_status: waiting_human`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`.
4. Delete `.desk/runtime/<task-name>.lock`.
5. Fire `terminal-notifier` with obsidian:// URL.
6. **Terminate**.

Resume happens via cold resume (see Signal Mechanism + Stop Hook Auto-Resume below).

#### Pattern B: Non-blocking exit (autonomous continuation)

Use when the session exhausts its context budget but remaining work is clearly defined and needs no human judgment. The next `$desk run` picks up from this Turn.

```markdown
### Turn-N
input:: done
agent_instruction::

**Completed**: <summary of commits and changes>
**Next**: <what the next session should do>
```

1. **bd sync** (Turn-N ↔ bd Sync Invariant): `bd note <bd_issue_id> "[Turn-N] <completed summary + next>"` + `bd dolt commit`.
2. Keep `status: in_progress`. Update frontmatter `current_status_summary`.
3. Set `runtime_status: idle`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`.
4. Delete `.desk/runtime/<task-name>.lock`.
5. **Terminate**.

**When in doubt, use Pattern A.** Human verification of external events (CI, deploy, review) is always Pattern A.

### Sub-issue Discovery

When a derived sub-issue surfaces during execution:
- Create via `bd create "<title>" --parent <epic-id>`.
- Create a dedicated branch task note for the sub-issue.
- Add a row to the Milestones table.
- Address the sub-issue, logging context in its bd issue.

### Derived Notes

When execution produces a substantial artifact (design doc, investigation report, decision record):

1. Create a new note in the vault root with a descriptive name.
2. **Tag inheritance**: Copy all `#prj-*` tags from the parent task note's first line into the derived note's first line. This ensures vault-wide project filtering remains consistent.
3. Link it from the task note using Obsidian wikilink syntax only (for example `[[Derived Note]]`) in the relevant Turn-N. Do not use markdown file links for derived-note references.
4. If `bd_issue_id` is set, reference it in the bd issue notes.

### Turn-N Artifact Callouts

When a Turn produces a linkable artifact, append a dedicated callout block **inside the Turn-N** (after the Agent narrative, before the next Turn heading). This makes artifacts scannable on cold resume.

**Derived note** — learning note, investigation report, design doc:
```markdown
> [!note] 派生ノート
> [[📝Derived Note Name]]
```

**PR** — pull request created or updated:
```markdown
> [!abstract] PR
> [#123 PR title](https://github.com/org/repo/pull/123)
```

**Branch task note** — sub-issue or delegated investigation:
```markdown
> [!info] Branch
> [[🔧Branch Task Note Name]]
```

Rules:
- One callout per artifact. A single Turn may contain multiple callouts.
- Place callouts at the **end** of the Agent section, after the narrative text.
- Use the exact callout type (`note` / `abstract` / `info`) for consistency across desk and desk-live.

## Phase 3: Completion

1. After all milestones are complete, append a final human-check `Turn-N` to the Dialogue section. This Turn MUST use `input:: pending` — the Status-Turn Consistency Invariant (see Guardrails) prohibits `done` while any Turn awaits input.
2. Transition to `status: in_review`. Set `runtime_status: waiting_human`, clear `runtime_subagent_id`, refresh `runtime_heartbeat_at`, and fire notification.
3. **Pre-done validation** (on human approval): Before transitioning to `done`, verify that the latest Turn-N has `input:: done` and does NOT contain an unresolved **Question**. If the human's response requests additional work, transition back to `in_progress` (not `done`).
4. On human approval (latest Turn confirmed resolved):
   - impl tasks: Create PR via `$join` if needed. Update frontmatter `pull_request_url`.
   - Close the bd epic issue.
5. Transition to `status: done`, set `runtime_status: done`, clear `runtime_subagent_id`, and refresh `runtime_heartbeat_at`.

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
   - `plan_ready` + `--no-plan` → executor (skip plan-first, transition directly to `in_progress`)
   - `plan_ready` (no flag) → planner (plan-first flow: write execution plan Turn, await approval)
   - `planning` → planner (Phase 1 deep planning)
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
- Latest Dialogue Turn (most recent `Turn-N` section, including `agent_instruction::` when present)
- If the latest Turn contains an approved execution plan (from plan-first flow), include the instruction: "Follow the approved execution plan in Turn-N"
- If the latest Turn contains a non-empty `agent_instruction::`, include the instruction: "Also follow `agent_instruction::` from Turn-N unless it conflicts with explicit task scope."
- `bd show <bd_issue_id>` output
- Any `[root]`-prefixed bd notes from the current session (human decisions/clarifications made in root dialogue)
- Working tree path and branch
- Instruction to follow Turn-N protocol with mandatory `input:: pending` inline field and always-present `agent_instruction::`

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

Claude Code / Codex `hooks.Stop` fires when the root session goes idle. `scripts/desk_stop_hook.sh` runs and:

1. Checks `.desk/signals/*.ready` — if found (FIFO, oldest first), returns `{"decision":"block","reason":"$desk run <task>"}`.
2. Checks `.desk/runtime/*.lock` for dead PIDs (`kill -0`) — if found, returns `{"decision":"block","reason":"$desk run <task> --force"}`.
3. Checks heartbeat staleness (>15 min with `runtime_status: running`) — fires `terminal-notifier` (does NOT block).
4. If nothing found, returns `{"decision":"approve"}`.

Execution time must be <1 second (no fswatch wait). Install via `<vault-root>/.claude/settings.json` or `<vault-root>/.codex/hooks.json`:

```json
{
  "hooks": {
    "Stop": [{"hooks": [{"type": "command", "command": "bash <skill-dir>/scripts/desk_stop_hook.sh <vault-root>", "timeout": 10}]}]
  }
}
```

Codex requires `[features] codex_hooks = true` in `~/.codex/config.toml`.

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
NOW=$(date '+%Y-%m-%d %H:%M:%S')
ENCODED_FILEPATH=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<task-note-name>")
ENCODED_HEADING=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "Turn-N")
terminal-notifier \
  -title "desk: <task-name>" \
  -message "[${NOW}] Turn-N: <status summary>" \
  -open "obsidian://adv-uri?vault=${VAULT_NAME}&filepath=${ENCODED_FILEPATH}&heading=${ENCODED_HEADING}"
```

- `-message` must include a `[yyyy-MM-dd HH:MM:SS]` timestamp and the target `Turn-N`.
- `-open` uses `obsidian://adv-uri` (Advanced URI plugin) with `heading=Turn-N` to jump directly to the target Turn section. The heading value must omit the `#` prefix (e.g., `Turn-3` not `# Turn-3`).
- **All query parameter values must be percent-encoded** via `urllib.parse.quote(value, safe='')`. Task names containing Japanese, spaces, or parentheses will break `NSURL` parsing if left raw.
- Requires the [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) plugin. The native `obsidian://open` does not support heading navigation.

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
| Plan-First | (built-in) | lightweight execution plan + approval gate |
| Planning (deep) | `$grill-me` (async adapted) | requirement clarification via Q&A |
| Execution | `$tk` | minimal-diff incision |
| Execution | `$review` | approval gate |
| Execution | `$commit` | micro-commit |
| Completion | `$join` | PR creation |
| All phases | `$beads` | bd issue CRUD & sync |

## Guardrails

- **Status-Turn Consistency Invariant**: If the latest Turn-N contains a **Question** (regardless of `input::` value), `status` MUST NOT be `done`. Allowed statuses when a Turn has an unresolved Question: `human_response_required` (during execution) or `in_review` (Phase 3 final check). The `done` transition requires: (a) the latest Turn has `input:: done`, AND (b) the human's response does not request additional work. If the response requests further action, transition to `in_progress` instead.
- **No silent executor exit**: Every executor session MUST write an Exit Turn before terminating (see Exit Turn Contract). An executor that commits work but terminates without a Turn violates this rule — the task note becomes an incomplete record and the cold resume chain breaks.
- **Off-topic exchange exception**: If a human message concerns session mechanics, protocol semantics, skill invocation, or other meta-concerns unrelated to the task's subject matter, do NOT write a Turn-N or fire a bd sync for that exchange. Turn-N exists to record task-substantive progress; logging protocol Q&A or tooling tangents pollutes the cold-resume record. This applies to both desk-live interactive turns and desk async dialogue. Note: errors, blockers, or unexpected failures encountered during task execution are task-substantive events — always record these in Turn-N and bd sync even if the triggering conversation was meta in nature.
- **Stateless workers**: Each agent session terminates after its work unit. No agent waits or polls.
- **Turn-N `input:: pending` is mandatory**: Signal detection depends on this inline field. Omitting it breaks the resume chain.
- **Turn-N `agent_instruction::` is always present**: Keep the field even when blank so humans can add note-side follow-up instructions without changing the template shape.
- All human dialogue is async via task note Turn-N. No synchronous interrupts.
- **Turn-N ↔ bd Sync Invariant**: Every Turn-N write MUST be paired with a `bd note` append. No Turn may exist without a matching bd note. This applies to all agent roles (planner, executor, reviewer, finisher). Background execution is acceptable but initiation before agent termination is mandatory. See the Turn-N ↔ bd Sync Invariant section for details. **⚠ MOST COMMONLY VIOLATED INVARIANT**: In practice, agents write Turn-N but forget the bd sync. Treat the pair as one atomic operation — never yield or terminate after a Turn-N write without verifying the bd sync was initiated.
- **Root Session bd Sync Invariant**: When the root desk session (the session that runs `$desk run` or `$desk`) receives task-relevant context from the human — design decisions, clarifications, approval rationale, external review results — it MUST sync a summary to the bd issue via `bd note <bd_issue_id> "[root] <summary>"` + `bd dolt commit` **before** spawning a sub-agent or ending the session. This ensures executor cold resume context includes human decisions that occurred outside Turn-N dialogue.
- **Question presentation format**: When presenting questions to the user during dialogue (Turn-N questions, planning Q&A, grill-me sessions), use Obsidian callout blocks (`> [!question]`) with bullet-point formatting. Do not compress questions into single lines; each question ID and its content must be on separate bullet lines within the callout for scannability.
- Dual writes to task notes and bd issues are by design (human-facing view vs agent-recoverable log).
- bd issue body/notes must be self-contained enough for cold resume after session death.
- Concurrent agent assignment to all in_progress tasks is permitted. Accept write-contention risk on shared BEADS_DIR.
- Prefer milestone-progress wording in `current_status_summary`; runtime mechanics belong in the runtime lease fields.
- Root epic closure always requires a human check gate.
- Lock files in `.desk/runtime/` are the external truth for agent liveness. Frontmatter `runtime_status` is self-reported.
