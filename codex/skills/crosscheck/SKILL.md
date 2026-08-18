---
name: crosscheck
description: >-
  Coordinate investigation work between the main commander agent (the root
  session) and one persistent codex fact-check reviewer living in a sibling
  Herdr pane. The commander investigates and presents conclusions immediately;
  every substantive factual conclusion (mechanism, causal chain, quantitative
  comparison, exoneration verdict) is dispatched per-conclusion to the reviewer
  for independent re-verification against primary data, and corrections come
  back as diffs. Adopt automatically whenever building factual conclusions from
  primary data — incident investigation, postmortem, audit, capacity analysis,
  security review — without an explicit call; also trigger on crosscheck,
  cross-check my conclusions, fact-check reviewer, commander reviewer pair,
  verification workflow, second-agent verification. Fact-checking only: code
  diffs go to herdr-review-loop, plans to herdr-critique-loop, GitHub PR bots
  to review-codex-loop. Requires HERDR_ENV=1; outside Herdr, skip the checks
  and label conclusions as unverified.
---

# crosscheck

Run investigations as a two-agent pair: the **commander** (you, root) owns the
investigation, the tempo, and the user conversation; one persistent **reviewer**
(codex, sibling Herdr pane) independently re-verifies each substantive factual
conclusion against primary data. Conclusions ship to the user immediately;
verification runs behind them; corrections land as diffs.

## Boundary

Fact-checking of factual claims only. Route other review work to its owner:

| Target | Skill |
|---|---|
| Code diff / working tree | `herdr-review-loop` |
| Plan / non-code artifact | `herdr-critique-loop` |
| GitHub PR via `@codex` bot | `review-codex-loop` |
| Factual conclusions from investigation | **this skill** |

Unlike the loop skills, crosscheck has no convergence loop: one verify pass per
conclusion, corrections folded back, done. Compose the base `herdr` skill for
every pane/agent command.

## Preconditions

- `test "${HERDR_ENV:-}" = 1`. If it fails, do not simulate the protocol:
  continue the investigation solo, label every substantive conclusion as
  unverified in user-facing output, and say once that fact-checking is skipped
  because the session is outside Herdr.
- A codex agent kind installed (`herdr agent`).

## Reviewer lifecycle

1. `herdr agent list` — if a live agent named `reviewer` exists, reuse it.
2. Otherwise pick or create a sibling pane (geometry per the `herdr` skill:
   caller stays top, agent panes form the bottom row) and
   `herdr agent start reviewer --kind codex --pane <id>`.
3. On `agent_name_taken` by another workspace, suffix (`reviewer2`) and keep
   using that name for the rest of the session.
4. One reviewer per session. Never spawn a fresh agent per check; the reviewer
   accumulates context across checks and gets faster.
5. The reviewer is serial: dispatch one request at a time; queue the next until
   the current one settles.

## What must be fact-checked

Mandatory — any conclusion that is substantive: a mechanism, a causal ordering,
a quantitative comparison, an exoneration verdict (ruling something out), or
anything bound for an issue record, a report, or a decision. Exempt — trivial
single-value reads (a config value, a monitor state) where the read itself is
the proof.

Cadence is **per-conclusion**: dispatch the check when you present the
conclusion, not batched at the end of the investigation. A wrong intermediate
conclusion left unchecked becomes the foundation of the next query.

## Presentation contract

- Present each conclusion to the user immediately, marked as "verification in
  flight". Do not block the investigation or the conversation on the verdict.
- When verdicts return, report **only the deltas** (needs-correction /
  unverifiable items and what changed) — not a re-summary of what held.
- If the corrected conclusion was already written to a record (issue tracker,
  note, report), append the correction there in the same breath.

## Request protocol

Write each request as a numbered scratchpad file (`factcheck_<N>_<slug>.md`)
containing, in order:

1. **Role framing** — third-party fact-checker; verify the listed claims
   against primary data (or re-derive them); no design review, no improvement
   proposals, read-only, single pass.
2. **Environment** — the read-only tools/wrappers available, auth state, and
   any known tool traps for the data sources involved (storage flags, tag
   quirks, rollup pitfalls) so the reviewer does not burn its budget
   rediscovering them.
3. **Claims, enumerated** — each with the exact observed values and the
   reproduction command that produced them. A claim without a repro command
   forces the reviewer to guess queries; don't send one.
4. **Self-flagged weakness** — name the claim you trust least and ask the
   reviewer to attack it specifically. This is where checks pay off.
5. **Speculation, labeled** — anything you believe but did not measure, marked
   as speculation; ask the reviewer only to confirm the labeling.
6. **Output format** — a table of claim | verdict (Confirmed / Needs
   correction / Unverifiable) | evidence and comments, then an overall
   assessment, then a list of problems found. Ask for numbers, not adjectives.
7. **Constraints** — read-only mandate, no writes to trackers/dashboards, and a
   word budget.

## Dispatch and wait mechanics

Session-tested; each rule below guards against a failure actually hit.

- Dispatch with
  `herdr agent prompt reviewer "<read file X and follow it>" --wait --timeout 590000`,
  run in the background. Checks take 10–15 minutes against real data; never
  wait in the foreground.
- **Wait timeout is not delivery failure.** On timeout, run
  `herdr agent get reviewer`: if `working`, the prompt landed — re-arm
  `herdr agent wait reviewer --timeout 590000` in the background and never
  re-send the prompt (double submission corrupts the reviewer's turn).
- Read results after settle with
  `herdr agent read reviewer --source recent-unwrapped --lines <N>`; oversized
  output lands in a persisted file — read its tail for the final report.
- After a session restart, background waits are gone but the reviewer keeps
  working. Check `agent get` first, then read; do not re-prompt.
- While a check is in flight, keep investigating adjacent questions — but do
  not build further conclusions on top of the exact claim under review.

## Verdict handling

- **Confirmed** — keep the claim; no user-facing noise.
- **Needs correction** — correct the conclusion, report the diff to the user,
  propagate the correction into every record already written.
- **Unverifiable** — either run the follow-up measurement that would decide it
  (when one query away) or demote the claim to an explicit unknown in reports.
  Never leave the original wording standing as if verified.
- The reviewer's Confirmed is machine corroboration, not human sign-off:
  merges, applies, and destructive operations still gate on humans.

## Anti-patterns

- Batching all checks to the end of the investigation.
- Spawning a new reviewer per check, or several reviewers in parallel panes.
- Sending claims without values and repro commands.
- Re-prompting after a wait timeout instead of checking agent state.
- Blocking every user response on verification (kills tempo — that is what the
  "verification in flight" label is for).
- Quietly upgrading Unverifiable to fact because the original number "looked
  right".
