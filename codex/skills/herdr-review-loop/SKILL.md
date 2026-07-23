---
name: herdr-review-loop
description: >-
  Drive a local Herdr reviewer-agent pane to review your working changes from
  multiple perspectives, then loop review → fix → re-review until all HIGH
  findings are resolved. Spawn a sibling reviewer pane (codex or any Herdr
  agent kind), have it review the working-tree or branch diff, feed its findings
  back to the orchestrator, delegate source-verified fixes to a fix subagent,
  push, and re-review the new head — repeat until no HIGH findings remain or a
  cycle cap fires. Composes the base `herdr` skill; the local-pane counterpart
  to `review-codex-loop` (which drives the GitHub PR Codex bot via `gh`). Use
  when asked to spin up a reviewer agent in a Herdr pane, review the working
  tree or a diff with a second agent, converge review findings locally, apply
  fixes from that reviewer's feedback, or loop until no HIGH findings remain.
  Trigger on herdr review loop, herdr reviewer pane, pane review loop, reviewer
  agent pane, review in a herdr pane, local review convergence. Requires
  HERDR_ENV=1.
---

# herdr-review-loop

Converge a change to "no HIGH findings" by driving a reviewer agent that lives
in a sibling Herdr pane. The orchestrator (you, root) owns the loop and stays
lean: it runs the reviewer pane, verifies findings against source, delegates the
actual fixes to a fix subagent, then re-reviews — repeating until HIGH findings
reach zero, a cycle cap fires, or a finding is held for a human.

## Relationship to other skills

- Composes the base `herdr` skill — follow its CLI contract for every pane and
  agent command (`herdr --help`, then the relevant group). This skill only adds
  the review-loop orchestration on top.
- Sibling of `review-codex-loop`. That skill converges the **GitHub PR** Codex
  bot (`@codex review` via `gh`, thread resolve, remote). This skill converges a
  **local** reviewer agent in a Herdr pane over the working tree or branch diff,
  with no GitHub dependency. Pick this when the review target is local work (a
  worktree, an uncommitted change, a not-yet-PR branch) or when you want a
  second live agent's eyes from multiple perspectives.

## Preconditions

- `test "${HERDR_ENV:-}" = 1`. If it fails, say you are not in Herdr and stop.
- The orchestrator is on the branch/worktree whose changes are under review, or
  knows the target path.
- A supported reviewer agent kind is installed (see `herdr agent`; default
  `codex`).

## Inputs (parameterize; ask only if genuinely ambiguous)

- `perspectives` — the review angles, passed through to the reviewer verbatim
  (e.g. "does this stay aligned with the latest WAF rules", correctness,
  security, convention). Required; this is what makes the review multi-angle.
- `target` — what to review. Default: the current working-tree / branch diff in
  the reviewer pane's cwd. May be a path, a commit range, or a PR branch.
- `kind` — reviewer agent kind. Default `codex`; any Herdr kind is allowed.
- `cycle_cap` — max review cycles before escalating. Default `5`.
- `severity_bar` — the severity that drives the loop. Default `HIGH` (P1-equiv).

## Execution model

- **One reviewer pane, reused across cycles.** Split once, start one agent, keep
  reusing it. Do not spawn a fresh pane per cycle.
- **Orchestrator owns the loop; fixes go to a fix subagent.** Root runs the
  reviewer, captures and verifies findings, then delegates the actual edits to a
  fix subagent (Agent tool, `fork`) that verifies each finding against source,
  edits, and commits/pushes. Root stays out of the file-editing weeds so its
  context survives many cycles.
- **Never wait indefinitely inline.** `herdr agent prompt --wait` may exceed a
  foreground timeout; run it with a background runner and resume on completion.

## Setup (once)

1. Learn the current CLI: `herdr --help`, then `herdr pane` and `herdr agent`.
2. Inspect the caller pane and split a sibling, preserving cwd and focus:
   - `herdr pane layout --pane "$HERDR_PANE_ID"`
   - `herdr pane split --current --direction right --cwd "<review-cwd>" --no-focus`
   - Read the new pane id from `.result.pane.pane_id`.
