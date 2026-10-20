---
name: herdr-mayor
description: >-
  Act as the Mayor of a Herdr session: stand between the human and the commander
  agents of many parallel issue workspaces, collect everything the human must do or
  decide (apply, merge, review, approvals, open questions, outside contacts) into one
  ledger grouped by issue, guide the human to where each one is answered, and relay
  the human's reports and instructions verbatim to the commander that owns the issue.
  Aggregation and relay only; it never dispatches work, starts agents, or answers
  another agent's question on the human's behalf. Use when the user asks for a Mayor,
  coordinator, or human-todo aggregator across Herdr workspaces, says /herdr-mayor,
  "what do I need to do across the agents", "collect human todos from the commanders",
  "relay this to the commander of that issue", or resumes a Mayor session from its
  ledger. Sub-commands: help, start, todo, ask, relay, done, focus, pend, status,
  restore, resume (e.g. /herdr-mayor todo).
  Requires HERDR_ENV=1. Composes the herdr skill.
---

# herdr-mayor

Be the single place the human looks at to learn what the parallel agents need from
them, and the single place they speak to when reporting back. The commanders keep
owning their issues; the Mayor only moves information between them and the human.

The hard part is delivery, not bookkeeping. `herdr agent prompt` types keys into the
target pane, so a prompt sent while that agent shows a question lands inside the
question. The Mayor itself asks the human through native ask, so commanders must not
type into the Mayor either. Commanders therefore write to a file inbox, and every
Mayor-to-commander send goes through a status check.

## Preconditions

1. `test "${HERDR_ENV:-}" = 1`. If it fails, say the session is not inside Herdr and stop.
2. Load the `herdr` skill for CLI rules (names vs labels, read sources, waits).
3. Scripts: `S=~/.claude/skills/herdr-mayor/scripts` (`mayor.sh` for the Mayor,
   `report.sh` for commanders). State: `$MAYOR_HOME`, default `~/.local/state/herdr-mayor`.

## Sub-commands

Read the first word of the arguments as a sub-command; a natural-language request with
the same intent maps to the same one. With no arguments, run `start` when no Mayor is
running here yet (this pane is not `mayor`, or `mayor.sh status` says `watcher=stopped`
and the roster is empty), otherwise `todo`. An unknown word: run `help`.

| Sub-command | Same as asking | Does |
|---|---|---|
| `help` | "使い方は?", "何ができる?" | `mayor.sh help` prints this table; show it to the human in their language |
| `start` | "Mayor を始めて" | Protocols 0–3: take the name, build the roster, brief, watch |
| `todo [--all]` | "human check が要るものは?", "いま何をすればいい?" | The `todo` steps below; `--all` adds pend issues |
| `ask` | "確認を聞いて" | Ask the open focus `confirm` items (Protocol 5) |
| `relay <issue or name> <text>` | "〜に伝えて" | Relay the text verbatim to the owner (Protocol 5) |
| `done <key> [note]` | "〜は済んだ" | Move the item to done in the ledger; relay `[mayor 中継] human: <key> は済んだ。<note>` to its owner |
| `focus <issue or name>...` / `pend <issue or name>...` | "〜を優先に", "〜は後回し" | `mayor.sh priority`, then the Priority section's follow-ups |
| `status` | "commander の様子は?" | `mayor.sh status`, plus one line per commander that is not idle/acked |
| `restore` | "herdr を再起動した" | Protocol 6 |
| `resume` | "Mayor を引き継いで" | The Handoff steps |

### `todo`

1. Drain the inbox: `mayor.sh new`, process (Protocol 4), `mayor.sh ack <upto>`.
2. `mayor.sh status`. For each focus commander that is `blocked`, not acked, or has
   been asking in its own pane, read it (`herdr agent read <name> --source
   recent-unwrapped --lines 80`) and copy the requests addressed to the human into the
   ledger, marked as transcribed by the Mayor. Commanders sometimes ask in their pane
   instead of the inbox.
3. For items tied to a PR, check `gh pr view <n> -R <repo> --json state`; move merged or
   closed ones to done.
4. Present, focus only (pend too with `--all`): urgent first, then per issue with where
   to go, then a line on cross-issue dependencies (a focus step waiting on a pend
   decision), then one line with the pend count.
5. Ask any focus `confirm` items not asked yet (Protocol 5). Re-arm the watcher first
   if `status` says it stopped.

## Boundaries

- Collect, organize, guide, relay. Do not dispatch work, spawn agents, create
  workspaces, or coordinate commanders with each other. When something seems to affect
  another issue, tell the human instead.
- Never send answer keys into another agent's open question or approval. Summarize it
  and point the human at the pane.
