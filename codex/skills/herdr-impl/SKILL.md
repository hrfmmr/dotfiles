---
name: herdr-impl
description: >-
  Orchestrate a single bd-issue implementation across Herdr panes as the
  architect/orchestrator. Create a bd-issue-prefixed worktree, spawn a `worker`
  agent to implement the issue's handoff plan, collect validation + tfplan
  artifacts, run a third-party review loop in a `reviewer` pane, relay findings
  worker↔reviewer until no HIGH findings remain, then leave a merge-ready branch
  for a human to open and merge the PR. Requires HERDR_ENV=1 and an existing
  canonical bd issue that already contains a handoff plan. Composes the herdr,
  wt, herdr-review-loop, and desk-live skills. Use when asked
  to orchestrate implementation with worker and reviewer panes, delegate a bd
  issue to a Herdr worker and review-loop it to convergence, bridge worker and
  reviewer as an architect, run implement-then-review across panes, or invoke
  /herdr-impl.
---

# herdr-impl

Position this session as the **architect/orchestrator**. You do not implement or
review directly; you broker a `worker` pane (implements) and a `reviewer` pane
(third-party verification), loop until clean, and hand off a merge-ready branch.

## Preconditions (stop if unmet)

1. `test "${HERDR_ENV:-}" = 1`. If not inside Herdr, say so and stop.
2. A **canonical bd issue that already contains a handoff plan** must exist. Do
   NOT auto-create it. If absent, stop and instruct the user to create one first
   (e.g. via a planning skill).
3. A target git repository with a discoverable default branch.

## Invariants (never violate)

- **Orchestrator-only writes.** ONLY this session writes to the bd issue or a
  desk task note. The `worker` and `reviewer` agents MUST NOT write to bd or task
  notes — their delegation prompts explicitly forbid it. Any 申し送り/handoff from
  worker or reviewer is captured by the orchestrator and recorded as a bd issue
  **COMMENT** (never in the description/body).
- **bd-id hygiene.** The bd issue id appears ONLY in the branch/worktree name.
  Never in code, commit messages, or PR body. Forbid it in delegation prompts.
- **human-gates** (orchestrator never performs these): SSO browser auth
  (cloud SSO browser auth), `terraform apply`, and PR merge. A codex approve alone is
  not sufficient for merge.
- **handoff-only PR.** Leave a merge-ready branch; do NOT auto-create the PR. The
  human opens and merges it.

## Composition (invoke, do not reimplement)

- `herdr` — base pane/agent control (split, agent start, prompt, read, wait, rename).
- `wt` — create the bd-issue-prefixed worktree. Always reuse `wt`; never raw `git worktree`.
- `herdr-review-loop` — reviewer pane + branch-diff review loop (Step 5–6).
- `beads` — bd graph writes when the repo uses a bd-backed issue DB.
- `desk-live` — Turn-N logging when a desk task note is active (optional; see Logging).

`mesh` is the in-session sub-agent orchestrator; `herdr-impl` is its Herdr-pane
counterpart. Reference it for the loop pattern; do not reimplement it.

## Arguments

- `bd_issue` (required unless derivable from an active desk task): the canonical issue.
- `worker_kind` (default `claude`), `reviewer_kind` (default `codex`): overridable.
- `slug` (optional): branch slug; else derive from the bd issue title.
- `plan_source` precedence: explicit arg > bd issue description > desk task note.

## Protocol

0. **Preflight.** Verify preconditions. Resolve the bd issue, its handoff plan
   (by `plan_source` precedence), the target repo, and its default branch.
   Detect IaC-repo context to enable specializations (see below).
1. **Worktree.** Use `wt` to create branch/worktree `<bd-id>--<slug>` from
   `origin/<default-branch>` (fetch first) under the repo's `__worktrees__/`.
2. **Worker pane.** `herdr pane split --no-focus` with `--cwd <worktree>`, then
   `herdr agent start worker --kind <worker_kind> --pane <id>`, then
   `herdr pane rename <id> worker`. **Set BOTH the agent name AND the pane label
   to `worker`.**
3. **Delegate implementation.** Build a self-contained prompt from the handoff
   plan (see Delegation prompt rules). Submit it robustly and **await completion
   state-anchored** (see Herdr I/O cautions): confirm the worker reached `working`,
   then wait for a SETTLED state (`herdr agent wait <name>` with NO `--until`;
   `done` counts as completion). Never use `--until idle` — it misses the `done`
   state that unseen background agents settle into and hangs to timeout — and
   never mistake the pre-work idle for completion. On settle, read and verify the
   worker's final report before moving on.
4. **Artifacts + verify.** Have the worker emit artifacts to
   `/tmp/<bd-id>-review-artifacts/`: required = branch diff + validation
   (fmt/validate); add tfplan for IaC changes. SSO browser auth is a human-gate —
   surface it. Then the orchestrator verifies branch/worktree/commit hygiene
   (no bd-id leak, clean scope) and that the plan matches expectation.
