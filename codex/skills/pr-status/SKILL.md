---
name: pr-status
description: >-
  Keep one Plannotator Inbox thread that lists where every PR of the Herdr Mayor's
  commanders stands (draft, agent reviewing locally, waiting for human review with or
  without a reviewer, changes requested, approved and waiting for merge, merged and
  waiting for apply, CI failing), marks stalled reviews, PRs with no reviewer and PRs
  that need a talk, and asks the human before any Slack review request or reminder is
  posted. Run by the herdr-mayor skill in a sub-agent on each Mayor wake; also use when
  asked for "PR の状況", "PR status across commanders", "which reviews are stalled",
  "/pr-status", or to record a PR's local state, Slack review-request URL or reminder in
  the Mayor's PR table. Requires the Mayor's state dir; never posts to Slack by itself.
---

# pr-status

Show the human, in one dedicated Inbox thread, where every PR of the Mayor's commanders
stands and which reviews have stopped moving, without putting PR detail into the Mayor's
summary thread or the Mayor's context. The deterministic part (collect, classify, diff,
draft) is `scripts/pr_status.py`; the agent sends what it produced and handles answers.

`P=~/.claude/skills/pr-status/scripts/pr_status.py`. State: `$MAYOR_HOME/pr-status/`
(`$MAYOR_HOME` default `~/.local/state/herdr-mayor`). Formats of the table, the config
and the holidays file: `references/formats.md`. Config template: `assets/config.example`.

## Inputs

- Commanders: `$MAYOR_HOME/roster.tsv`; their Inbox folders: `$MAYOR_HOME/inbox-projects.tsv`
  (a roster commander's rows by name or issue, older folders included).
- PRs: the pulls attached to each commander's threads (open threads, and resolved ones
  active within `resolved_lookback_days`), plus every row of the PR table
  `$MAYOR_HOME/pr-status/prs.tsv` whose commander is on the roster.
- Live state: `gh api graphql` per PR (draft, review decision, review requests, reviews,
  comments, last commit and its check rollup, ready-for-review / review-requested /
  force-push events). Bots (`Bot` type, `[bot]`, `ignore_logins`) are not reviewers and
  do not count as activity.
- What GitHub cannot show (agent reviewing locally, apply pending / applied, the Slack
  review-request URL, reminders sent) lives only in the PR table.

Read-only route to the Inbox from a shell (what the script does): `plannotator inbox
call read_thread '{"asked_by":"anyone","project_path":"<folder>","include_resolved":true,"limit":100}'`
lists a project's threads (limit at most 100; `total` says how many exist), and
`plannotator inbox pulls ls <thread_id>` prints `{"thread_id":…,"pulls":[{ref,url,state,…}]}`.
Neither marks anything read. Never run bare `plannotator inbox`: it opens the window and
connects other agents.

## States and marks

One state per PR, first match wins: merged (→ `merge 済み・apply 待ち` when the table says
`apply-pending` or the repo is in `apply_repos` and not `applied`; otherwise done), closed,
draft, CI failing (rollup `FAILURE`/`ERROR`), changes requested, approved, agent reviewing
(table), waiting for human review with a reviewer (GitHub request, a non-author human
review, or a recorded Slack request), waiting with no reviewer.

- 停滞: waiting with a reviewer, and no review, comment, push, ready/request event or
  reminder for `stall_business_days` (2) business days. Slack replies do not count.
  Business time skips weekends and the holidays file.
- レビュアー未定: waiting with no reviewer.
- 要相談: stalled after `max_reminders` (2) reminders. No more reminder drafts.

## Steps (one run)

1. `python3 $P run` (`--dry-run` prints without writing; `--json` for the full result).
   It writes `out/result.json`, `out/list.md`, `out/send-list.json` when anything changed
   since the last snapshot (or `post=always`, or the first run), and one
   `out/ask-<pr>.json` per question due. Then it saves the snapshot.
2. If `out/send-list.json` exists, send it to the dedicated thread:
   `plannotator inbox call --session "$MAYOR_SESSION" send_message - < out/send-list.json`.
   `$MAYOR_SESSION` is the Mayor's session id (the one its Inbox watcher uses), so replies
   reach the Mayor and not this sub-agent. The payload already carries `project_path` (the
   Mayor's Inbox project, from config or the `mayor` row of `inbox-projects.tsv`), the
   thread name (`thread_name`) and an idempotency key. No file means nothing changed:
   send nothing.
3. Send each `out/ask-*.json` the same way, one question per message, then record it:
   `python3 $P table upsert <pr> --asked <message_id from the send result>`.
4. For each `stale_asks` entry (a question still open for a PR that moved on), send a
   short note to the same thread with `supersedes: ["<ask_ref>"]`, then
   `table upsert <pr> --clear-asked`.
5. Return to the Mayor only: changed yes/no, counts per state, the PRs marked 停滞 /
   レビュアー未定 / 要相談, questions sent, `need_slack_url` PRs (stalled, but no Slack
   request URL recorded: the Mayor asks their commanders for it), warnings. Keep titles
   and diffs out of the return.

Run `date` before writing any time by hand. If `--session` is refused, return the paths of
the payload files and let the Mayor send them with its own Inbox tool.

## Answers to the questions (the Mayor does this, not the sub-agent)

The answer returns to the Mayor's session. Read the question message for the PR, the
draft and the target, then:

- 送る / 直して送る: post the draft, or the human's corrected text verbatim, and nothing
  else.
  - Reminder: reply in the original review-request thread only.
    `python3 $P slack-thread <slack_url>` gives `channel` and `thread_ts`; post with the
    Slack tool as a thread reply there. Then `table upsert <pr> --reminded`.
  - First review request: post a new message in `review_channel`, get its permalink, then
    `table upsert <pr> --slack <permalink> --answered`. If `review_channel` is empty, ask
    the owning commander where its reviews are requested before posting.
  - Say in the dedicated thread that it was sent, with the Slack link.
- 送らない: `table upsert <pr> --answered`. It is asked again only after another stall
  period (a first request is not asked again).

## Rules

- Never post to Slack without the human's 送る / 直して送る answer to that exact question
  (MUST). A relay, a commander or an old answer is not that answer.
- Never post a reminder anywhere but the original review-request thread. No URL recorded:
  no reminder (`need_slack_url`).
- At most `max_reminders` reminders per PR; then only the 要相談 mark.
- PR status goes only to the dedicated thread, never into the Mayor's summary thread.
- Read-only on GitHub. Do not add or remove thread pulls; commanders own them.
- Do not contact commanders from the sub-agent; the Mayor relays.

## Recording (the Mayor)

Commanders report PR events with `report.sh --kind pr` (herdr-mayor `commander-brief.md`).
For each `kind=pr` line from `mayor.sh new`, run `python3 $P ingest "<line>"`; it maps
`--state` to the table (`opened`→none, `agent-review`, `agent-review-done`→none,
`apply-pending`, `applied`, `closed`) and records `--slack`. Direct edits:
`python3 $P table upsert <pr> [--commander N --issue I --local S --slack URL]`,
`python3 $P table show`.

## Backfill

PRs opened before this skill are invisible until attached or reported. The Mayor sends each
focus commander one `[mayor から]` notice: attach each PR it opened or owns to its own
Inbox thread (`thread_pulls` add), and report each with `report.sh --kind pr --pr <ref>
--state <local state>` plus `--slack <url>` when a review was requested on Slack. The
next run picks them up.