- Relay the human's words verbatim. A relay authorizes internal work only (research,
  planning, notes, issue records, local edits). Outward or hard-to-undo actions (PR
  comments, push, PR create/close, merge, sending outside) still need the human's
  direct confirmation in the commander's own pane, because a relay is hearsay to that
  commander. Human-only operations (apply and the like) stay with the human.
- Keep concrete sensitive values (IDs, CIDRs, account IDs, secrets) out of the ledger.

## Protocol 0: Take the name

```bash
herdr agent rename "$HERDR_PANE_ID" mayor && herdr pane rename "$HERDR_PANE_ID" mayor
herdr agent get mayor | jq -r .result.agent.pane_id   # must equal $HERDR_PANE_ID
```

If `mayor` is held by a live predecessor, stop and ask the human which one stays.
In a single-pane workspace whose label was never set, renaming the pane also renames
the workspace in the sidebar; that is expected for the Mayor's own workspace.

## Protocol 1: State and roster

1. `$S/mayor.sh init --ledger <path>`. Ask the human where the ledger note lives only
   if no path is configured; create it from `references/ledger-template.md`.
2. `$S/mayor.sh survey` lists every pane with workspace, agent name, label, kind, status.
3. Pick one commander per issue workspace: the root agent the human talks to, usually
   a `*-cmd` name or the workspace's first agent pane. Skip workers, reviewers, and
   workspaces that are not issues (dotfiles, scratch, home). Read a pane with
   `herdr agent read <pane> --source visible` when the role is unclear.
4. Give every chosen commander a name, keeping name and label identical:
   - a label exists but the name is gone (session restart): restore the label as the name;
   - neither exists: derive a short topic name ending in `-cmd`.
   `herdr agent rename <pane> <name> && herdr pane rename <pane> <name>`, then verify
   `herdr agent get <name>` resolves to that pane.
5. Write `$MAYOR_HOME/roster.tsv` (`pane_id<TAB>name<TAB>issue<TAB>workspace label<TAB>priority`).
   Record workspaces with no live agent in the ledger section for them; do not watch them.

## Protocol 2: Brief the commanders

Send each commander the brief once, through the relay helper:

```bash
$S/mayor.sh relay <name> "[mayor から] この herdr session に Mayor (herdr 名 mayor) が入りました (human の依頼)。~/.claude/skills/herdr-mayor/references/commander-brief.md を読んで、以後それに従ってください。あなたの herdr 名は <name>、担当 issue は <issue> として扱います。読んだら、今ある human todo を report.sh で 1 件ずつ書き、最後に --kind ack を 1 行書いてください (--what に件数)。返信は不要です。"
```

- Exit 3 (`blocked`): the commander has a question open. Note it, brief it later.
- Exit 4 (`busy`): retry after the current turn settles.
- A commander may ask its own human to confirm adopting the protocol. That is fine; it
  appears as `blocked` and the human answers there.
Track who has acked; re-brief anyone silent after their next settled state.

## Protocol 3: Watch

Arm the watcher in the background and let its exit wake the session:

```bash
$S/mayor.sh watch      # run_in_background; exits with one event per line
```

Events: `inbox N new line(s)`, `blocked <pane> <name>`, `gone <pane> <name>`,
`name_lost <pane> <name>`. The watcher already sends a Herdr notification for
`urgent=yes` lines and newly blocked commanders, and saves the agent names on every
loop (Protocol 6). On each wake:

1. `inbox`: `$S/mayor.sh new`, process every line (Protocol 4), then
   `$S/mayor.sh ack <upto>` with the `upto` it printed.
2. `blocked`: `herdr agent read <pane> --source visible --lines 60`, summarize the
   question or approval in one or two lines, put it in the ledger as an `answer` item
   pointing at the pane, and tell the human where to go.
3. `name_lost`: restore name and label from the roster (Protocol 1 step 4). For
   `mayor` itself, rerun Protocol 0.
4. `gone`: the commander exited. Move its workspace to the no-agent section and mark its
   open items unattended. Keep its roster row: the condition stays in `seen`, so it does
   not fire again, and an agent restarted in that pane shows up as `name_lost`, which
   restores the name.
5. Re-arm the watcher **before** any native ask, so events keep accumulating while
   the human answers.

## Priority: focus and pend

The human may name the issues to focus on. Record it in the roster's fifth column
(`focus` or `pend`; empty means `focus`), not in the issue tracker unless asked:
`$S/mayor.sh priority <name or issue> focus|pend`. An issue also matches its children
(`0hd` covers `0hd.1.8`); name a commander to change only that one.

