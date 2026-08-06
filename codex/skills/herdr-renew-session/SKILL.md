---
name: herdr-renew-session
description: >-
  Replace a context-exhausted Herdr orchestrator session with a successor session
  in a sibling pane that inherits the accumulated decision history through a
  durable handoff, verifies it by reciting the current position, then takes over
  the orchestrator agent name and closes the predecessor's pane. Use ONLY when a
  human explicitly asks for it — invoke on /herdr-renew-session, replace the main
  session, renew the orchestrator session, swap this session for a fresh one, hand
  this orchestration over to a new session, or start a successor session that
  inherits the context. Do NOT fire on context pressure alone; summarizing in place
  is a different job. Requires HERDR_ENV=1, an active desk task note with a bd
  issue, and that this session is the orchestrator. Composes the herdr, herdr-impl,
  and desk-live skills.
---

# herdr-renew-session

Retire THIS session and stand up a successor that resumes the same orchestration
under the same agent name — losing the conversation but not the decision history.

The whole difficulty is that the outgoing session is the only thing that holds the
context, and it cannot act after it exits. So everything the successor will need must
be written to a durable store first, and the successor must prove it read that store
while the predecessor is still alive to fix it.

## Preconditions (stop if unmet)

1. `test "${HERDR_ENV:-}" = 1`. If not inside Herdr, say so and stop.
2. **A human asked for this explicitly.** Never self-trigger from context pressure —
   compacting in place is the cheaper answer, and this procedure discards a session
   and closes a pane. If you merely *observe* pressure, say so and wait.
3. **An active desk task note + its bd issue.** This skill is scoped to desk-live
   orchestration; the note and issue ARE the durable store. If there is none, stop and
   say the scope does not apply.
4. **This session is the orchestrator and already has an agent name** (`herdr agent get
   "$HERDR_PANE_ID"` reports `.result.agent.name`). If it does not, name it first
   (`herdr-impl` Protocol 0) — that name is what the successor inherits, and a pane
   *label* is not a name.

## Invariants (never violate)

- **Nothing durable goes in the scratchpad.** The agent scratchpad directory is keyed
  to the session id, so the successor gets a DIFFERENT one and cannot read yours.
  Durable stores only: the desk task note (Obsidian), the bd issue, and a gitignored
  directory inside the worktree (`<worktree>/.local/`). This applies to the handoff
  prompt file too — keep it under `<worktree>/.local/` so it can be re-sent.
- **Verify before dying.** Do not `/exit` until the successor has recited the current
  position back (see the Gate). A settled `idle` proves nothing about comprehension —
  the same discipline as verifying a deliverable rather than a status.
- **The successor is the only actor after the gate.** Once you exit you cannot rename,
  close, or notify anything. Every post-exit step must be armed as an instruction the
  successor already holds.
- **Keep the orchestrator name continuous.** Sibling panes were told to report to your
  name. If the successor does not inherit it, every one of those instructions goes
  stale silently.

## Composition (read, do not duplicate)

- `herdr` — pane/agent primitives, name-vs-label resolution, read sources.
- `herdr-impl` — **`## Agent naming (session-unique)`** and **`## Herdr I/O cautions`**.
  Submission, completion detection, prompt-via-file, and naming rules live there.
  Follow them; do not restate them here.
- `desk-live` / `desk` — Turn-N, frontmatter fields, and the cold-resume contract the
  successor boots from.

## Protocol

### 0. Triage volatile vs durable

Before writing anything, decide where each fact belongs. Facts the successor cannot
re-derive must go to a durable store; facts it can re-derive cheaply need not be
written at all.

| Volatile (dies with this session) | Durable (survives) |
| --- | --- |
| this conversation, the scratchpad dir, in-flight tool state | desk task note, bd issue, `<worktree>/.local/` |
| ports of daemons YOU started, pane/agent topology | git history, pushed commits |

### 1. Inventory the runtime

Collect the live facts the successor would otherwise have to rediscover:

```bash
herdr agent list                     # panes, agent names, kinds, status — who holds what context
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
git -C <worktree> status --short && git -C <worktree> log --oneline -5
git -C <worktree> rev-list --count origin/<base>..HEAD
```

Plus: ports of services you launched (e.g. a review daemon), and external
preconditions (container runtime up? cloud SSO still valid?).

### 2. Write the durable handoff (two layers)

**Layer 1 — revise the task note's cold-resume material.** Do not append; **correct
it**. Stale premises are the main failure mode: a successor that reads "sandbox
unverified / worktree not created" when both are long done takes a wrong first action.
Re-read what the note currently claims and fix every premise that has moved.

**Layer 2 — write `<worktree>/.local/HANDOFF.md`** for the volatile half. Required
sections, in this order:

