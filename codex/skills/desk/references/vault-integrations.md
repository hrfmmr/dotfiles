# Vault integrations

## Notification (terminal-notifier + Advanced URI)

```bash
VAULT_NAME=$(basename "$PWD")
NOW=$(date '+%Y-%m-%d %H:%M:%S')
ENCODED_FILEPATH=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<task-note-name>")
ENCODED_HEADING=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "Turn-N")
terminal-notifier \
  -title "desk: <task-name>" \
  -message "[${NOW}] Turn-N: <status summary>" \
  -open "obsidian://adv-uri?vault=${VAULT_NAME}&filepath=${ENCODED_FILEPATH}&heading=${ENCODED_HEADING}"
```

- `-message` must include a `[yyyy-MM-dd HH:MM:SS]` timestamp and the target `Turn-N`.
- `-open` uses `obsidian://adv-uri` (Advanced URI plugin) with `heading=Turn-N` to jump directly to the target Turn section. The heading value must omit the `#` prefix (e.g., `Turn-3` not `# Turn-3`).
- **All query parameter values must be percent-encoded** via `urllib.parse.quote(value, safe='')`. Task names containing Japanese, spaces, or parentheses will break `NSURL` parsing if left raw.
- Requires the [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) plugin. The native `obsidian://open` does not support heading navigation.

## Dataview queries

### Pending Input View

Cross-note query aggregating `input:: pending`:

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  input AS "Input Status",
  current_status_summary AS "Summary"
FROM ""
WHERE input = "pending"
SORT file.mtime DESC
```

### Active Tasks

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  status AS "Status",
  task_type AS "Type",
  current_status_summary AS "Summary"
FROM ""
WHERE status AND status != "done" AND status != "not_started"
SORT file.mtime DESC
```
