---
name: herdr-impl
description: >-
  Orchestrate a single bd-issue implementation across Herdr panes as the
  architect/orchestrator. Create a bd-issue-prefixed worktree, spawn a `worker`
  agent to implement the issue's handoff plan, collect validation + tfplan
  artifacts, run a third-party review loop in a `reviewer` pane, relay findings
  worker↔reviewer until no HIGH findings remain, present the diff for human
  review via hunk-present (reusing the implementer worker as the hunk fix
  worker), then leave a merge-ready branch for a human to open and merge the PR.
  Worker runs claude sonnet5; reviewer runs codex. Requires HERDR_ENV=1 and an
  existing canonical bd issue that already contains a handoff plan. Composes the
  herdr, wt, herdr-review-loop, hunk-present, and desk-live skills. Use when asked
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
- **Addressable orchestrator.** This session must be reachable as a prompt target
  BEFORE any agent is spawned. Herdr resolves a target by **agent name or pane ID
  only — a pane *label* is not a target.** A label-only orchestrator pane cannot be
  replied to: a worker/reviewer prompt addressed to it fails identity resolution and
  the result never arrives. Name your own agent first (see Protocol 0).

## Composition (invoke, do not reimplement)

- `herdr` — base pane/agent control (split, agent start, prompt, read, wait, rename).
- `wt` — create the bd-issue-prefixed worktree. Always reuse `wt`; never raw `git worktree`.
- `herdr-review-loop` — reviewer pane + branch-diff review loop (Step 5–6).
- `hunk-present` — human review of the branch diff (Step 7): reading map in a dedicated Herdr tab, hunk comment Q&A, verdict.
- `beads` — bd graph writes when the repo uses a bd-backed issue DB.
- `desk-live` — Turn-N logging when a desk task note is active (optional; see Logging).

`mesh` is the in-session sub-agent orchestrator; `herdr-impl` is its Herdr-pane
counterpart. Reference it for the loop pattern; do not reimplement it.

## Arguments

- `bd_issue` (required unless derivable from an active desk task): the canonical issue.
- `worker_kind` (default `claude`, model `sonnet5` — start with `--kind claude -- --model sonnet`), `reviewer_kind` (default `codex`): overridable.
- `slug` (optional): branch slug; else derive from the bd issue title.
- `plan_source` precedence: explicit arg > bd issue description > desk task note.

Model policy: the main orchestrator session driving this skill (the architect / commander
role in the Herdr session) runs on claude fable5. worker = claude sonnet5. reviewer = codex
(unchanged). Planning/critique agents launched upstream (desk plan-first / `$rough-plan`)
carry no model pinning.

## Agent naming (session-unique)

The agent-name namespace is shared by the WHOLE Herdr session, so the bare names
`worker`/`reviewer` collide with any other run still alive. Derive a per-run prefix
from the branch slug decided in Step 1 and use it for both agents:

```
PFX   = the slug's FIRST token          # worktree n0z--cp5c-lattice-tls → slug cp5c-lattice-tls → cp5c
names = <PFX>-worker  /  <PFX>-reviewer # cp5c-worker / cp5c-reviewer
```

**Why the slug and not something opaque.** Names must stay discoverable by a human
scanning the pane list. A workspace id (`wy-worker`) is unique and fully
deterministic, but it is an opaque handle — with five runs in flight nobody can tell
which pane belongs to which issue. That recreates the exact findability problem this
skill already warns about (an unlabelled pane "is hard to find and target later").
The slug head names the issue in one glance.

**Length budget — derive it, never hardcode the number.** Names must match
`[a-z][a-z0-9_-]{0,31}` — 32 chars max. Compute the prefix budget by subtracting
EVERY suffix the name will carry:

```
budget = 32 - len(role_suffix) - len(numeric_suffix)
       = 32 - len("-reviewer")            = 23   # normal case
       = 32 - len("-reviewer") - len("-2") = 21   # when falling back to a numeric suffix
       = 32 - len("-reviewer") - len("-10") = 20  # if the counter may reach two digits
```

**Always budget against the LONGER role suffix `-reviewer` (9), never `-worker` (7).**
Budgeting on `-worker` yields an asymmetric failure where the worker name is accepted
and only the reviewer name is rejected.

The budget is a ceiling on how far the prefix may GROW, not the initial value: the
initial `PFX` is the first slug token (see above), and extension keeps joining tokens
with `-` while the result stays inside the current budget. If a single token already
exceeds the budget, truncate it to the budget.

**On collision, extend the prefix — do not switch schemes.**

1. Try `<PFX>-worker` / `<PFX>-reviewer`.
2. On `agent_name_taken`, read the holder the error reports
   (`pane_id` / `workspace_id` / `cwd`) to confirm it is a different run, then extend
   the prefix by the NEXT slug token — `cp5c-worker` → `cp5c-lattice-worker` — still
   inside the current budget.
