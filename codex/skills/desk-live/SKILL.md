---
name: desk-live
description: >
  Synchronous interactive mode for desk task notes. Root session holds the task and dialogues with the user in real-time, appending each round-trip as a Turn-N to the task note and bd issue.
  Use when user says "$desk-live", "desk-live", "$desk-live --flush", "interactive mode for task", or wants rapid synchronous dialogue on a desk-managed task note (planning Q&A, adhoc discussion) instead of the default async sub-agent cycle.
---

# Desk Live

## Overview

Synchronous interactive session on a desk-managed task note. The root session holds the task directly (no sub-agent spawn) and dialogues with the user in real-time. Each round-trip is appended as a Turn-N to the task note and bd issue, maintaining full compatibility with desk's async cold resume.

Prerequisite: the target task note must already exist (created via `$desk new` or manually). desk-live does NOT create new tasks.

## Invocation

| pattern | behavior |
|---------|----------|
| `` $desk-live `<task-note-name>` `` | Start interactive session on the specified task. Note name follows the same backtick-quoting convention as `$desk run`. |
| `$desk-live` | No argument: scan for active task notes (status != done/not_started), present candidates, and let the user select. Prioritize tasks with `runtime_status: waiting_human` or recent `runtime_heartbeat_at`. |
| `$desk-live --flush` | Catch-up sync within an active desk-live session: scan conversation history since the last Turn-N for unlogged discussion context (design decisions, findings, actions), write a comprehensive Turn-N summarizing all unlogged content, and fire a `bd comment` in the background. Use when Turn-N updates have been deferred across multiple rounds or when the user explicitly requests a log flush. The flush Turn should capture all substantive exchanges — not just the latest one. |

## Session Lifecycle

### 1. Open

1. Read task note frontmatter + latest Dialogue Turn.
2. If `bd_issue_id` is set, run `bd show <bd_issue_id>` for context.
3. If `git_working_tree` is set, cd to it.
4. Guard: if `.desk/runtime/<task>.lock` exists and PID alive → report conflict, abort.
5. Create `.desk/runtime/<task>.lock` with `role=interactive`.
6. Update frontmatter:
   - `runtime_status: running`
   - `runtime_subagent_id: ""` (root session, no sub-agent)
   - `runtime_subagent_role: interactive`
   - `runtime_heartbeat_at: <now JST>`
   - Keep `status` unchanged (do not transition on open).
7. Present current state summary to user and begin dialogue.

### 2. Loop (each round-trip)

For each user message:

1. Process the user's input (research, answer, discuss, execute — whatever the task requires).
2. **GATE — Append Turn-N before yielding to user.** This is a hard requirement, not optional. Write Turn-N to the task note Dialogue section **in the same assistant response** that answers the user — never defer to "later" or "batch".

   **Off-topic exception**: If the user's message is about session mechanics, protocol semantics, skill invocation, or other meta-concerns unrelated to the task's subject matter, do NOT write a Turn-N or fire a bd comment. Respond directly and continue. Turn-N exists to record task-substantive progress; logging protocol Q&A or tooling tangents pollutes the cold-resume record. Note: errors, blockers, or unexpected failures encountered during task execution are task-substantive events — always record these in Turn-N and bd comment even if the triggering conversation was meta in nature.
   ```markdown
   ### Turn-N
   input:: done
   agent_instruction::

   **User**: <user's message summary — 1-2 lines>
   **Agent**:
   <agent's substantive output — see Turn-N content rules below>
   ```
   - If a delegated skill ($grill-me, $gen-beads, etc.) produces the response, Turn-N append is still the **caller's** responsibility. The skill does not write Turns.
   - If the response spans multiple tool calls, append Turn-N after the **last** tool call and before the final text output.

   **Turn-N content rules (task note):**
   The Agent section must capture essentially all substantive output the agent produced in this turn — not just conclusions. Include:
   - Reactions and interpretations of the user's input
   - Investigation results, findings, data points discovered
   - Options considered, comparisons, trade-off analysis
   - Decisions made and their rationale
   - Actions taken (commands run, files edited, beads created, etc.)
   - Artifacts produced (snapshots, plans, code diffs, etc.)
   - Prefer task-critical substance over orchestration chatter. Omit repeated signal, lock, retry, or housekeeping details unless they change task state, block progress, or justify a decision.

   **Skill-specific rules:**
   - **$grill-me / interactive Q&A**: Log every question asked and every answer received **without omission**. Each Q&A pair must be recorded verbatim (question text + selected option or free-form answer). Do not summarize multiple questions into a single line.
   - **Question presentation format**: When presenting questions to the user during interactive dialogue, use Obsidian callout blocks with bullet-point formatting for scannability. Do not compress questions into single lines. Example:
     ````markdown
     > [!question]
     > - **Q-1**: <question content>
     > - **Q-2**: <question content>
     > - **Q-3**: <question content>
     ````
     Each question ID and its content must be on separate bullet lines within the callout.

   Omit only: tool-call boilerplate, retry noise, permission prompts, and formatting scaffolding. When in doubt, include it.