1. **Reading order** — task note → bd description → bd comments → this file.
2. **⚠ Policy reversals, at the very top.** Anything already rejected or superseded
   ("the self-signed route is rejected — do not apply it"). A successor that misses
   this resumes work on a discarded plan, and it will look productive while doing it.
3. **Traps that bite immediately** — the non-obvious ones only.
4. **How to reach bd** (e.g. TCP rather than socket, when that is not the default).
5. **git state** — branch, HEAD, commit count, pushed or not, and **every
   intentionally-uncommitted file with the reason it is uncommitted**.
6. **Live runtime table** — service, port, how to re-verify it.
7. **Sibling panes** — agent name, kind, and what context each one holds.
8. **Open human decisions** and **questions already settled** (so nothing is re-asked).

Ensure `<worktree>/.local/.gitignore` is `*` so none of this is committable.

### 3. Flip the task note frontmatter to a handover state

Per `desk-live`: `runtime_status`, `runtime_subagent_role`, `runtime_heartbeat_at`,
`current_status_summary`. **Lead `current_status_summary` with the policy reversal and
the handoff path** — it is the first thing a cold resume reads.

### 4. Spawn the successor beside yourself

Split YOUR OWN pane, so that closing it later lets the successor expand into the space.
That preserves the orchestrator's position without `herdr pane move`, whose silent
zoom no-op and pane-ID change are avoidable risk here:

```bash
NEW=$(herdr pane split --current --direction right --cwd <worktree> --no-focus \
      | jq -r '.result.pane.pane_id')
herdr agent start <orch-name>-next --kind claude --pane "$NEW"
herdr pane rename "$NEW" <orch-name>-next
```

Use a temporary name: your name is still taken, and claiming it is the successor's
last step, not its first. Name and label per `herdr-impl` `## Agent naming`.

### 5. Prompt it: critical facts inline, the rest by pointer

Write the brief to `<worktree>/.local/handoff-prompt.md` and submit it with
`"$(cat …)"` — never a bare variable (see `herdr-impl` `## Herdr I/O cautions`). The
durable path matters: a successor that dies on an upstream error has NO context to fall
back on, and you must re-send the same brief verbatim.

Inline in the brief, because missing them is fatal:

- the policy reversals,
- the traps that bite immediately,
- the reading order and the absolute path of `HANDOFF.md`,
- the takeover instructions from step 7,
- the explicit ask: **recite the current position back** — policy in force, git state,
  and the intended next action.

Everything else stays a pointer. The point of renewing is a free context window; do not
spend it re-narrating what the successor is about to read.

### 6. Gate: the successor recites the current position

Follow `herdr-impl`'s state-anchored completion protocol, then **read the recitation and
check it against the handoff** — the recitation IS the deliverable here; a settled
status is not.

Accept only if it names the policy in force (including what was rejected), the git
state, and a next action consistent with the plan.

- Wrong or thin → **fix the handoff, then re-prompt the same successor**; the gap is
  usually the document's, not the reader's. Cap at 2 retries.
- Still wrong → **abort the renewal**: close the successor pane and keep living. This is
  exactly why the successor is verified in a sibling pane before you exit — an abort
  must cost nothing but the pane.

### 7. Arm the takeover, then exit

The successor must already hold these instructions before you go, because nobody else
can issue them afterwards:

1. Poll `herdr agent list` until `<orch-name>` is absent.
2. `herdr pane close <old-pane-id>` if that pane still lingers.
3. `herdr agent rename "$HERDR_PANE_ID" <orch-name>` and
   `herdr pane rename "$HERDR_PANE_ID" <orch-name>`.
4. Verify with `herdr agent get <orch-name>` — **`herdr pane get` reports only the label
   and cannot confirm the name**.
5. Resume the task.

Then close out as the outgoing session: final Turn-N in the task note, a matching bd
comment (+ `bd dolt commit`), and a report naming the successor's pane id and temporary
name. Exit last — submit `/exit` as a prompt after `esc`; **`ctrl+d` does not exit
Claude Code** and can resume the turn instead.

### 8. Successor: take over

Execute the armed instructions. If the name cannot be inherited for any reason, the
fallback is not to shrug: **prompt every sibling pane with the new destination**, since
their standing "report to `<orch-name>`" instructions are now dead letters.

## Report

State the handoff paths (task note, bd issue, `HANDOFF.md`), what the successor recited,
its pane id and the name it will take, and which durable premises you had to correct in
step 2.

## Hard constraints

- Never put handoff content in the scratchpad directory.
- Never `/exit` before the gate passes.
- Do not close the predecessor pane from the predecessor — arm the successor to do it.
- Do not commit or push as part of the renewal; carry uncommitted work forward by
  documenting it instead.