3. Only if that still collides, fall back to a numeric suffix (`cp5c-worker-2`).
   **Re-budget and trim the prefix FIRST, then append the counter** — the numeric
   suffix shrinks the budget (23 → 21), so a prefix already grown to the full 23 must
   be cut back before the counter is added. Appending first and discovering the
   overflow afterwards fails as a name-VALIDATION error, not `agent_name_taken`, which
   makes the escalation look like an unrelated breakage. In this case you MUST also
   record the resolved names (bd comment + every delegation prompt), because the name
   no longer maps to the slug.

**bd ids are ALLOWED in agent names and pane labels.** The bd-id-hygiene invariant
guards *artifacts* — code, commit messages, PR body — things that persist and travel
outward. An agent name and a pane label are session-local volatile operational
handles that are never committed or published, so they sit on the same side of that
line as the branch name. The rule above simply does not need one: worktrees are named
`<bd-id>--<slug>`, so taking the slug head already yields a bd-id-free name. If some
future scheme does use a bd id, sanitize it first — names permit no dots, so
`u31.4.1.9` must become `u31-4-1-9`.

Whatever name is resolved, apply that SAME value to the agent name AND the pane label.

## Protocol

0. **Preflight.** Verify preconditions. Resolve the bd issue, its handoff plan
   (by `plan_source` precedence), the target repo, and its default branch.
   Detect IaC-repo context to enable specializations (see below).
   **Then make yourself addressable**: this is a two-way topology — the agents you
   spawn must be able to send results back — so give THIS session's agent a name
   before spawning anything:

   ```bash
   herdr agent get "$HERDR_PANE_ID"                 # does .result.agent.name exist?
   herdr agent rename "$HERDR_PANE_ID" <orch-name>  # e.g. main — only if it does not
   herdr pane rename "$HERDR_PANE_ID" <orch-name>   # keep label == agent name
   ```

   A pane whose label is already `main` proves nothing: the label is not a target.
   Tell every spawned agent to report back to `<orch-name>` by that exact name.
1. **Worktree.** Use `wt` to create branch/worktree `<bd-id>--<slug>` from
   `origin/<default-branch>` (fetch first) under the repo's `__worktrees__/`.
2. **Worker pane.** Split the architect pane DOWN — `herdr pane split --current
   --direction down --no-focus` with `--cwd <worktree>` — so the agent panes form
   a bottom row under this session (herdr agent pane geometry). This worker pane
   is the base that the reviewer pane later vsplits off in Step 5. Resolve the name
   per Agent naming (`<PFX>-worker`), then
   `herdr agent start <PFX>-worker --kind <worker_kind> --pane <id>`, then
   `herdr pane rename <id> <PFX>-worker`. **Set BOTH the agent name AND the pane
   label to that same value.**
3. **Delegate implementation.** Build a self-contained prompt from the handoff
   plan (see Delegation prompt rules). Submit it robustly and **await completion
   state-anchored** (see Herdr I/O cautions): confirm the worker reached `working`,
   then wait for a SETTLED state (`herdr agent wait <name>` with NO `--until`;
   `done` counts as completion). Never use `--until idle` — it misses the `done`
   state that unseen background agents settle into and hangs to timeout — and
   never mistake the pre-work idle for completion. On settle, read the worker's final
   report AND confirm the deliverable exists on disk before moving on — a settled
   `done` alone does not mean work was produced.
4. **Artifacts + verify.** Have the worker emit artifacts to
   `/tmp/<bd-id>-review-artifacts/`: required = branch diff + validation
   (fmt/validate); add tfplan for IaC changes. SSO browser auth is a human-gate —
   surface it. Then the orchestrator verifies branch/worktree/commit hygiene
   (no bd-id leak, clean scope) and that the plan matches expectation.
5. **Review.** Invoke `/herdr-review-loop` with a reviewer pane (kind =
   `reviewer_kind`; name it `<PFX>-reviewer` per Agent naming, and set agent name AND
   pane label to that value) over the branch
   diff and the artifacts. Place it by vsplitting the worker pane —
   `herdr pane split --pane <worker-pane> --direction right --no-focus` — so
   worker and reviewer sit side by side in the bottom row.
6. **Relay loop.** Feed HIGH findings to the worker → worker fixes and commits →
   re-review. **Loop until HIGH findings = 0.** HIGH = correctness / security /
   data-loss impact. MED/LOW are recorded as PR comments (non-blocking). Cap at
   **3 review cycles**, then human-escalate.
7. **Human review (hunk).** Present the branch diff to the human via
   `$hunk-present`: dedicated Herdr tab named `hunk-<PR番号|slug>`, three-dot
   (merge-base) target, sidecar reading map. **Reuse `<PFX>-worker` as the hunk
   fix worker — do NOT spawn a new fixer.** The worker keeps its existing pane
   (topology stays as built in Step 2); satisfy `$hunk-present`'s Fix worker spawn
   contract by briefing it with the hunk session coordinates: the worktree path
   (`--repo` selector), the TUI tab/pane ids (read/drive-forbidden), the human
   comments (or the `comment list` command to fetch them), and 5b ownership —
   the worker runs the post-fix re-sync (sidecar anchors, three-dot reload,
   in-place replies with the commit hash). Verdict is recorded per
   `$hunk-present` step 6.