3. Start the reviewer in that pane with a unique name:
   - `herdr agent start reviewer --kind <kind> --pane <pane-id> --timeout 60000`
   - `agent start` returns only once Herdr sees the agent ready.

## The loop

Track `cycle = 0`, `held = []`. Repeat:

1. **Review.** Prompt the reviewer to run its review over `target` from every
   `perspective`, as a review-only pass (no edits, no commits — it only lists
   findings). Require each finding as: severity (P1/P2/P3 or HIGH/MED/LOW) +
   `file:line` + one-line problem + concrete fix direction; and a final verdict
   line stating whether HIGH findings are zero. On a re-review, tell it the head
   advanced and which prior findings were addressed by which commit.
   - Submit with `herdr agent prompt reviewer "<prompt>" --wait --timeout <ms>`
     via a background runner. Increment `cycle`.
2. **Capture the findings** from the pane (see Output capture). Do not proceed
   until you have the full review text.
3. **Verify + triage each finding against source.** A reviewer can be wrong;
   confirm each claim against the actual files/config before acting. Route each:
   - **Fix** — clear, in-scope, source-confirmed: collect for the fix subagent.
   - **Won't-fix** — false positive / out of scope / accepted trade-off: record
     the reason; it does not block convergence.
   - **Hold** — needs a destructive change or a real design decision: append to
     `held`. Do not auto-fix. This is the human gate.
4. **Apply fixes via a fix subagent.** If any Fix items exist, spawn one Agent
   (`fork`) that: re-verifies each item against source, makes scoped edits,
   runs the repo's guards, commits (follow repo/global commit conventions;
   no issue-tracker IDs in the message), and pushes. It returns per-item
   applied/partial/not-applied with the commit hash(es) and guard result.
   Independently confirm the new head and guard.
5. **Decide.** If verified HIGH findings == 0 → **converged**, stop and report.
   Else if `cycle >= cycle_cap` or `held` is non-empty → stop and escalate.
   Else go to 1 and re-review the new head.

## Output capture (codex/TUI panes)

Reviewer agents usually run on the terminal alternate screen, so pane reads can
truncate.

1. First try `herdr agent read reviewer --source recent-unwrapped --lines 200`.
2. If the response is clearly truncated (alternate screen — a larger `--lines`
   reveals no more), ask the reviewer to write its complete findings as Markdown
   to a temp path and reply with only that path, then read the file directly.
   Use this only as a fallback; do not request file output in the first prompt.

## Severity and convergence

- The loop converges on `severity_bar` (default HIGH / P1-equiv) reaching zero.
- MED/LOW (P2/P3) findings are reported to the human but do not drive the loop;
  fix them only if trivially correct and in scope.
- A HIGH finding that requires a destructive change or a genuine design decision
  is **held**, never auto-fixed — surface it for the human.

## Stop conditions

Report and stop on any of:

- **Converged**: verified HIGH findings == 0. Success.
- **Cycle cap**: `cycle_cap` reached without convergence. Escalate.
- **Held**: a finding entered `held`. Escalate with each held item and the exact
  human decision needed.
- **Reviewer stall/timeout**: the reviewer never settles. Escalate with state
  from `herdr agent get` / `herdr agent read`.

On escalation, summarize cycles used, findings fixed / won't-fixed / held (with
`file:line`), the current head, and what the human must decide.

## Guardrails

- Follow the base `herdr` skill for all pane/agent commands; parse ids from JSON
  responses, never guess them. Use `--no-focus` so the user keeps their pane.
- Reuse the single reviewer pane across cycles. At the end leave it idle for a
  possible manual re-review; do not auto-close a pane you created unless asked.
- The reviewer is review-only: it must not edit, commit, or push. All writes go
  through the fix subagent.
- Verify every finding against source before fixing; keep each commit scoped to
  the finding it addresses; do not fold in unrelated changes.
- Never merge, mark ready, or approve anything. No issue-tracker IDs (bd, etc.)
  in commit messages or any PR-visible text.
- Do not close workspaces, tabs, panes, or sessions you did not create.