3. **GATE — bd comment (background).** If `bd_issue_id` is set, fire `bd comment` **in the same response as the Turn-N write**, using `run_in_background: true` on the Bash tool so it never blocks the user. This is a hard gate paired with Turn-N: if you wrote a Turn-N, you must also fire the bd comment. Do not defer, batch, or skip.

   > **⚠ MOST COMMONLY VIOLATED GATE**: In practice, Turn-N is written but the bd comment is forgotten. This is the #1 protocol violation observed across sessions. Treat the bd comment as an inseparable part of the Turn-N write — they are one atomic operation, not two independent steps. If you catch yourself about to yield to the user after writing a Turn-N, STOP and verify you fired the bd comment first.
   ```bash
   # run_in_background: true
   BEADS_DIR=<bd_beads_dir> bd comment <bd_issue_id> "Turn-N: <structured summary — findings, decisions, actions, artifacts — compact but reproducible>"
   ```
   Content rules: concise but substantively complete — preserve key data points, decision rationale, created/modified identifiers (bead IDs, file paths, commit SHAs), and state transitions. Omit verbose prose.
4. Update frontmatter `runtime_heartbeat_at` every ~5 Turns (not every Turn — avoid noise).
5. If a meaningful status transition occurs (e.g., planning completes → `in_progress`), update `status` and `current_status_summary` immediately.
6. Continue to next user input.

### 3. Close

Triggered by: user says "done" / "end" / "close" / "exit" / explicit close instruction, OR user switches to another task/topic.

1. Write a final Turn-N summarizing the session:
   ```markdown
   ### Turn-N
   input:: done
   agent_instruction::

   **Session Summary**: <what was discussed/decided/produced>
   **Next**: <what remains, if anything>
   ```
2. Update frontmatter:
   - `current_status_summary`: reflect session outcomes
   - `runtime_status: idle` (or `waiting_human` if a question was left open)
   - `runtime_subagent_id: ""`
   - `runtime_subagent_role: ""`
   - `runtime_heartbeat_at: <now JST>`
3. If `bd_issue_id` is set, append session summary to bd issue and `bd dolt commit`.
4. Delete `.desk/runtime/<task>.lock`.

## Turn-N Format

Interactive Turns use the same heading scheme (`### Turn-N`) as async desk. Key differences:

- `input:: done` is set immediately (no `pending` → signal → `done` cycle needed).
- `agent_instruction::` is always present but typically empty (user gives instructions verbally in real-time).
- Content is a **User/Agent** pair rather than the async pattern of Context/Question/blockquote-response.

This format is intentional: async desk's cold resume reads the latest Turn-N regardless of format, so interactive Turns are fully compatible.

## Derived Notes

If discussion produces a substantial artifact (design doc, investigation report, decision record):

1. Create a new note in the vault root with a descriptive name.
2. **Tag inheritance**: Copy all `#prj-*` tags from the parent task note's first line into the derived note's first line. This ensures vault-wide project filtering remains consistent.
3. Link it from the task note (inline link in the relevant Turn-N).
4. If `bd_issue_id` is set, reference it in the bd issue notes.

### Turn-N Artifact Callouts

When a Turn produces a linkable artifact, append a dedicated callout block **inside the Turn-N** (after the Agent narrative, before the next Turn heading). This makes artifacts scannable on cold resume.

**Derived note** — learning note, investigation report, design doc:
```markdown
> [!note] Derived Note
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

## Guardrails

- **No sub-agent spawn**: desk-live runs entirely in the root session.
- **No signal mechanism**: interactive mode does not use `.desk/signals/` — dialogue is synchronous.
- **Compatible Turns**: Turn-N format must remain readable by desk's async cold resume.
- **Turn-N is a hard gate**: every *task-substantive* user turn MUST produce exactly one Turn-N append before the assistant yields. Skipping or batching multiple turns into one retroactive write is a protocol violation. Off-topic exchanges (protocol Q&A, session mechanics, skill meta-discussion) are exempt — see Loop §2 off-topic exception.
- **Lock discipline**: always create lock on open, delete on close. If the session crashes, desk's Stop Hook will detect the stale lock.
- **Skill delegation**: desk-live may invoke any skill that desk executors use (`$tk`, `$commit`, `$beads`, etc.) directly in the root session. The **caller** (desk-live loop) owns Turn-N writes — delegated skills never write Turns.
