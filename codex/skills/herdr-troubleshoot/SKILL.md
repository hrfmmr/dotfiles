---
name: herdr-troubleshoot
description: >-
  Troubleshoot an error or issue during implementation orchestration by spawning
  a research-only investigation agent in a Herdr pane, agreeing the fix plan with
  the architect (you) and a human, then delegating the fix to an active worker
  agent. The investigation pane researches root cause + fix direction (no edits);
  you verify each finding against source, classify it as code-fix vs operational,
  get human approval of the fix plan, hand code fixes to the worker (reuse an
  active one, else create a worktree-backed one), then lightweight-verify.
  Composes the base herdr skill; the runtime counterpart to herdr-impl's review
  loop. Use when a build/apply/test/deploy/plan step fails mid-orchestration, when
  you want a dedicated agent to investigate a failure before fixing, when asked to
  run herdr troubleshoot, spin up an investigate pane, research an error and
  delegate the fix, diagnose-then-fix across panes, or invoke /herdr-troubleshoot.
  Requires HERDR_ENV=1.
---

# herdr-troubleshoot

Position this session as the **architect/orchestrator**. You do not investigate
or fix directly. You drive a research-only `investigator` pane, verify its
findings against source, get human agreement on the fix plan, delegate code
fixes to a `worker` pane, then lightweight-verify. This is the runtime-failure
counterpart to `herdr-impl`'s review loop and is frequently invoked from inside
that relay loop when an `apply`/build/test step fails.

## Preconditions (stop if unmet)

1. `test "${HERDR_ENV:-}" = 1`. If not inside Herdr, say so and stop.
2. A **concrete issue** to investigate: an error log, failing command output, or
   a reproducible symptom. If none is provided, ask for it and stop.
3. A **target repo/worktree** where any code fix will land. If a worker must be
   created, a git worktree (via `wt`) is the prerequisite for it.

## Invariants (never violate)

- **Research-only investigator.** The investigator MUST NOT edit files, run
  `apply`, commit, push, or write to any issue tracker. It only reads, runs
  read-only commands, researches, and reports findings + fix direction.
- **Human agreement gate.** NEVER delegate a fix until the human approves the
  fix plan. Present verified findings + the proposed fix, then wait.
- **Human gates** (architect/worker never perform): `terraform apply`, SSO
  browser auth, and **operational remediation** (state import, manual resource
  ops, destructive changes). Surface these as commands for the human to run.
- **Orchestrator-only writes.** ONLY this session writes to a bd issue / task
  note. The investigator and worker MUST NOT — forbid it in their prompts.
  Capture their hand-off as an orchestrator-authored bd COMMENT when a bd issue
  exists (skip silently when none).
- **bd-id hygiene.** The bd issue id appears ONLY in a branch/worktree name.
  Never in code, commit messages, or PR body. Forbid it in delegation prompts.
- **Pane hygiene.** Do not close panes/tabs/workspaces you did not create. Leave
  the investigator pane idle at the end for a possible re-investigation.

## Composition (invoke, do not reimplement)

- `herdr` — base pane/agent control (split, agent start, prompt, send-keys,
  read, wait, rename, get). Follow its CLI contract for every command.
- `wt` — create the worktree-backed worker when no active worker exists.
- `herdr-review-loop` — optional stricter post-fix verification (Step 5).
- `herdr-impl` — the parent orchestration this skill is usually invoked from.

## Arguments

- `issue` (required): the error text / failing command / symptom + any context
  (which stack/step, path to a saved log).
- `investigator_kind` (default `codex`), `worker_kind` (default `claude`).
- `target` (optional): repo/worktree/stack path the fix lands in.
- `worker` (optional): name of an existing worker agent to reuse; else discover
  an active one, else create.

## Protocol

0. **Preflight.** Verify preconditions. Resolve the issue text, the target path,
   and whether an active worker exists (`herdr agent list`). Detect a bd issue /
   desk task note for optional logging.
1. **Investigator pane.** Follow herdr agent pane geometry: if no bottom agent row
   exists yet, `herdr pane split --current --direction down --no-focus` with
   `--cwd <target>`; if one does (e.g. a `worker` pane), vsplit its last pane with
   `herdr pane split --pane <last-bottom-pane-id> --direction right --no-focus`.
   Then `herdr agent start investigator --kind <investigator_kind> --pane <id>`,
   then `herdr pane rename <id> investigator`. **Set BOTH the agent name AND the
   pane label** to the same value at creation (use a unique name if one is
   taken, e.g. `<scope>-investigator`). Verify with `herdr agent list`.
2. **Delegate investigation.** Submit a self-contained research prompt (see
   Delegation prompt rules). Require, per distinct error: **root cause**, a
   **concrete fix direction** (file:line for code; exact command for
   operational), and a **classification: code-fix vs operational**. Tell it to
   use authoritative docs AND read-only CLI verification where possible, and to
   flag doc/reality mismatches. Await a SETTLED state (state-anchored — see
   Herdr I/O cautions), then read and capture the full report (use the file
   fallback if the pane truncates).
