# Reader comments: watch, collect, and answer

After delivery the reader reads the note and writes comments in it. Watch the note, collect each new comment, and answer or apply it in the note. Follow the `bump` skill where it applies (the `.o0:` token, the nearest-content target, the settle window of at least 60 seconds, keeping the request text visible, the derived-note rule), with the grasp-specific differences listed at the end.

## Comment syntax

- A comment is a line that contains `.o0:` followed by request text. The token may follow whitespace, a list marker, or blockquote prefixes (`>`). The target is the nearest content above it.
- Not comments: a bare `.o0:` with no text yet; lines inside fenced code blocks (any fence length, also inside blockquotes and list items); `.o0:` inside inline code spans. A reader may write a follow-up `.o0:` inside or below an `AI Follow-up` reply; it is a new comment.
- The watcher counts comments by request text. The `.o0:` lines present at delivery (the agent's own hook requests) form the baseline. A reader activates a hook by rewriting its request, or by adding an `.o0:` line below it (copying the same text also counts, because the count rises).

## State

- `scripts/watch_comments.py` keeps one state file per note at `~/.cache/grasp-watch/<hash of the note's real path>.json` (outside the vault, so it survives the session). Pass `--state` to override it, and pass the old state file with `--state` after the note is renamed.
- The baseline stays as recorded. Acknowledged counts shrink when lines leave the note, so a comment you replaced cannot trigger again, and a comment the reader writes again later with the same text is new.
- When the count of a request text rises, the watcher lists every line with that text; decide which one is the reader's new line (it may sit above or below the hook it copies).
- Exit codes: 0 new comments (or a successful `--baseline`/`--ack`), 1 `NO_NEW_COMMENTS`, 2 `WATCH_TIMEOUT`, 3 `NOTE_MISSING`, 4 `STATE_MISSING`, 5 `STATE_EXISTS`.

## Lifetime of the watch

1. At delivery (Phase 6), record the baseline once: `python3 scripts/watch_comments.py NOTE.md --baseline`. It refuses to overwrite an existing state (`STATE_EXISTS`); re-baselining would hide comments, so after a diff-mode re-delivery keep the existing state. Use `--force` only for a note whose comments are all handled.
2. Start the watch in the background: `python3 scripts/watch_comments.py NOTE.md --quiet 60 --interval 10`. In Claude Code, run it with the shell tool's background mode; its exit notifies you. Where no background notification exists (for example Codex), run `--once` at each turn or ask the reader to say "commented to grasp note".
3. The watch exits once with `NEW_O0_COMMENTS` and one row per new comment (`<key>\tL<line>\t<heading>\t<text>`) after the note has stayed unchanged for `--quiet` seconds (at least 60; raise it to half the vault's auto-commit interval when that is longer). Partial typing therefore does not trigger it.
4. Process the batch (below). Restart the watch as soon as each comment of the batch has its reply line in place, including a "Received" reply for a request that goes to the owner flow; do not wait for the owner flow to finish.
5. If you write `.o0:` lines yourself after delivery (for example a new hook), run `--list`, then `--ack <key>` for exactly those keys. Use `--ack <key>` also for a comment you defer while asking the reader. Never acknowledge keys you did not handle.
6. "commented to grasp note" from the reader is a manual trigger: run `python3 scripts/watch_comments.py NOTE.md --once` (same as `--list`) and process what it lists (`NO_NEW_COMMENTS`, exit 1, means nothing is pending).
7. Stop when the reader approves the underlying artifact (in the chat or in a comment) or the session ends: stop the background task. `WATCH_TIMEOUT` (default 12 hours), `NOTE_MISSING`, or `STATE_MISSING` also ends it; restart only while the reader is still reviewing (for `STATE_MISSING`, check the path before baselining again).

## Processing a batch

Classify each comment, then act:

| Kind | Example | Action |
|---|---|---|
| Edit to the note | "this sentence is wrong", "add a diagram here" | Apply it to the note. Run Gate B on the changed part. |
| Question about the note or the design as written | "why X and not Y?" | Answer from the sources, with provenance labels. |
| Request to change the underlying design, plan, or code | "can we automate this renewal?", "consider option Z" | Do not change the artifact from the note. Reply that the request was received and how it is being examined, route it to the artifact's owner flow (for a commander: the worker and reviewer loop, plus fact checks), and return with the result. |
| Approval or a closing remark | "OK, approved", "no more comments" | Reply briefly, record it in the chat and the owner's log, and stop the watch. |
| Ambiguous (several readings) | | Ask the reader before acting (native ask with a recommended option). `--ack` its key meanwhile. |

Changes the agent proposes on its own still go through the usual approval; a reader's comment is itself the go-ahead for that comment only.

## Reply shape

Replace the comment line with a folded callout that keeps the reader's request text in its title. Never leave the `.o0:` token or any status marker in the note; never drop the request text.

```markdown
> [!note]- AI Follow-up: <request text>
> <answer, or "Applied: <what changed, where>", or "Received: <how it is being examined>; the result will be written here">
```

- Keep the comment's own blockquote depth and add one level: a comment written as `> .o0: …` inside a hook or a dialogue callout gets `> > [!note]- AI Follow-up: …` with `> > ` on every reply line, so the outer callout stays intact.
- Long answers (more than about 8 lines, or worth revisiting on their own) go to a derived note in the vault root, following bump's derived-note shape. Put the link inside the same folded callout (`> [!note]- AI Follow-up: <request text>`, then `> → [[<derived note>]]`), not as a bare link line, so every reply has one shape.
- When an owner-flow result arrives, update the same callout (keep its title) and the parts of the note the result changes. Re-run `check_note.py` and `render_mermaid.py` for the changed parts, and the independent fact check for substantive additions.
- If the request cannot be done, use `> [!warning]- AI Follow-up blocked: <request text>` with the reason.
- Do not edit human prose outside the comment line and the parts the comment asked to change. Write `.o0:` in replies only inside inline code, because the watcher reads reply callouts too (so it can catch the reader's follow-ups there).
- After a batch, notify the reader with `terminal-notifier` when it is installed (bump's `references/notification.md`); start it detached (`… >/dev/null 2>&1 &`), because it can wait for a click and block the shell. Say in the chat which comments were handled and how.

## Differences from bump

| | bump | grasp comment watch |
|---|---|---|
| Trigger | post-commit hook pipeline or `$bump` | background watcher started at delivery, or "commented to grasp note" |
| State | `.bump/queue/` in the vault | `~/.cache/grasp-watch/` outside the vault |
| Inline reply | `> [!note] AI Follow-up: …` (open) | `> [!note]- AI Follow-up: …` (folded, at the comment's depth + 1) |
| Derived-note reply | bare `→ [[…]] — <request text>` line | the link inside the folded callout |
| Blocked reply | `> [!warning] Bump blocked: …` | `> [!warning]- AI Follow-up blocked: …` |
| Fenced code | not specified | ignored by the watcher |
| Design requests | answered in place | routed to the artifact's owner flow; the result returns to the same callout |