8. **PR handoff.** Leave the merge-ready branch. Report the branch and how to
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
- **Re-submission always re-sends the FULL brief.** An agent that died on an upstream
  API failure has lost its context (`Ctx: 0` in the pane footer) even though the
  transcript is still on screen. Never write "the instructions are in this pane's
  history / scroll back" — there is nothing to read from. Keep the brief in a file
  and re-submit it verbatim.
- **`ctrl+d` does not exit Claude Code.** Sending it to a busy agent can RESUME the
  turn instead of ending it. To retire an agent pane: `herdr agent send-keys <name>
  esc` to stop the turn, then submit `/exit` as a prompt.

## Herdr I/O cautions

- **Name + label at creation (do not skip).** The moment a pane hosts an agent,
  set BOTH the agent name (`herdr agent start <name> ...`) AND the pane label
  (`herdr pane rename <pane> <name>`) to the SAME value (`<PFX>-worker` /
  `<PFX>-reviewer`).
  The pane label MUST correspond to the agent name. Do it at creation time — an
  unnamed pane shows only "Claude Code" in the UI and is hard to find and target
  later. **Verify BOTH, with the two different commands** — `herdr pane get <pane>`
  reports only `label`, and `herdr agent get <pane>` / `herdr agent list` report only
  `name`; neither shows the other. Checking one is not checking both. Do not read
  `pane get`'s `agent` field as the name: it is the agent KIND (`claude`, `codex`),
  so a pane with `label` + `agent` set still proves nothing about the name.
- **Agent names are session-global; `agent start` can fail while `pane rename`
  succeeds.** The agent-name namespace spans the WHOLE Herdr session, not the
  workspace — an agent named `reviewer` in another workspace (another issue's run)
  makes `herdr agent start reviewer` fail with
  `{"error":{"code":"agent_name_taken",...}}`, and the error names the holder
  (`pane_id`/`workspace_id`/`cwd`). So the literal names `worker`/`reviewer` collide
  whenever two herdr-impl runs overlap — which is why names carry a per-run prefix
  (see Agent naming). Pre-check with `herdr agent list` before
  `agent start`. Because rename is a SEPARATE command, a failed `agent start`
  followed by a successful `pane rename` leaves a pane that is *labelled*
  `reviewer` with **no agent of that name** — visually correct, unaddressable. On
  `agent_name_taken`, extend the prefix per the Agent naming escalation and apply the
  resolved name to both the agent and the label; never keep a label that no agent
  name backs.
- **Ghost/recap input.** Claude Code's recap can leave ghost text in a pane's
  input that `esc`/`ctrl+u`/`ctrl+c` do NOT clear (the real buffer is empty). A
  fresh paste replaces it.
- **Paste is not always atomic.** Protocol: paste the prompt → read/verify the
  input shows ONLY your text (recap ghost replaced, no stray prior input
  concatenated) → send `Enter` if it did not auto-submit.
- **Pass the prompt through a FILE, never a shell variable.** Write the brief to
  `/tmp/<bd-id>-<role>-brief.md`, then submit it as
  `herdr agent prompt <name> "$(cat /tmp/<bd-id>-<role>-brief.md)"`. Under the wrong
  quoting (`'...'`, or an escaped `"\$PROMPT"`) the agent receives the LITERAL string
  `$PROMPT` and `herdr agent prompt` still returns `agent_prompted` — success-shaped.
  The only tell is that `state_change_seq` does not advance. A file + `"$(cat …)"`
  removes the whole class of expansion/escaping mistakes and gives you a re-submittable
  brief for free.
- **Do not rely on `herdr agent prompt --wait` for long work.** The waiter is a
  foreground child of the calling Bash tool, so the harness's own ~2-minute command
  limit kills it (`exit 143`) no matter what `--timeout` you pass — while the agent
  keeps `working`, invisible. Preferred shape: submit WITHOUT `--wait` → poll
  `herdr agent get <name>` until `working` is confirmed → run the long
  `herdr agent wait <name>` as a BACKGROUND command and resume on its notification
  (reconciling per the completion protocol below).
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
  6. **A settled status is a NECESSARY, not a SUFFICIENT, condition — always verify
     the deliverable itself.** `done` does not distinguish "finished the task" from
     "the upstream API died". An agent that hit `529 Overloaded`, retried for 3–4
     minutes and produced NOTHING still settles to `done`, with
     `state_change_seq` advanced and the tab title changed to the task name — i.e.
     every submit-side signal in step 2 looks correct. Before reporting progress,
     check the artifact that must exist (commit sha / changed files / artifact path
     under `/tmp/<bd-id>-review-artifacts/`). No artifact = not done, regardless of
     status.
- Target agents by unique name or pane id; use `--no-focus` to keep user focus.

## IaC-repo specialization (apply only when the target is a Terraform/IaC repo)

- bd writes via the `beads` skill (against the repo's bd DB).
- Cloud SSO browser auth and `terraform apply` are human-gates.
- IaC changes require a tfplan artifact; run the repo's plan step to produce it.
