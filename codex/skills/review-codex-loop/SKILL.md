---
name: review-codex-loop
description: >-
  Drive the Codex PR-review loop to convergence on a GitHub pull request. Post
  an `@codex review` comment, poll for the chatgpt-codex-connector bot's review,
  triage each inline comment, fix-and-push or reply, resolve each thread, then
  re-request review and repeat until Codex approves or a stop condition fires.
  Use when asked to run or automate Codex review on a PR, converge Codex review
  comments, resolve Codex review threads, or loop `@codex review` until approval.
  Trigger on "review-codex-loop", "codex review loop", "run the @codex review
  loop", "converge Codex review", "resolve Codex findings", "automate Codex
  review".
---

# review-codex-loop

Automate the back-and-forth with the Codex GitHub reviewer (`chatgpt-codex-connector[bot]`)
on one pull request until it approves, or until a stop condition escalates to a human.
Only Codex-authored reviews are handled automatically; other reviewers are reported, not auto-answered.

## Invocation

- `$review-codex-loop <pr>` — target PR by number or URL.
- `$review-codex-loop` — no arg: resolve the PR of the current branch (`gh pr view --json number`).

## Preconditions

- `gh` authenticated for the repo; `git` on the PR branch; PR pushed and mergeable-in-progress.
- Codex review is enabled for the repo (it reacts to `@codex review`).
- Determine `OWNER/REPO` and `PR` once; reuse for every API call. See `references/mechanics.md`.

## Execution model (background subagent)

Run the loop in a background subagent, not inline on the main agent. The main agent is only the
orchestrator: it spawns one subagent, then relays that subagent's final report to the human.