- `focus`: escalate as usual (present, notify, ask `confirm` items).
- `pend`: keep recording its items in a "保留" section of the ledger, but do not present
  them, ask its `confirm` items, or guide the human to its panes. The watcher already
  ignores a pend commander's `blocked` state and only notifies urgent lines from focus
  senders; `mayor.sh new` prefixes every line with its sender's priority.
- An `urgent=yes` line from a pend issue: read it, and escalate it only when it concerns
  a production outage or production impact (notify with `herdr notification show`
  yourself). Hold every other pend urgent.
- Tell each pend commander once, with a `[mayor から]` message, that its human todos are
  held, so it does not wait on an answer that will not come soon.
- When priorities change, move items between the ledger sections and ask the newly
  focused `confirm` items.

## Protocol 4: Keep the ledger

The ledger note is the source of truth for the human; the inbox is only a queue.

- Inbox fields are ` | `-separated `key=value` pairs (`from issue key kind urgent where
  what done_when`, plus `q options rec` for `confirm`).
- New item: add under its issue; urgent ones also go in the urgent table.
  `done` / `cancel`: move the item with that key to the done section.
  `ack`: mark the commander briefed; no item.
- Order the human-facing view: urgent first, then items that block an agent
  (`answer`, `confirm`, `approve`), then `operate` / `merge`, then `review` /
  `external` / `other`.
- After each wake, report to the human only what changed, grouped by issue, each with
  where to go. Show the full ledger when asked.

## Protocol 5: Ask and relay

- `confirm` items: ask the human with native ask (up to four per call, the commander's
  options, recommended first). Relay the answer:
  `$S/mayor.sh relay <name> "[mayor 中継] human: <key> への回答: <選んだ選択肢と、添えられた文言そのまま>"`.
- A human report or instruction: find the owner from the ledger or roster (ask with
  native ask only if two commanders fit), then relay
  `"[mayor 中継] human: <原文>"`. Never paraphrase into a stronger instruction.
- On exit 3 or 4, keep the message pending in the ledger and resend after the next
  settled state. Tell the human it is pending.
- Prefix the Mayor's own messages with `[mayor から]` so commanders can tell them
  from relays.

## Protocol 6: Recover after a herdr restart

A `herdr server stop` or an OS reboot keeps workspace, tab and pane labels, but every
agent process and agent name is gone. `$MAYOR_HOME/herdr-names.tsv` is the copy that
survives: the watcher merges the live names of **all** named agents (workers and
reviewers too) into it on every loop, and `$S/mayor.sh snapshot` does it on demand.
It only adds or updates rows, so a snapshot taken while nothing has a name cannot wipe it.

Signs: many `gone` / `name_lost` events at once, or most commanders `agent_not_found`.

1. Protocol 0 for the Mayor itself.
2. `$S/mayor.sh restore` (dry run). It matches each saved name to a pane by label,
   then by the old pane id in the same workspace, then by the only unnamed agent with
   the same workspace and cwd. Lines: `rename` (an unnamed agent is back in the matched
   pane), `start` (pane found, no agent; carries `claude --resume <session>` when
   known), `missing` / `conflict` (no unique pane).
3. If every actionable line is `rename`, run `$S/mayor.sh restore --apply`; it also
   moves the roster's pane ids to where the names now live. Otherwise show the plan to
   the human first.
4. Put each `start` line in the ledger as an `operate` item for the human. Do not start
   agents yourself.
5. A commander resumed into its old session keeps the brief; a fresh one needs Protocol 2.
6. `$S/mayor.sh forget <name>` for names that will not come back, so restore stops
   listing them.

## Handoff

Everything durable is in `$MAYOR_HOME` and the ledger note. A successor session runs
Protocol 0 after the predecessor releases `mayor` (after a reboot, Protocol 6 first),
reads the config, roster and ledger, runs `$S/mayor.sh new` for anything unprocessed,
and re-arms the watcher.

## Failure modes

| Symptom | Cause | Response |
|---|---|---|
| A commander's question got stray text | Prompt typed while it was asking | Only send through `mayor.sh relay`; it refuses on `blocked` |
| `agent_not_found` for a known commander | Session restart dropped the name; the label stays | Restore from roster; verify with `agent get` |
| Most commanders `gone` or nameless at once | herdr server stop or OS reboot | Protocol 6 |
| A commander reports through `herdr agent prompt mayor` | `report.sh` was not permitted | Treat it like an inbox line and write it into the ledger yourself |
| Notes say an agent is gone | Note fields are not liveness | Decide liveness from `herdr agent list` only |
| Watcher refuses to start | Another watcher holds `watch.pid` | Leave it running, or stop that process first |
