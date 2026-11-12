# pr-status: files and formats

All files live in `$MAYOR_HOME/pr-status/` (override with `PR_STATUS_DIR`), outside any
git repository. Company-specific values (channels, repos, folder names) go only here.

## prs.tsv (the PR table)

One PR per line, tab-separated, first line a `#` header. Written only through
`pr_status.py table upsert` / `ingest` (and `run`, which adds attached PRs it has not
seen); do not edit by hand while a run is going.

| Column | Meaning |
|---|---|
| `pr` | `owner/repo#n` (a GitHub URL is normalized to this) |
| `commander` | herdr name of the owning commander |
| `issue` | the commander's issue ID |
| `local_state` | `none`, `agent-review`, `apply-pending`, `applied`, `closed` |
| `slack_url` | permalink of the Slack review-request message (reminders reply in its thread) |
| `reminders` | reminders posted so far |
| `last_reminder_at` | UTC time of the last reminder (restarts the stall clock) |
| `asked_at` | UTC time the last request/reminder question was sent to the human |
| `ask_ref` | Inbox message id of that question while it is unanswered |
| `updated_at` | UTC time of the last change to the row |

`table upsert` flags: `--commander`, `--issue`, `--local`, `--slack`, `--reminded`
(count +1, set `last_reminder_at`, clear the question), `--asked <message id>`,
`--answered` (clear `ask_ref`, keep `asked_at`), `--clear-asked`.

## report.sh `kind=pr` lines

`report.sh --issue <id> --kind pr --pr <owner/repo#n|url> [--state <s>] [--slack <url>] [--what <text>]`
appends `... | kind=pr | ... | pr=<ref> | state=<s> | slack=<url>`. `ingest` maps `state`:

| `state=` | table `local_state` |
|---|---|
| `opened` | `none` (creates the row) |
| `agent-review` | `agent-review` |
| `agent-review-done` | `none` |
| `apply-pending` | `apply-pending` |
| `applied` | `applied` |
| `closed` | `closed` |

## config

`key=value` lines, `#` comments; see `assets/config.example` for every key and default.

## holidays file

Path from `holidays=`. One date per line as `YYYY-MM-DD`, anything after the date is a
comment, `#` lines ignored. Weekends are always non-business days.

```
2027-01-01 New Year
2027-01-11
```

## Other files

- `snapshot.json`: per PR `{state, marks, reminders}` from the last run; the diff base.
- `out/`: the last run's `result.json`, `list.md`, `send-list.json` (only when it should
  be sent) and `ask-<pr>.json` (send_message payloads). Rewritten on every run.
