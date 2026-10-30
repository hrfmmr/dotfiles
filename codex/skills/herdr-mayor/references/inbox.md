# Plannotator Inbox: the Mayor's side

Focus commanders with the Inbox tool ask and report to the human in the Plannotator
Inbox. The human answers there, and each answer goes back only to the session that
asked. The Mayor does not carry those answers: it gives every commander its own project,
watches the Inbox to know where each issue stands, writes its own summary in its own
project, and relays only what the human says to the Mayor. The commanders' side is
`commander-brief.md`.

## Projects: one per workspace

The Inbox groups threads by the `project_path` a sender passes. A folder outside git
becomes a project named after the folder; a folder inside a repository (the vault
included) merges into that repository's project. So each commander gets a folder under
`$MAYOR_HOME/inbox-projects/`, named `<issue>--<title>`, and passes its absolute path on
every send.

```bash
$S/mayor.sh project <name> <issue> [title]   # prints the folder's absolute path
```

- It creates the folder, records it as the agent's last row in `inbox-projects.tsv`
  (`agent<TAB>issue<TAB>folder`), and sets the roster issue. The title defaults to the
  agent's workspace label without its ID prefix (`/` becomes `・`); pass a title when the
  label does not start with the ID or `<provisional ID>--`.
- Run it only once the issue ID is fixed. A task that gets a tracker issue starts under
  a provisional name; a folder created under that name would soon be abandoned. A task
  without a tracker issue keeps its provisional name as the ID.
- The ID changes (a provisional ID filed in the tracker): run `project` with the new ID
  and tell the commander. It starts new threads in the new project and finishes old
  threads in the old one. The old row stays, so reads still cover the old project; drop
  that row by hand once its threads are all resolved. A title change alone (the
  workspace was renamed) changes nothing: the Inbox cannot rename a project, and
  following every rename would strand threads and drafts.
- Never delete a folder, project or thread, and never edit `~/.plannotator/inbox`. An
  emptied project is the human's to remove in the Inbox Settings; mention it to them.
- The Mayor's own project is `mayor--Mayor の全体の状況`
  (`$S/mayor.sh project mayor mayor "Mayor の全体の状況"`).

## Moving a running commander onto the Inbox

Tools reach only sessions started after the tool was connected, so a commander whose
session predates it must restart into the same session:

```bash
$S/switch-to-inbox.sh <name> <issue>
```

- It takes the folder from the commander's row in `inbox-projects.tsv` for that issue
  (exit 2 when there is none: run `project` first). It refuses (exit 3) while the
  commander is working, shows a question, or holds a human draft. If background work
  blocks the exit, it cancels the exit and refuses too.
