---
name: herdr-critique-loop
description: >-
  Converge a plan or other non-code artifact to "no HIGH findings" by driving
  multiple critique-agent panes in Herdr. The architect (you, root) drafts/holds
  the plan, spawns one critique pane per review lane (derived via the critique
  skill), prompts them to review the plan in parallel, aggregates their findings
  back to the architect pane, revises the plan, and re-reviews — looping
  autonomously until no HIGH findings remain or a cycle cap fires. Composes the
  base `herdr` and `critique` skills; the plan/artifact counterpart to
  `herdr-review-loop` (which converges a code diff). Use when asked to run a
  Herdr multi-pane critique loop, review a rough plan with several critique
  agents, aggregate critique-pane feedback and revise, or converge plan findings
  to zero HIGH. Trigger on herdr critique loop, critique panes, plan critique
  loop, plan review pane, critique convergence in herdr, loop plan critique
  until no HIGH findings remain. Requires HERDR_ENV=1.
---

# herdr-critique-loop

Converge a **plan / non-code artifact** (rough plan, snapshot, design doc, ADR)
to "no HIGH findings" by driving several critique agents that live in sibling
Herdr panes. The **architect** (you, root) owns the plan and the loop: it derives
review lanes, runs one critique pane per lane, aggregates and verifies their
findings, revises the plan itself, then re-reviews — repeating until HIGH
findings reach zero, a cycle cap fires, or a finding is held for a human.

This is the develop-phase (plan) counterpart to `herdr-review-loop`, which
converges a **code diff** via one reviewer pane. Here the target is a plan and
there are **multiple** critique panes (one per lane).

## Relationship to other skills

- Composes the base `herdr` skill — follow its CLI contract for every pane and
  agent command (`herdr --help`, then the relevant group). This skill only adds
  the multi-pane critique-loop orchestration on top.
- Composes `critique` — reuse its lane-derivation rules, its review-only lane
  prompt (including the EVIDENCE MANDATE), and its aggregation/severity schema.
  This skill moves that fan-out from ephemeral sub-agents into persistent Herdr
  panes and adds an autonomous revise → re-review convergence loop.
- Sibling of `herdr-review-loop` (code diff, one reviewer pane). Pick this skill
  when the review target is a **plan/artifact**, not a code change.
- The **non-Herdr fallback is the in-session `critique` skill** (parallel
  sub-agents). The caller (e.g. `rough-plan`) selects this skill only when
  `HERDR_ENV=1`, and `critique` otherwise.

## Preconditions

- `test "${HERDR_ENV:-}" = 1`. If it fails, say you are not in Herdr and stop;
  tell the caller to use `$critique` (in-session) instead.
- A drafted artifact exists to review (a rough plan Turn, a task-note Plan /
  Snapshot section, or a design doc). If none exists, stop — there is nothing to
  critique yet (run `$rough-plan` / `$grill-me` first).

## Inputs (parameterize; ask only if genuinely ambiguous)

- `artifact` — what to review. Default: the current rough plan (task-note Plan
  section or the latest plan Turn-N). May be a file path or inline text.
- `lanes` — the review lanes. Default: derive 2-4 lanes from the artifact via
  the `critique` lane-derivation rules (one expert perspective per major domain).
  Present the lanes before spawning panes.
- `kind` — critique agent kind. Default `codex`; any Herdr kind is allowed. May
  mix kinds across lanes if useful.
- `cycle_cap` — max review cycles before escalating. Default `3`.
- `severity_bar` — the severity that drives the loop. Default `HIGH`.

## Execution model

- **One pane per lane, reused across cycles.** Split once per lane, start one
  critique agent per pane, keep reusing them. Do not spawn fresh panes per cycle.
- **Architect owns the loop AND the plan edits.** Unlike `herdr-review-loop`
  (code fixes go to a fix subagent), plan revisions are lightweight and the root
  architect already owns the plan — so the architect revises the plan directly
  between cycles. Keep the critique panes review-only.
- **Never wait indefinitely inline.** Prompt-with-wait may exceed a foreground
  timeout; run waits via a background runner and resume on completion. Fan the
  per-lane prompts out concurrently, then collect.

## Setup (once)

1. Learn the current CLI: `herdr --help`, then `herdr pane` and `herdr agent`.
2. Derive lanes from the artifact (critique rules: 2-4 lanes, one per domain).
   Present them to the user, e.g.:
   ```
   Critique lanes:
   1. terraform-infra — AWS resource/provider/state design
   2. cross-account   — RAM share, auth policy, apply ordering
   3. tooling         — Makefile/runner/cred flow correctness
   Spawning one critique pane per lane...
   ```
