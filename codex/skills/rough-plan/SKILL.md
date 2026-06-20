---
name: rough-plan
description: Approval gate that drafts a rough implementation plan before code changes begin. Replaces desk's plan-first flow for impl tasks. Triggered by $desk run on plan_ready impl tasks, or by invoking $rough-plan directly.
---

# Rough Plan

## Overview

Draft a rough plan for "how to build it" and obtain human approval before starting implementation.
Requirements (What/Why) must already be settled. If unclear, run `$grill-me` first.

## Applicability

| task_type | rough-plan | skip condition |
|-----------|-----------|----------------|
| impl | MUST | Trivial changes (single file, a few obvious lines) may be skipped by agent judgment |
| research | skip | -- |
| adhoc | skip | -- |

When skipping for triviality, record the skip and its reason as a one-line note in Turn-N.

## desk Integration

This skill replaces desk's plan-first flow.

- When `$desk run <task>` detects a `plan_ready` impl task, desk invokes rough-plan instead of spawning a planner sub-agent.
- After rough-plan obtains human approval, desk spawns the executor.
- The `--no-plan` flag remains valid (bypasses rough-plan, transitions directly to executor).

## Workflow

```
1. Precondition check
2. (optional) $grill-me gate
3. (optional) $creative-problem-solver
4. Draft rough plan
5. Human approval
6. Handoff to execution
```

### Step 1: Precondition Check

Verify:
- Requirements are clear (What/Why are defined).
- Worktree and bd issue exist (for impl tasks).
- Current state of the target code is understood.

If requirements are ambiguous, proceed to Step 2. If clear, skip to Step 3.

### Step 2: Grill-Me Gate (optional)

Invoke when requirements contain ambiguity.

- Call `$grill-me` to finalize the Snapshot (problem statement + success criteria).
- Once the Snapshot is settled, proceed to Step 3.

Decision criteria:
- Source issue / bd issue describes requirements sufficiently → skip.
- "What" is clear but "why" or constraints are unknown → invoke.
- Human explicitly instructs to skip → skip.

### Step 3: Creative Problem Solver (optional)

Invoke when multiple implementation approaches exist for the How.

- Call `$creative-problem-solver` to present trade-offs across options.
- Once the human selects an approach, proceed to Step 4.

Skip conditions (agent judgment):
- Only one viable approach exists.
- Human has already specified the approach.
- Change is small enough that comparing options adds no value.

### Step 4: Draft Rough Plan

Write the rough plan using this structure:

```markdown
**Rough Plan: <title>**

Approach: <1-2 line summary of the direction>

**Phase N: <phase name>**

<natural-language explanation: outline, key points, rationale>

\```
<pseudocode: concrete operations, file changes, resource definitions, etc.>
\```

**Commit order**
1. <commit 1: what it groups>
2. <commit 2: ...>

> <caveats and verification checkpoints>
```

Rules:
- The natural-language sections present the outline and key points per topic.
- Critical implementation details MUST include pseudocode.
- Pseudocode should be granular enough to convey the concrete shape of the change (TF resource definitions, code structure, file operations, etc.).
- Phase boundaries align with commit boundaries (1 phase = 1 commit by default).
- State verification checkpoints (e.g. "plan diff must be zero") explicitly when applicable.

### Step 5: Human Approval

Write the rough plan into a Turn-N in the task note and request approval.

Turn-N format:
```markdown
### Turn-N
input:: pending
agent_instruction::

<rough plan from Step 4>

> Approve, modify, or reject. If you have extra instructions for the next agent session, write them in `agent_instruction::` before changing `input:: pending` to `input:: done`.
```

bd sync: issue a `bd note` immediately after writing Turn-N (per Turn-N / bd Sync Invariant).

### Step 6: Handoff

When the human sets `input:: done`:
- desk context: transition status to `in_progress` and hand off to executor spawn.
- standalone context: begin implementation following the approved plan.

## Standalone Invocation

When `$rough-plan` is called directly outside desk:
- If a bd issue exists, log the plan there.
- If no task note exists, output the plan directly in the conversation.
- After human approval, proceed to implementation.

## Guardrails

- Do not make code changes before rough plan approval.
- Do not sneak in changes beyond the plan's scope (feedback: bug fix scope must be strictly honored).
- Pseudocode is a plan, not production code. Adjust as needed during implementation.
