# Plannotator Inbox: the Mayor's side

Focus commanders with the Inbox tool ask and report to the human in the Plannotator
Inbox. The human answers there, and each answer goes back only to the session that
asked. The Mayor does not carry those answers (except one that never arrives, below): it
gives every commander its own project, watches the Inbox to know where each issue stands,
writes its own summary, Board cards and status threads in its own project, and relays
only what the human says to the Mayor. The commanders' side is `commander-brief.md`.

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
- On completion, read the changed threads, check that the human's messages reached their
  commanders and look for picked answers (both below), update the summary (below), then
  re-arm.

## Reading

Read every row of a focus agent in `inbox-projects.tsv`, older projects included.
`read_thread` with no id, `asked_by: "anyone"` and a project folder as `project_path`
lists that project's open threads with their open questions. Read a thread with its
`thread_id` (and the same `project_path`) for the questions and action items still
waiting. Those are the human's turn; place them as `Inbox「<folder name>」›「<thread
name>」` in human-facing lines. Reading marks nothing read for the human.

`read_thread` shows a question the human chose but did not send as `picked`. Nothing
reaches the commander until it is sent, and the watcher never reports a pick (a pick only
rewrites a record). So on every watcher completion, and in `todo`, look for `picked`
questions in every focus project. Tell the human once per picked question, in the
summary (a summary trigger of its own, below), and note in the ledger that it was told:
`選んだまま未送信: <place> の <question> は「<choice>」`. `todo` lists them apart from
open questions.

## Checking that the human's messages arrived

The plugin hands a human's Inbox message (an answer, a text reply, an annotation) to the
commander's session when it is idle. One sent while the commander works waits for the
turn to end, unless the human pressed Send now, which puts it into the running turn. On
2026-10-30 three such messages had still not arrived after the turn ended, and the
commanders kept waiting for what they had been given. So check each message the human
sent in a commander's thread (not in the Mayor's own project). One send is one message:
its `message` line by `person` and its `answer-sent` lines share the project and `at=`,
and `reply=` is its id. A `message` line alone (a text reply or annotation) prints no id;
find it with `read_thread`.

1. If the commander is idle, read its pane now. If it is working, note the pending check
   in the ledger and check once the turn ends: run `herdr agent wait <name> --until idle
   --until done --until blocked --timeout 1800000` through the background tool, or check
   at the next wake or `todo`. When the wait ends before the message shows, look again a
   minute later.
2. It got the message when the pane shows `Plannotator Inbox: <subject> (<message id>)`
   or `Plannotator Inbox: the person's reply (…) went into this turn.` (`message` in
   place of `reply` for a message that answers no question). A commander that
   merely works on the matter likely got it; confirm when its turn ends. It did not get
   it when, a minute or so after the turn ended, it is still idle or done and its last
   report still waits for that answer or request.
3. Then relay the original with `mayor.sh relay`, taking the text from `read_thread`
   (`expand` the message): `[mayor 中継] Inbox で届かなかった human のメッセージ
   (Inbox「<folder name>」›「<thread name>」、<time>、<message id>、答えなら
   <question message id>/<key>): <原文>`. If the relay is refused (exit 3–5), read the
   pane again before retrying rather than queueing it with `--until-sent`: a late
   delivery could land first. Record the relay in the ledger. The commander answers in
   that thread and treats a later delivery of the same id as the same message
   (`commander-brief.md`, "Mayor から届くもの").

## The Mayor's summary

Keep one thread, `Mayor: 全体の状況`, in the Mayor's project. Add a new message there
whenever an item enters or leaves the human's turn or its action, place or deadline
changes ("When to update" below), a cross-issue finding appears (a
dependency, a moved deadline), a new commander starts, or a question is found picked but
not sent (once per question, "Reading"). A report that only read a
commander's question, or found no change, stays in the chat. Holding the summary back
for changes judged minor once left it silent for five hours while a deadline moved.
Items of an issue whose commander is gone go into the summary too, since nobody else
posts them.
Link each commander thread a message names, at its first mention, so the human opens it
from the summary instead of searching (human request, 2026-11-05):
`[<thread name>](http://localhost:<port>/#thread=<thread id>)`. Copy the URL from the
header of the latest `read_thread` of that thread; the port can change between sessions.
The Mayor's own questions to the human (about operating the Mayor) also go to its
project, as `:::question` blocks.

## The PR status thread

PRs of every commander are listed in one more thread of the Mayor's project, kept by the
`pr-status` skill (its `thread_name`, default `Mayor: PR の状況`), never in the summary
(human, 2026-11-12: PR status there is noise). Commanders attach their PRs to their own
threads and report local state and the Slack review-request URL with `report.sh --kind
pr` (`commander-brief.md`, section 6); the Mayor ingests those lines into the PR table.

