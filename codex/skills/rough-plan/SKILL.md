---
name: rough-plan
description: Approval gate that drafts a rough implementation plan, including the commit plan (one commit per purpose, each with a validation signal), before code changes begin. The planning step of implementation tasks under the Human Review Default in AGENTS.md, or invoke $rough-plan directly.
---

# Rough Plan

## Overview

Draft a rough plan for "how to build it" and obtain human approval before starting implementation.
Requirements (What/Why) must already be settled. If unclear, run `$grill-me` first.

## Applicability

| task | rough-plan | skip condition |
|------|-----------|----------------|
| implementation | MUST | Trivial changes (single file, a few obvious lines) may be skipped by agent judgment |
| research, documents | skip | -- |

When skipping for triviality, record the skip and its reason as a one-line entry in the `bd` issue notes (AGENTS.md, Task State).

## Recording

The plan is a derived note in the vault, `<bd id>--<topic> plan.md`, with `bd_issue_id` in its frontmatter (vault root as in `$pre-review` step 3). It is written at Step 4 and edited in place on each modify round. It is the artifact the human approves, not a task note. On approval the caller records it per AGENTS.md (Task State): the same file in the issue's `design` field, one child issue per phase, and a `bd` note for each settled decision. Without a `bd` issue, the plan stays in the conversation and no note is written.

## Question Channel

Whenever a step needs a human judgment call — Step 2 requirement clarification, Step 3 approach selection, or any mid-draft decision that shapes the plan — ask through the host's native structured-question tool (e.g. `AskUserQuestion`) when the environment exposes one. Prose questions in the response body are the fallback, used only when no such tool is available.

Rules:
- One question per decision; 2-4 concrete options each, recommended option first.
- Each option must state the consequence of choosing it, not just a label.
- Do not log raw Q&A. Hand each settled decision (topic, options, choice, rationale) to the caller to record as a `bd` note; without a `bd` issue, keep it in the plan.
- Step 5 approval is one decision (approve / modify / reject), asked in the Inbox when the work has an Inbox thread and through native ask otherwise, never a note-side gate.

## Workflow

```
1. Precondition check
2. (optional) $grill-me gate
3. (optional) $creative-problem-solver
4. Draft rough plan
4.5 Critique (converge plan; $herdr-critique-loop if HERDR_ENV=1 else $critique)
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

Write the rough plan into the plan note (see Recording), using this structure:

```markdown
**Rough Plan: <title>**

Approach: <1-2 line summary of the direction>

**Big Picture**

\```mermaid
<architecture / structure diagram — components, boundaries, and how they connect (MUST)>
\```

\```mermaid
<sequence diagram — publish/request/event flow across components (REQUIRED when runtime interaction / data flow spans ≥2 components; otherwise omit + note why)>
\```

**Phase N: <phase name>**

<natural-language explanation: outline, key points, rationale>

\```
<pseudocode: concrete operations, file changes, resource definitions, etc.>
\```

**Commit plan**

| ID | Purpose | Content | Validation signal | State |
|----|---------|---------|-------------------|-------|
| Ph1-C1 | <the one purpose> | <what changes> | <the smallest meaningful check> | <planned / 未確定> |

> <caveats and verification checkpoints>
```

Rules:
- The natural-language sections present the outline and key points per topic.
- **Big Picture MUST output items** (non-trivial impl plans; the Applicability trivial-skip rule still applies):
  - **Architecture / structure diagram — MUST.** Every plan opens with a `mermaid` diagram of the whole change: the components involved, their boundaries (accounts / services / modules), and how they connect. This gives the cold reader the shape before the phase-by-phase detail.
  - **Sequence diagram — conditional MUST.** A `mermaid` sequence diagram is REQUIRED when the change involves runtime interaction or data flow across two or more components (cross-service calls, message/event flows, request→response paths). It may be omitted ONLY when no such flow exists (e.g. a pure static-config or local refactor change); when omitted, state the reason in one line.
  - **Diagram notation is `mermaid`** (renders in Obsidian; consistent with `$report`). ASCII / box-art is allowed only as a supplement, never as a replacement for the mermaid diagram.