3. **Verify + triage against source.** Do not trust findings blindly. Confirm
   each against the actual files/config/live read-only checks. Route each:
   - **code-fix** — source-confirmed change → collect for the worker.
   - **operational** — state import, apply-time step, SSO, destructive → HUMAN.
   - **hold** — needs a genuine design decision → HUMAN, do not auto-fix.
4. **Agree the fix plan (HUMAN GATE).** Present the verified findings and the
   proposed fix plan (code-fixes to delegate + operational steps for the human)
   and **wait for the human's approval**. Do not proceed to delegation without
   it. If the human revises scope, update the plan and re-confirm.
5. **Delegate code fixes to the worker.** Reuse an active worker agent when one
   exists; otherwise create one: `wt` a worktree, split a pane with `--cwd` on
   it, `herdr agent start worker --kind <worker_kind>`, name+label `worker` (or
   `<scope>-worker`). Submit a self-contained fix prompt embedding the exact
   fixes (file:line, exact replacement/ARN/JSON). Worker rules: one scoped
   micro-commit with a validation signal in the message; offline validation
   only (no creds); **no `apply`, no push, no PR, no bd writes, no bd-id in code
   or commit messages**; STOP and report on ambiguity. Await a SETTLED state.
6. **Lightweight verify + hand off.** Confirm the worker's fix against source,
   offline validation, and clean scope/commit hygiene (no bd-id leak, scoped
   diff). This is intentionally light — troubleshooting favors fast turnaround.
   Escalate to `/herdr-review-loop` only when the change warrants stricter
   convergence. Then hand the **operational** items to the human as exact
   commands, report the commit and remaining human steps, and record a bd
   COMMENT if a bd issue exists. If applying the fix surfaces a NEW error, loop
   from Step 2 (reuse the idle investigator pane).

## Delegation prompt rules

**Investigator (research-only)** — the prompt MUST:
- Embed the full error text (or its path) and pointers to the relevant source.
- Forbid ALL writes: no edits, no `apply`, no commit, no push, no bd.
- Ask for root cause + concrete fix direction + code-fix/operational
  classification per distinct error, self-contained enough to hand to a fixer.
- Encourage authoritative docs AND read-only CLI verification; ask it to flag
  any doc-vs-reality mismatch and cite sources.
- Ask it to STOP and report on ambiguity rather than guess.

**Worker (fix)** — the prompt MUST:
- Be self-contained: embed the exact fixes (file:line + exact change) so the
  worker needs no bd/investigator access.
- Forbid `git push`, PR creation, bd/task-note writes, and the bd-id in code or
  commit messages. Forbid `terraform apply` and any creds-requiring command;
  note SSO/apply/operational steps are human.
- Require one scoped micro-commit with a validation signal, offline validation,
  and a final report (files changed, validation results, commit sha).
- Ask it to STOP and report on ambiguity rather than guess.

## Herdr I/O cautions

- **Name + label at creation.** The moment a pane hosts an agent, set BOTH the
  agent name (`herdr agent start <name> ...`) AND the pane label
  (`herdr pane rename <pane> <name>`) to the SAME unique value. An unnamed pane
  shows only "Claude Code"/"Codex" and is hard to target later.
- **Paste is not always atomic; submit may stall.** After
  `herdr agent prompt <name> "<prompt>"`, if it returns `agent_prompt_stalled`
  (status unchanged, `state_change_seq` not advanced), the text is pasted but
  not submitted — send `herdr agent send-keys <name> Enter` and re-check.
- **Completion is state-anchored.** Record `state_change_seq` before submitting;
  confirm the agent moved to `working` (status `working` AND seq advanced) after
  submit; then await a SETTLED state with `herdr agent wait <name>` and **no
  `--until`** (never `--until idle` — an unseen background agent settles in
  `done`, not `idle`, so `--until idle` hangs to timeout). **Treat `done` as
  completion.** If it settles `blocked`, it hit an approval/question — read and
  respond. Background long waits and resume on notification.
- **Completion truth = settled STATUS, not the wait notification.** If the
  notification is missed/killed, RECONCILE with `herdr agent get <name>`: a
  `done`/`idle`/`blocked` status is authoritative completion.
- **Capture-on-truncate fallback.** If a pane read truncates (codex/TUI
  alternate screen), ask the agent to write its complete report to a temp path
  and reply with only that path, then read the file.
- Target agents by unique name or pane id; use `--no-focus` to keep user focus.

## Failure / timeout handling

- On a prompt stall: re-send `Enter` → re-check → respawn the agent → escalate.
- Use generous timeouts for generative steps; background long waits.
- Keep panes on abort (no auto-clean); the human decides cleanup.

## Logging (orchestrator only)

- When a bd issue / desk task note is active, record a COMMENT (and a desk
  Turn-N if in a desk-live session) at: investigation delegated, findings +
  triage, human-approved plan, worker fix verified, hand-off. Never edit an
  issue description for progress. Skip silently when no bd issue exists.