- **When:** on every Inbox watcher wake, after the summary, run the skill in a sub-agent
  with `MAYOR_SESSION`. It posts the list only when something changed.
- **Questions:** a stalled review (no review, comment or push for 2 business days) or a
  PR with no reviewer gets a `:::question` there with a draft: 送る / 直して送る /
  送らない. The answer returns to the Mayor. Only on 送る or 直して送る does the Mayor
  post to Slack, and a reminder only as a reply in the recorded review-request thread
  (the skill's "Answers to the questions"). This is the human's check on an outward
  action; a relay or a commander's word never replaces it.
- **Limits:** at most 2 reminders per PR, then 要相談 in the list. A stalled PR with no
  recorded Slack URL is listed in the skill's return: ask its commander for the URL.
- **Backfill:** PRs opened before 2026-11-12 appear once their commanders attach and
  report them; send each focus commander one `[mayor から]` notice asking for that
  (the skill's "Backfill").

## The Board and the status threads

The human goes from the Inbox's Board (one card per issue) to the issue's status thread,
and from there to the thread where they answer: the list, where each issue stands, then
the detail. Before this, nothing said where an issue stood, so the human asked the Mayor
or searched the Inbox, and the search grew with every parallel task (human, 2026-11-05;
the Board has been on since then). Both live in the Mayor's project: a card links only
threads of its own project, and the Mayor writes nowhere else. A reply in a status thread
therefore reaches the Mayor, not the commander, so every status message links the
commander threads where the human answers.

- **Scope:** the focus workspaces the human chose for the Board, starting with the
  busiest; the human may add one (2026-11-05: 0hd, prrev-1104, qml, 3x4, dy5,
  isms-audit-mail). A child issue with its own workspace gets no card of its own: it is
  a row in its parent's status thread (3x4.1 under 3x4, dy5.19 under dy5), and its
  items join the parent card's `--you` (human, 2026-11-05).
- **Who updates:** for now the Mayor updates every card and status thread; they move to
  the commanders once the form settles (the human's choice, 2026-11-05).
  `commander-brief.md` does not cover them yet.

### Cards

One card per Board issue, titled in 2–5 words, linked to its status thread and its PRs.
The column says where the work stands:

| Column | When | Card text |
|---|---|---|
| `in_review` | The human has an item that holds the work | `--you`: the human's items in one line (shown only in this column) |
| `in_progress` | The commander is on the next step | `--say` ends with `あなたの残り: …`, since `--you` is refused here |
| `done` / `dropped` | Shipped / cancelled | `card ship` / `card drop <reason>` |
| `backlog` | The issue is pend | — |

```bash
P="$MAYOR_HOME/inbox-projects/mayor--Mayor の全体の状況"
plannotator card create "<2–5 words>" --project "$P" --column in_review --key mayor-<issue> \
  --thread <status thread id> --ref <owner/repo#n> --say "<where it stands>" --you "<the human's items>"
plannotator card link <crd_id> --project "$P" --ref <owner/repo#n>   # one --ref per call
plannotator card move <crd_id> in_progress --project "$P" --say "<…>。あなたの残り: <…>"
plannotator card say <crd_id> --project "$P" "<where it stands>" --you "<the human's items>"
```

Use the CLI: the Mayor's Inbox tool may have no card action. `--key` makes a create safe
to repeat. More than one `--ref` in a call fails with the usage text; add each further PR
with its own `card link`.

Link a card to its source issue as well as its PRs (human, 2026-11-06): the team tracker
issue the work comes from (`--ref <its URL>`), and a child issue's page too when the card
holds that child. Take the URL from the desk note's `source_issue_link`, the daily note,
or a tracker search by the issue's number; a bd ID is not a source issue. When the work
has no tracker issue (a chat request, a skill change), say so instead of guessing one.

### Status threads

One thread per card, named `<issue>: 現況` (`send_message` with `thread`). On every change,
add one message that rewrites the whole state, never a diff: the newest message is the
whole picture, and the human skips the older ones. Its parts, in this order:

1. `**現況 (<date> <time>)**。最新の 1 通が今の全体像です。` Run `date` first: a time
   written without checking was wrong on 2026-11-05.
2. フェーズ: where the issue stands among its milestones, in a few sentences.
3. あなたの番: each item with its Inbox id (`q-…`, `a-…`) and a link to the thread where
   the human answers it. An item outside the Inbox (a sentence to type in a commander's
   chat, a mail draft) says where it is. Then what is expected to come next.
4. 担当の番: what each commander is doing or waiting on, and whether the Mayor saw it on
   its screen.
5. 子の単位: a table, one row per child issue, PR or part, with its state.
6. 止まっているもの: what waits on what, and why.
7. ノート: attach the issue's desk note (the Inbox shows the file as it is now); say so
   when the issue has none. Attach it for reading only: the human's comments on an
   attachment here reach the Mayor, who must relay them. A file the human will annotate
   (a draft, a reading note) goes out from its commander's own thread, where comments
   reach the commander (human, 2026-11-05, after two relays that day).

Writing one means reading every thread of the issue's projects ("Reading"), so it is also
the recount of the human's turn: on 2026-11-05 it found two dy5 items the Mayor had
stopped counting. Build あなたの番 from those reads, not from the previous message.

### When to update

On every watcher completion, for each Board issue whose projects changed, add the status
message and update its card (`say`, `--you`, column) in the same pass. A card update
notifies nobody: the human hears of a change only from the summary. So add a summary
message whenever the human's turn changes: an item added or done, and also an item whose
action, place or deadline changed while the count stayed the same (on 2026-11-05 a draft
moved from Gmail to vault notes, the count stayed, and the human found it only by
looking). A change on the commander's side alone gets no notice; the Board shows it. The
summary keeps the change notices and the cross-issue matters and links the status thread
it touched; it does not repeat the whole state (human, 2026-11-05). The ledger copies
neither: it keeps only what the Inbox does not hold (SKILL.md, Protocol 4).

## Answers that arrive outside the Inbox

The human also answers in the Mayor's chat or a commander's pane. The Mayor cannot
answer an Inbox question for the human. When a relay answers an Inbox item, add the
project, thread and question (`<message id>/<key>`) it answers; when it is a new
request, say that it answers no Inbox item. The commander then writes the answer's route
and wording into its thread and withdraws the question, or marks an action item done
once it has seen it done (`commander-brief.md`, section 2). An Inbox message that never
reached its commander is not this case: it is already in the Inbox ("Checking that the
human's messages arrived").

## Failure modes

| Symptom | Cause | Response |
|---|---|---|
| A human's Inbox answer never reached the Mayor | The read marks were rebuilt and counted it as read | Never rebuild `plannotator-seen*`; read the projects' threads now |
| Inbox events are missed or repeated | Two Inbox watchers ran at once | Keep one; confirm the previous run exited before re-arming |
| The watcher wakes on the Mayor's own messages | `MAYOR_SESSION` names an earlier Mayor session | Restart the watcher with the current session id |
| A commander's thread sits in its repo's or the vault's project | It sent without `project_path`, or with a folder inside git | Nothing is lost (the watcher reads every project); tell it the absolute folder from `inbox-projects.tsv` |
| An Inbox question stays open after the human answered | The answer came by chat or pane | Relay it with project, thread and `<message id>/<key>`; the commander records it and withdraws the question |
| A commander still waits for an answer or request the human sent in the Inbox | A message sent mid-turn waits for the turn to end, and on 10-30 some had not arrived after it | Check its pane once the turn ends; relay the original with place, time and the human's message id |
| The human thinks a question is answered, but the commander never got it | The choice was picked in the Inbox but not sent; the watcher ignores picks | Look for `picked` questions on every watcher completion and in `todo`; tell the human once in the summary |
| The Inbox shows nothing of what the Mayor told the human | The Mayor skipped its summary for changes it judged minor | Add a summary message whenever the human's turn changes |
| A broadcast came back with a reply from every commander | It did not say 返信不要 | End every broadcast with 返信不要 |
| The human has to hunt for the thread a summary item refers to | The summary named the item without its thread link | Link each thread at its first mention, with the URL from the latest `read_thread` |
| A card's You: opens the status thread, not the place to answer | A card links only threads of the Mayor's project | Link each あなたの番 item of the status message to the thread where it is answered |
| A card shows none of the human's items | It is in `in_progress`, where `--you` is refused | `in_review` while the human holds the work; otherwise `あなたの残り: …` in `--say` |
| `card create` or `card link` prints the usage text | More than one `--ref` in one call | One `--ref` per call; add more with `card link` |
| A status message carries a wrong time | It was written before checking the clock | Run `date` before writing the time |
| The count of the human's turn drifts from the Inbox | It was carried over from the previous message | Rebuild あなたの番 from every thread of the issue's projects each time |
| `switch-to-inbox.sh` keeps exiting 3 | The commander is busy, asking, or holds a draft or background work; or a cause that waiting does not clear (see above) | Retry when it settles; `STOP_BG=1` only when stopping its background work is acceptable; otherwise tell the human |
| The human answered in the thread of a commander that is gone | The answer returns only to that session | Tell the human; once the commander is resumed in the same session (Protocol 6), ask it to read its threads |