3. Inspect the caller pane and split one sibling pane per lane, preserving cwd
   and focus:
   - `herdr pane layout --pane "$HERDR_PANE_ID"`
   - For each lane: `herdr pane split --current --direction right --cwd "<cwd>" --no-focus`
     and read the new pane id from `.result.pane.pane_id`.
4. Start one critique agent per pane with a unique lane-scoped name, and set the
   pane label to the SAME name (name + label at creation — an unnamed pane is
   hard to target later):
   - `herdr agent start critique-<lane> --kind <kind> --pane <pane-id> --timeout 60000`
   - `herdr pane rename <pane-id> critique-<lane>`
   - Verify with `herdr pane get <pane-id>` (label) and `herdr agent list`.

## The loop

Track `cycle = 0`, `held = []`. Repeat:

1. **Review (fan out).** Prompt every critique pane, in parallel, to review the
   current `artifact` from its lane as a **review-only** pass (no edits). Use the
   `critique` lane prompt verbatim, including the EVIDENCE MANDATE. Require each
   finding as: severity (HIGH/MED/LOW) + `subject` + issue + recommendation +
   evidence; plus a final verdict line stating whether HIGH findings are zero.
   On a re-review, tell each pane what changed in the plan and which prior HIGH
   findings were addressed.
   - Submit via `herdr agent prompt critique-<lane> "<prompt>" --wait --timeout <ms>`
     through a background runner per pane. Increment `cycle` once per round.
2. **Capture findings** from each pane (see Output capture). Do not proceed until
   every pane's full review text is in hand (retry/escalate a stalled pane).
3. **Aggregate + verify.** Apply `critique` aggregation: normalize, dedup
   materially-identical findings across lanes (keep highest severity), and run
   the **evidence gate** (demote uncited tool-behavior claims to LOW/UNVERIFIED).
   Verify each surviving HIGH against the artifact's intent and sources before
   acting — a critique pane can be wrong. Route each finding:
   - **Fix** — clear, in-scope, source-confirmed: fold into the plan revision.
   - **Won't-fix** — false positive / out of scope / accepted trade-off: record
     the reason; it does not block convergence.
   - **Hold** — needs a genuine design decision or a scope change: append to
     `held`. Do not silently resolve. This is the human gate.
4. **Revise the plan (architect).** Apply the Fix findings to the plan directly,
   keeping each revision scoped to the finding it addresses; do not fold in
   unrelated scope. Record what changed so the next round's panes can confirm
   resolution.
5. **Decide.** If verified HIGH findings == 0 → **converged**, stop and report
   the final plan + the MED/LOW findings left for the human. Else if
   `cycle >= cycle_cap` or `held` is non-empty → stop and escalate. Else go to 1
   and re-review the revised plan.

## Output capture (codex/TUI panes)

Critique agents often run on the terminal alternate screen, so pane reads can
truncate.

1. First try `herdr agent read critique-<lane> --source recent-unwrapped --lines 200`.
2. If clearly truncated (a larger `--lines` reveals no more), ask that pane to
   write its complete findings as Markdown to a temp path and reply with only the
   path, then read the file. Use this only as a fallback.

## Severity and convergence

- The loop converges on `severity_bar` (default HIGH) reaching zero.
- MED/LOW findings are reported to the human but do not drive the loop; fold them
  into the plan only if trivially correct and in scope.
- A HIGH finding that needs a genuine design decision or scope change is
  **held**, never silently resolved — surface it for the human.

## Stop conditions

Report and stop on any of:

- **Converged**: verified HIGH findings == 0. Return the final revised plan.
- **Cycle cap**: `cycle_cap` reached without convergence. Escalate.
- **Held**: a finding entered `held`. Escalate with each held item and the exact
  human decision needed.
- **Pane stall/timeout**: a critique pane never settles. Escalate with state from
  `herdr agent get` / `herdr agent read`.

On escalation, summarize cycles used, findings folded / won't-fixed / held (with
subject), the current plan state, and what the human must decide.

## Guardrails

- Follow the base `herdr` skill for all pane/agent commands; parse ids from JSON,
  never guess them. Use `--no-focus` so the user keeps their pane.
- Reuse the per-lane panes across cycles. At the end leave them idle for a
  possible manual re-review; do not auto-close a pane you created unless asked.
- Critique panes are review-only: they must not edit files or write the plan.
  All plan edits go through the architect (root).
- Verify every HIGH finding against the artifact and its sources before folding
  it in; keep each revision scoped to the finding it addresses.
- Never leak issue-tracker IDs (bd, etc.) into any pane-visible or committed text
  the panes might echo. This loop reviews a plan; it does not commit code.
- Do not close workspaces, tabs, panes, or sessions you did not create.