- **Spawn one subagent for the whole loop.** Use the `Agent` tool with `subagent_type: fork` so it
  inherits the PR, repo, and commit-convention context. That one subagent owns the entire loop
  (request → poll → triage → fix/won't-fix → reply → resolve → re-request) and runs it to
  convergence in the background. Do not fan out per-finding or per-cycle: a single owner keeps every
  commit/push on the PR branch serialized and conflict-free.
- **The subagent never waits on a human, and never relies on auto-resume.** It returns control to
  the main agent at a genuine stop condition (approval, held, cycle cap, timeout, wait-arm-failure)
  with a structured result. Waiting on the **bot** is a CHECKPOINT, not a stop: when it would wait,
  the subagent yields a *waiting checkpoint* (its live waiter receipt + the durable run-state path;
  see Loop step 2). It must NOT encode "the harness re-invokes me when the background waiter exits"
  as the re-entry mechanism — this session proved that unreliable: a waiter can exit (even with
  RESPONSE) while the subagent goes idle with `no active task`, no progress, and no stop-notification.
  Re-entry is the **main agent's** duty (next bullet), and every (re)entry re-derives state from
  ground truth, so a missed re-invoke never loses or duplicates work.
- **The main agent relays; it does not run the loop itself.** On return, surface the approval or the
  escalation to the human. Only after the human resolves a held item does the main agent spawn a
  fresh subagent to continue.
- **A "waiting" checkpoint is the main agent's DUTY to re-drive — not a result, and not self-
  resuming.** The runtime surfaces the subagent's interim waiting message as if it were a completed
  result while the poll waiter is still running. When the message says it is waiting/polling (it
  must quote a live waiter task ID — launch-receipt rule), the main agent MUST, in order:
  1. **Poll ground truth on BOTH surfaces** — `pulls/{pr}/reviews` AND `issues/{pr}/comments` (REST,
     `[bot]` login; approval arrives as an *issue comment*, so a reviews-only check misreads it as a
     timeout). See the bot-login note in `references/mechanics.md`.
  2. If ground truth shows a genuine stop (approval, or findings needing the human), handle/relay it.
  3. **Otherwise guarantee re-entry — do not just "wait for the next notification".** Schedule a wake
     (`ScheduleWakeup`, interval ≈ one waiter arm, ~2-8 min) so re-drive happens even if no completion
     notification ever arrives; then on that wake **or** the waiter's completion notification
     (whichever is first) resume the subagent (`SendMessage`) after re-sweeping ground truth.
  Never assume the subagent resumes itself, and never leave it idle. If a wake or notification finds
  the subagent idle (`no active task`) while the loop is not at a stop, resume it from ground truth
  immediately — that is the recovery for the silent-idle stall this rule exists to prevent.

## Loop

The background subagent runs this loop. Track `held = []` (judgment-requiring findings). Do NOT
keep `cycle` only in memory — it is lost on respawn. Derive it from PR ground truth: the count of
`@codex review` comments authored by the authenticated user (`$ME`) since the run's start
(carried in the escalation payload across respawns). A resumed/fresh subagent enters at step 0,
never blindly at step 1 — this prevents double triggers.

0. **Cycle-0 sweep (entry point, every (re)start).** Before posting any trigger, sweep ground
   truth: enumerate ALL existing **unresolved** bot review threads and the latest bot verdict
   issue comment (marking a PR ready-for-review may itself auto-trigger a Codex review, so bot
   activity can predate the loop). If an unhandled verdict exists → step 3. If unresolved bot
   threads exist → triage them as this cycle's findings (step 4) without posting a new trigger.
   Otherwise → step 1.
1. **Request review.** FIRST record `base_review_id = max(existing review ids)` and
   `base_issue_id = max(existing issue-comment ids)`, THEN post the `@codex review` comment
   (capture its URL) and record `trigger_ts = now`. Capturing baselines after posting is a race:
   a fast bot response lands at/below the baseline and is silently skipped → false timeout.
2. **Arm a waiter for the Codex response — do not "poll" inline.** Launch the canonical poll
   script from `references/mechanics.md` Step 2 as a **background Bash task**
   (`run_in_background: true`); it exits with an explicit `RESPONSE` / `PENDING` / `TIMEOUT`
   status line. The response may be either shape: a new bot **review** with inline comments, or a
   new bot **issue comment** verdict (approval usually arrives as an issue comment, NOT a review).
   The 20-min cap is wall-clock from `trigger_ts` — on every wake, re-check ground truth first;
   re-arm on `PENDING` only while inside the budget; never restart the budget. If the budget
   elapses with no bot response → timeout (stop condition c). If you cannot arm a waiter at all →
   `wait-arm-failure` escalation (stop condition c), which is NOT a timeout and does not consume a
   cycle. Ignore non-bot activity (report separately; do not auto-handle).
   When you arm the waiter and yield, yield a **waiting checkpoint**: the waiter task ID + the
   run-state path — so the main agent can drive re-entry (Execution model) and reconstruct state.
   Persist run-state to a durable file (run-start ts, cycle, `trigger_ts`, phase, last-arm ts,
   waiter task ID) and refresh it on every arm; it is the heartbeat the main agent checks for a
   stall. On every (re)entry, re-run the §0 ground-truth sweep FIRST — derive state from the PR +
   run-state, never from memory — so re-entry is idempotent and a missed re-invoke is harmless.
3. **Detect approval.** Approved when the bot posts an issue comment starting
   `Codex Review: Didn't find any major issues.` whose `Reviewed commit` matches the pushed head,
   OR a review that adds no new actionable inline comments. On approval the loop is **done**.
   Report and stop.
4. **Triage every unresolved bot thread** (not just this cycle's review — sweeps and overlapping
   auto-reviews surface older ones too). First dedup: fingerprint by (path, line, gist of the
   claim); duplicates get one canonical triage, and the non-canonical threads get a short reply
   referencing the canonical one, then resolve. Write every thread reply as a **polite Japanese
   statement** (desu/masu form); see the reply-style guardrail. For every comment:
   - Decide fix-necessity. If the fix is obvious, act directly. If necessity or the convergent fix
     is **non-obvious or has multiple viable solutions**, run a quick `/critique` on that finding
     and adopt the recommended, convergent plan.
   - Route to exactly one branch:
     - **Fix** (clear, in-scope): apply the recommended change, `git commit` + `git push`
       (follow the repo/global commit conventions), then reply on the thread with the evaluation +
       what changed + the commit hash, and **resolve the thread**.
     - **Won't-fix** (false positive, already-accepted trade-off, or out of PR scope): reply with the
       reason, and **resolve the thread**.
     - **Hold** (destructive change, real design decision, or beyond this PR's scope): do **not** fix
       and do **not** resolve; reply stating it is held and why; append to `held`. This is a human gate.
   - Continue until every Codex thread from this review is either resolved or held.
5. **Re-request.** When all resolvable threads are resolved, go back to step 1 (`@codex review`).

Reply/resolve/poll command details are in `references/mechanics.md`. Post the fix commits before
replying so the reply can cite the pushed hash and the next cycle reviews the updated head.

## Stop conditions

On any stop condition the subagent stops and **returns its structured result to the main agent**
(which relays to the human); the subagent never blocks on human input.

- **(a) Approved** (step 3): report the approving review and stop. The loop succeeded.
- **(b) Cycle cap**: after completing the **5th** `@codex review` cycle without approval, stop and
  escalate to a human. Do not post a 6th `@codex review`. Cycles are counted from PR ground truth
  (`$ME`-authored `@codex review` comments since run start), not an in-memory counter.
- **(c) Held findings / timeout / wait-arm-failure**: escalate to a human immediately when any
  finding is placed in `held`, when the 20-min wall-clock budget from `trigger_ts` elapses with no
  bot response (**timeout**), or when no waiter could be armed (**wait-arm-failure** — distinct
  reason: the bot may still respond; the resumer should sweep ground truth first and, if the
  budget has not elapsed, re-enter waiting without a new trigger or cycle increment).

On any escalation, return a payload with: escalation reason (`held` / `timeout` /
`wait-arm-failure`), cycles used, `trigger_ts`, threads fixed / won't-fixed / held (with links),
the current PR head, and the exact human decision needed for each held item. The main agent passes
this payload into any continuation subagent's prompt so cycle accounting and budgets survive
respawn.

## Guardrails

- Handle only `chatgpt-codex-connector[bot]` reviews. Surface non-Codex reviews to the human; never
  auto-reply or auto-resolve them.
- Never resolve a thread you did not respond to first. Every resolved thread has a reply explaining
  fix or won't-fix.
- Write every thread reply as a **polite Japanese statement** (desu/masu form): courteous, factual, and
  addressed to the reviewer. This applies to fix, won't-fix, and held replies alike. Exceptions that
  stay as-is: the `@codex review` trigger stays the literal English command, and commit messages keep
  following the repo/global commit conventions — do not switch those to Japanese.
- Never auto-fix or auto-resolve a **held** finding — that is the human gate (per stop condition c).
- Keep commits scoped to the finding being addressed; do not fold unrelated changes in.
- Do not put secrets, tokens, or internal issue IDs into PR comments or commit messages; follow the
  repo's and global commit conventions.
- One reply per thread per cycle; do not spam. Prefer editing/replying over opening duplicate threads.
- **Launch-receipt rule — never claim to be waiting without a live waiter.** Do not end a turn in a
  waiting state unless, in that same turn, a background waiter was actually started and its tool
  result returned a task ID; quote that task ID in the yield message. A textual claim of "polling
  in background" backed by no receipt is a `wait-arm-failure` (stop condition c), not a valid wait.
  This is the failure mode this rule exists for: an agent sincerely believing it is polling while
  nothing is alive.
- Run the loop in one background subagent that solely owns the PR branch and serializes its
  commits/pushes; never spawn parallel subagents that write the same branch. The human gate lives in
  the main agent: the subagent returns on any stop condition and never waits on a human itself.
- **No silent idle (liveness invariant).** A valid bot-wait requires BOTH a live waiter receipt
  (launch-receipt rule) AND a main-agent-scheduled re-drive (a `ScheduleWakeup`, plus resuming on the
  waiter's completion notification if it arrives). One without the other is incomplete: if the
  auto-re-invoke never comes, the scheduled wake still re-drives; if neither is armed it is a
  `wait-arm-failure` — escalate. Because every (re)entry begins with the ground-truth sweep, resuming
  a stalled/idle subagent is always safe and never double-triggers.