5. **Review.** Invoke `/herdr-review-loop` with a `reviewer` pane (kind =
   `reviewer_kind`; set agent name AND pane label to `reviewer`) over the branch
   diff and the artifacts.
6. **Relay loop.** Feed HIGH findings to the worker → worker fixes and commits →
   re-review. **Loop until HIGH findings = 0.** HIGH = correctness / security /
   data-loss impact. MED/LOW are recorded as PR comments (non-blocking). Cap at
   **3 review cycles**, then human-escalate.
7. **PR handoff.** Leave the merge-ready branch. Report the branch and how to
   open the PR. Do not create or merge it.

## Delegation prompt rules (worker and reviewer)

Every delegation prompt MUST:
- Be self-contained (the agent should not need bd access); embed the plan/spec.
- **Forbid**: `git push`, PR creation, and any writes to bd issues or task notes.
- Forbid writing the bd-id into code or commit messages.
- Forbid `terraform apply`; note SSO auth is human-approved.
- Ask the agent to STOP and report on ambiguity/blockers rather than guess.
- Ask for a concrete final report (files changed, validation commands + results,
  commit sha, artifact paths).

## Logging (orchestrator only)

- Write a bd issue COMMENT at each milestone (worktree ready, delegation, worker
  done + verification, each review cycle, HIGH-clear, handoff). Never edit the
  issue description/body for progress.
- Do bd writes via the `beads` skill. durability = local `bd dolt commit`
  (push may be a no-op).
- desk-live Turn-N is OPTIONAL: write Turns only when a desk task note is active.
  Otherwise run standalone with bd-only logging.

## Failure / timeout handling

- On a prompt stall or hang: retry once → respawn the agent → human-escalate.
- Use generous timeouts for generative steps; background long waits.
- On abort, KEEP the worktree (no auto-clean). The human decides cleanup.

## Herdr I/O cautions

- **Name + label at creation (do not skip).** The moment a pane hosts an agent,
  set BOTH the agent name (`herdr agent start <name> ...`) AND the pane label
  (`herdr pane rename <pane> <name>`) to the SAME value (`worker` / `reviewer`).
  The pane label MUST correspond to the agent name. Do it at creation time — an
  unnamed pane shows only "Claude Code" in the UI and is hard to find and target
  later. Verify with `herdr pane get <pane>` (`label`) and `herdr agent list`.
- **Ghost/recap input.** Claude Code's recap can leave ghost text in a pane's
  input that `esc`/`ctrl+u`/`ctrl+c` do NOT clear (the real buffer is empty). A
  fresh paste replaces it.
- **Paste is not always atomic.** Protocol: paste the prompt → read/verify the
  input shows ONLY your text (recap ghost replaced, no stray prior input
  concatenated) → send `Enter` if it did not auto-submit.
- **Completion detection is state-anchored (this bit us — the main fix).**
  `herdr agent wait` WITHOUT `--until` returns on ANY settled state — including
  the agent's *current* idle *before* your task starts — so it falsely reports
  "done" the instant you call it. Never treat a pre-work idle as completion.
  Protocol:
  1. Record `state_change_seq` (via `herdr agent get <name>`) BEFORE submitting.
  2. After `Enter`, confirm the agent actually moved to `working` (status=`working`
     AND `state_change_seq` advanced). If it stays idle with an unchanged seq, the
     submit did not register — re-send `Enter`.
  3. ONLY after `working` is confirmed, await a SETTLED state with
     `herdr agent wait <name>` — **no `--until`** (it settles on idle|done|blocked).
     **Never `--until idle`**: an unseen background agent finishes in `done`, not
     `idle` (idle requires the tab to be *seen* in the UI; CLI reads do not mark it
     seen), so `--until idle` never fires and the wait hangs to its timeout — the
     loop then stalls with no notification. **Treat `done` as completion** (same
     underlying state as idle). If it settles `blocked`, the agent hit an
     approval/question — `read` and respond; do not treat it as done. Background
     long waits and resume on the notification.
  4. **Completion truth = the settled STATUS, not the wait notification.** The
     background-wait notification is a convenience. If it is killed, times out at
     the harness layer, or does not arrive within a heartbeat, RECONCILE by polling
     `herdr agent get <name>`: a `done`/`idle`/`blocked` status is authoritative
     completion even with no delivered notification. Never let a missing
     notification stall the loop — when unsure, `herdr agent get` before concluding
     the agent is still working.
  5. On settle, `herdr agent read <name> --source recent-unwrapped` to read the
     final report, then verify it against the expected deliverable.
- Target agents by unique name or pane id; use `--no-focus` to keep user focus.

## IaC-repo specialization (apply only when the target is a Terraform/IaC repo)

- bd writes via the `beads` skill (against the repo's bd DB).
- Cloud SSO browser auth and `terraform apply` are human-gates.
- IaC changes require a tfplan artifact; run the repo's plan step to produce it.
