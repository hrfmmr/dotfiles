# Completion Notification

Bump workers fire a `terminal-notifier` notification on completion so the human can jump directly to the AI response in Obsidian.

## Command Template

```bash
VAULT_NAME=$(basename "$PWD")
NOW=$(date '+%Y-%m-%d %H:%M:%S')
ENCODED_FILEPATH=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<note-name>")
ENCODED_HEADING=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<heading>")
terminal-notifier \
  -title "bump: done" \
  -message "[${NOW}] <source-note>: <request-summary>" \
  -open "obsidian://adv-uri?vault=${VAULT_NAME}&filepath=${ENCODED_FILEPATH}&heading=${ENCODED_HEADING}"
```

## Field Rules

| field | value |
|-------|-------|
| `-title` | `"bump: done"` on success, `"bump: blocked"` on failure |
| `-message` | `[yyyy-MM-dd HH:MM:SS] <source note name>: <request text truncated to 60 chars>` |
| `-open` | `obsidian://adv-uri` deep link (see below) |

## Deep Link Construction

Uses the [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) plugin.

### For `inline` response

Link to the source note at the heading or anchor nearest to the AI callout:

```
obsidian://adv-uri?vault=<vault>&filepath=<source-note>&heading=<nearest-heading>
```

If no heading is nearby, omit the `heading` parameter (opens the note at top).

### For `branch` response

Link to the derived note:

```
obsidian://adv-uri?vault=<vault>&filepath=<derived-note-name>
```

## Encoding

All query parameter values must be percent-encoded:

```python
urllib.parse.quote(value, safe='')
```

This is critical for note names containing Japanese, spaces, or parentheses — unencoded values break `NSURL` parsing.

## Graceful Degradation

If `terminal-notifier` is not installed (`command -v terminal-notifier` fails), skip the notification silently. Never fail the bump workflow due to a missing notifier.