- **Pseudocode — MUST per phase.** Each phase MUST include a pseudocode block; critical implementation details MUST be expanded, not summarized.
- Pseudocode should be granular enough to convey the concrete shape of the change (TF resource definitions, code structure, file operations, etc.).
- Phase boundaries align with commit boundaries (1 phase = 1 commit by default).
- State verification checkpoints (e.g. "plan diff must be zero") explicitly when applicable.
- **Commit plan — MUST.** The plan ends with one row per commit, and the human approves the rows with the plan (Step 5):
  - 1 commit = 1 purpose, atomic and reversible. Order the rows so every commit stands alone and passes its own validation signal (the `$commit` skill's rule).
  - The ID is `Ph{n}-C{N}`: `n` is the phase (the design plan's step number, or the order of the phases when the plan has no steps) and `N` the commit within it, so an ID never needs context to resolve. Every progress report names the phase first.
  - The validation signal is the smallest meaningful check that can run on the commit alone (for example `terraform fmt -check` and `terraform validate` for Terraform, a compile or syntax check for other languages). Say in the row what the signal cannot cover (a plan, an apply, a real run).
  - Never cut or merge commits by how many new concepts they hold. Commit granularity is a software-engineering concern (atomic, reversible); a concept-heavy commit gets a thicker explanation at review time (`$pre-review`), still as one commit.
  - Write `未確定` for any item you cannot confirm from the plan or the live system. Investigate first (read the plan, inspect read-only) or leave the row open; never fill it by guess. Investigation may change the plan: a row that looked like one change can turn out to be several independent ones. Re-cut only for software reasons, and re-approve the changed rows.

#### Plan Verbosity Guidelines

The natural-language sections MUST be written as full sentences — not terse labels or heading-style phrases. The target reader is someone who has NOT been in any prior conversation: they must be able to cold-read the plan and understand the full picture without additional context.

Each phase's explanation must answer four questions:
- **What** will be done in this phase (specific action, not a category name)
- **Why** this phase is necessary at this point (rationale, dependency, or risk being addressed)
- **Prerequisite / assumed state** entering this phase (what must already be true or known)
- **Expected output / outcome** — what will be known or available after this phase completes

The ordering of phases must be self-evident from the narrative: each phase should naturally lead into the next, so the reader intuitively understands why the sequence is what it is.

**Before (too terse — do not write like this)**:
```
**Phase 1: Dependency audit** — Check which packages need updating.
```

**After (verbose, context-rich — write like this)**:
```
**Phase 1: Audit dependencies for version conflicts** — Before modifying any code, we need to know which installed packages conflict with the target version — because a silent version mismatch causes runtime failures that are hard to trace back to the upgrade. Run the package manager's outdated-check command and cross-reference each result against the new version's compatibility matrix. The output is a pinned list of packages that must be upgraded or excluded before the migration can proceed safely.
```

### Step 4.5: Critique (optional)

After drafting, review the plan before human approval.

Routing:
- If `HERDR_ENV=1`, invoke `$herdr-critique-loop`. It spawns one critique pane per review lane, aggregates findings back to the architect/root pane, revises the plan, and re-reviews — an autonomous loop converging on zero HIGH findings (cycle cap 3).
- Otherwise invoke `$critique` (in-session parallel sub-agent review).

Fold verified HIGH findings into the plan; converge to no-HIGH before Step 5. MED/LOW findings are recorded for the human and are non-blocking.

Trivial changes may skip this step (consistent with the Applicability trivial-skip rule); record the skip reason alongside the plan-skip note.

### Step 5: Human Approval

Present the rough plan, with its commit plan, as the plan note. When the work has an Inbox thread, attach the note there and ask the approval as one `:::question` (approve / modify / reject); otherwise show it in the conversation and ask via native ask. On modify, revise the note and re-ask. The pre-approval draft is not written to `bd`.

On approval, the caller records the plan (see Recording): `bd update <id> --design-file <the plan note>`, one child issue per phase, and a `bd` note for each settled decision. A change to a commit row after approval is re-approved for the changed rows only: edit the note first, then run `--design-file` again.

### Step 6: Handoff

Begin implementation following the approved plan, one commit per row. When the commits are done, the next step is human review (`$pre-review`, AGENTS.md Human Review Default).

## Standalone Invocation

When `$rough-plan` is called directly:
- If a bd issue exists, record the plan there as described in Recording.
- Without a bd issue, output the plan directly in the conversation.
- After human approval, proceed to implementation.

## Guardrails

- Ask plan-shaping questions through native ask mode when available; prose questioning is the fallback (see Question Channel).
- Do not make code changes before rough plan approval.
- Do not sneak in changes beyond the plan's scope (feedback: bug fix scope must be strictly honored).
- Pseudocode is a plan, not production code. Adjust as needed during implementation.