- It reads model and effort from the screen's status line or else the transcript,
  restarts with `--resume <session id>` (never `--continue`, which opens the newest
  session in that cwd, possibly another commander's), checks that pane and session are
  unchanged, and relays the switch notice. Exit 4: restarted but the notice was not sent;
  relay it yourself.
- Retry an exit 3 once the commander settles. With `STOP_BG=1` it stops background work
  (hunk comment watchers, PR watches) instead, and the notice asks the commander to
  re-arm what it needs. Waiting does not clear `kind=<not claude>`, `no session id`,
  `unknown model` or `effort not shown`: tell the human, who restarts that commander.
- Exit 1 (`FAIL`: still running after `/exit`, or a different pane or session after the
  restart): the commander may be down or on another session. Read its pane now and tell
  the human.
- A new commander from `intake` starts with the tool and needs none of this.

## Watching

```bash
MAYOR_SESSION=<this Mayor's session id> $S/watch-plannotator.sh [timeout_sec=1800] [interval_sec=30]
```

Run it through the background tool beside `mayor.sh watch`; the file inbox still carries
pend and tool-less commanders and the notices addressed to the Mayor. It exits with
`plannotator inbox changed` and one line per new message from another session or per
answer the human sent (project, thread, author, no bodies), or with `timeout: ...`.
Record rewrites (read marks, draft picks) are ignored. The project column is the Inbox's
internal slug (for example `u3112-63b455`), not the folder name; match it to a folder
in `inbox-projects.tsv` and read by that folder.

- Run exactly one. Before re-arming, confirm the previous run has exited: two runs race
  for the read marks and drop or repeat events. Check by process, not by script path: a
  run started from an older copy of the script uses the same read marks.
- Never delete or rebuild `plannotator-seen.tsv` or `plannotator-seen-ids.txt`. A rebuild
  counts the answers sent meanwhile as read, and they are never reported.
- `MAYOR_SESSION` keeps the Mayor's own messages from waking it. After a handoff, use
  the new session's id.
- After the first change it waits `SETTLE` seconds (45; 0 reports at once), so a run of
  answers wakes the Mayor once. While commanders re-post many items, read each project
  once after it settles rather than per event.
- On completion, read the changed threads, update the summary (below), then re-arm.

## Reading

Read every row of a focus agent in `inbox-projects.tsv`, older projects included.
`read_thread` with no id, `asked_by: "anyone"` and a project folder as `project_path`
lists that project's open threads with their open questions. Read a thread with its
`thread_id` (and the same `project_path`) for the questions and action items still
waiting. Those are the human's turn; place them as `Inbox「<folder name>」›「<thread
name>」` in human-facing lines. Reading marks nothing read for the human.

## The Mayor's summary

Keep one thread, `Mayor: 全体の状況`, in the Mayor's project. Add a new message there
whenever an item enters or leaves the human's turn, a cross-issue finding appears (a
dependency, a moved deadline), or a new commander starts. A report that only read a
commander's question, or found no change, stays in the chat. Holding the summary back
for changes judged minor once left it silent for five hours while a deadline moved.
Items of an issue whose commander is gone go into the summary too, since nobody else
posts them.
The Mayor's own questions to the human (about operating the Mayor) also go to its
project, as `:::question` blocks.

## Answers that arrive outside the Inbox

The human also answers in the Mayor's chat or a commander's pane. The Mayor cannot
answer an Inbox question for the human. When a relay answers an Inbox item, add the
project, thread and question (`<message id>/<key>`) it answers; when it is a new
request, say that it answers no Inbox item. The commander then writes the answer's route
and wording into its thread and withdraws the question, or marks an action item done
once it has seen it done (`commander-brief.md`, section 2).

## Failure modes

| Symptom | Cause | Response |
|---|---|---|
| A human's Inbox answer never reached the Mayor | The read marks were rebuilt and counted it as read | Never rebuild `plannotator-seen*`; read the projects' threads now |
| Inbox events are missed or repeated | Two Inbox watchers ran at once | Keep one; confirm the previous run exited before re-arming |
| The watcher wakes on the Mayor's own messages | `MAYOR_SESSION` names an earlier Mayor session | Restart the watcher with the current session id |
| A commander's thread sits in its repo's or the vault's project | It sent without `project_path`, or with a folder inside git | Nothing is lost (the watcher reads every project); tell it the absolute folder from `inbox-projects.tsv` |
| An Inbox question stays open after the human answered | The answer came by chat or pane | Relay it with project, thread and `<message id>/<key>`; the commander records it and withdraws the question |
| The Inbox shows nothing of what the Mayor told the human | The Mayor skipped its summary for changes it judged minor | Add a summary message whenever the human's turn changes |
| A broadcast came back with a reply from every commander | It did not say 返信不要 | End every broadcast with 返信不要 |
| `switch-to-inbox.sh` keeps exiting 3 | The commander is busy, asking, or holds a draft or background work; or a cause that waiting does not clear (see above) | Retry when it settles; `STOP_BG=1` only when stopping its background work is acceptable; otherwise tell the human |
| The human answered in the thread of a commander that is gone | The answer returns only to that session | Tell the human; once the commander is resumed in the same session (Protocol 6), ask it to read its threads |
