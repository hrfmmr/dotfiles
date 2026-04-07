---
name: bump
description: Handle asynchronous AI follow-up requests embedded in arbitrary Obsidian notes via a marked span plus a compact request block. Use when user says "$bump", wants a highlighted passage explained in place, wants a branch note for a side topic, or needs the marked-note follow-up protocol defined or updated.
---

# bump

## Overview

Treat a marked span in any Obsidian note as a durable follow-up request.
Resolve that request into either an inline answer or a branch note so the main note stays readable while the side topic remains linkable and recoverable.

## Problem Statement

Keep the main line of a note focused while still letting a human ask "what does this part mean?" or "go deeper here" anywhere in the vault.

## Success Criteria

- A request is unambiguous from note text alone.
- The agent can process one pending request without relying on transient chat context.
- The result lands back in the source note as either an inline answer or a Wikilink to a derived note.
- The handled request is visibly marked as complete.

## Request Contract

**Core principle: the note stays clean.** All pipeline metadata lives in `.bump/queue/` — never in the note itself. The only marks the agent writes to the note are the AI response (callout or wikilink).

### Trigger syntax

Only treat a note fragment as a bump request when a `.o0:` token is present:

```markdown
.o0:<space_optional><request>
```

Examples:

```markdown
.o0:ここを噛み砕いて
.o0: ここを噛み砕いて
    - .o0: この部分をもう少し詳しく
```

Position rules:

- `.o0:` does NOT need to start at column 0. It may follow whitespace, list markers (`-`, `*`, `1.`), or blockquote prefixes (`>`).
- The recognizer must match `.o0:` as a **token anywhere on the line**, not as a line-start anchor.
- Everything after `.o0:` (with optional space) up to end-of-line is `request_text`.
- When `.o0:` appears inside a list item, the **target** is the nearest preceding sibling or parent item that contains substantive content.
- Highlighting or quoting without `.o0:` is not a bump request.

### Canonical state lives in `.bump/queue/`

All metadata (`bump_id`, `fingerprint`, `request_text`, `mode`, `status`, timestamps) is stored in the queue JSON file — not in the note. See `references/queue-protocol.md` for the full schema.

The note never contains `bump::*` inline fields. Idempotency relies on:

- `fingerprint` in the queue entry (deduplicates across commits).
- Terminal queue state (`done`/`blocked`) prevents re-dispatch (Layer 4, condition 6).

### Canonicalization responsibility

- **Hook path**: the dispatcher writes canonical metadata to `.bump/queue/` after the stability gate passes. The note is not modified during canonicalization.
- **Manual `$bump` invocation**: the agent reads `.o0:` from the note, creates a queue entry in `.bump/queue/` (or processes directly if queue infrastructure is unavailable), and proceeds to the workflow.

## Invocation

| pattern | behavior |
|---------|----------|
| `$bump <note-path-or-name>` | Read the note, find pending bump requests, and resolve the next actionable one. |
| `$bump` | If a note is already explicit in context, process that note. Otherwise identify the note before proceeding. |
| hook-driven async invocation | A post-commit hook enqueues candidate observations via a recognizer registry, then a dispatcher validates stability and canonicalizes shorthand before launching workers. Each worker is a **background sub-agent** (`run_in_background: true`) that receives a single `bump_id`. Multiple stable candidates are dispatched as **parallel sub-agents** (one per `bump_id`). See `.plans/obsidian-cow-bump-hook.md` for the full pipeline design. |

This skill is not limited to `desk` task notes. If the source note happens to be a `desk` note, treat the bump as a side thread rather than as a new main-thread Turn.

## Hook Detection Guardrails

Hook-driven invocation must pass five layers before a worker launches. Each layer targets a specific false-positive threat.

For detailed schemas see `references/candidate-ast.md`, `references/queue-protocol.md`, and `references/canonicalization-transaction.md`.

### Recognizer Registry

Trigger syntax is registered as pluggable parser adapters. The hook never hard-codes `.o0:` or any single syntax; it consumes only the Candidate AST contract.

- Initial adapters: canonical block (`bump:: pending`), shorthand (`.o0:`).
- Future candidates: callout-based, HTML comment, code fence metadata.
- Input contract: the registry receives `changed_note_paths: list[str]` and scans only those notes.

### Layer 1: Changed-note scoping

Scan only notes whose paths appear in the commit diff (`changed_note_paths`). Never scan unchanged notes. This prevents historical `.o0:` thought markers from becoming actionable.

### Layer 2: Completion predicate

A candidate is complete only when `request_text` is non-empty AND the target locator is resolvable. Incomplete candidates (e.g. bare `.o0:` with no request text) remain queued as `seen` and are never dispatched.

### Layer 3: Settle window

Do not dispatch until `stable_after` has elapsed: `max(60s, auto_commit_interval / 2)`. The value is read from `.bump/config.yaml` (`settle_window_sec` key; falls back to the formula above). If the source note is modified again before the window expires, reset `stable_after`. This absorbs partial input captured by obsidian-git auto-commit.

### Layer 4: Current-state revalidation

Before canonicalization, re-run the recognizer on the source note. All six conditions must pass:

1. Source note still exists.
2. Trigger syntax is still present in the note.
3. Recognizer re-execution yields the same `fingerprint`.
4. `request_text` is non-empty.
5. `target_locator` is still resolvable.
6. No terminal-state queue entry with the same `fingerprint` exists.

If any condition fails, discard the queue entry.

### Layer 5: Canonicalization and idempotent dispatch

Canonicalization writes canonical metadata to the queue entry (not to the note) via a compare-and-swap transaction (see `references/canonicalization-transaction.md`):

1. Acquire `flock`-based advisory lock on `.bump/runtime/<note-path-hash>.lock`.
2. Re-read note, verify `fingerprint` (`.o0:` token) is still present.
3. Write canonical fields (`bump_id`, `request_text`, `mode`, etc.) to the queue JSON entry. **Do not modify the note.**
4. On lock failure or CAS mismatch: revert queue entry to `seen` and retry next cycle.

After canonicalization, the dispatcher launches a worker only when `bump_id` is not already active. `fingerprint` deduplicates across commits; `bump_id` + `flock` lock ensures at most one concurrent worker per request.

### Dry-run mode

Run the hook pipeline against `HEAD~1..HEAD` without mutating notes or queue state. Print candidate detection, stability decisions, and would-be dispatches to stdout. Useful for validating recognizer changes and debugging false positives.

### Runtime state

All hook runtime state lives under `.bump/` (excluded from vault search via `.gitignore` and Obsidian excluded-files setting):

- `.bump/queue/` — queued candidate observations (one JSON file per candidate)
- `.bump/runtime/<bump_id>.lock` — `flock` advisory locks for active workers
- `.bump/log/events.jsonl` — audit trail for debugging
- `.bump/config.yaml` — hook configuration (e.g. `settle_window_sec`, `auto_commit_interval_sec`)

## Worker Execution Policy

### Async sub-agent spawn

Each dispatched `bump_id` is processed by a **dedicated background sub-agent** (`Agent` tool with `run_in_background: true`). The dispatcher spawns one sub-agent per stable candidate.

When multiple candidates are stable simultaneously, the dispatcher launches them as **parallel sub-agents in a single message** (multiple `Agent` tool calls). This ensures:

- Independent bump requests do not serialize behind each other.
- Each worker has its own context window and cannot interfere with another worker's note edits.
- The dispatcher remains free to process the next dispatch cycle.

### Worker contract

Each sub-agent receives:

- `bump_id` and `source_note_path`
- The full bump skill prompt (this SKILL.md)
- Instruction to process exactly one `bump_id`, write the result, fire the completion notification, and terminate.

The sub-agent must:

1. Acquire `flock` lock on `.bump/runtime/<bump_id>.lock`.
2. Read request metadata from the queue entry (`.bump/queue/<candidate_id>.json`), then read the source note for context.
3. Execute the Workflow (Discover → Decide → Produce → Close The Loop → Notification).
4. Update queue entry to terminal state (`done` or `blocked`).
5. Release lock (automatic on process exit).

## Workflow

### 1. Discover

1. Read the source note and locate each `.o0:` token (may appear anywhere on a line, not only at line start).
2. Match the token to the nearest target content immediately above it (preceding sibling, parent item, or paragraph).
3. Infer context from the target span and surrounding paragraph before asking questions.
4. If multiple pending requests exist, handle the clearest actionable one first unless the caller explicitly asked for all of them.

### 2. Decide Response Shape

Choose `inline` when:

- the answer fits in roughly 4-8 lines,
- the request is local clarification,
- a separate artifact would not be reused later.

Choose `branch` when:

- the request needs multiple sections, examples, or references,
- the answer would clutter the source note,
- the topic should remain linkable and revisitable on its own.

When `bump_mode:: auto`, bias toward `branch` if there is any real risk of polluting the source note.

### 3. Produce The Result

**Principle: replace the `.o0:` line with only the AI response. No `bump::*` metadata in the note.**

For `inline`:

1. **Remove** the `.o0:` line (or the entire line containing the `.o0:` token).
2. Insert a callout in its place:

```markdown
> [!note] AI Follow-up
> <concise explanation>
```

3. Leave the marked target above untouched.

For `branch`:

1. Create a new note in the vault root (see Derived Note Shape below).
2. **Remove** the `.o0:` line and insert a wikilink in its place:

```markdown
→ [[Derived Note Title]]
```

   If the `.o0:` was inside a list item, preserve the list structure:

```markdown
    - → [[Derived Note Title]]
```

3. The derived note records the source note, target excerpt, and request text (see Derived Note Shape).

In both cases, update the queue entry in `.bump/queue/` with `status: done`, `response_at`, and `response_by`.

### 4. Close The Loop

- Never leave a handled `.o0:` line in the note — always replace it with the AI response.
- The human's original request text is preserved in the queue entry and (for branch) in the derived note.
- If you create a derived note, ensure the source note links to it and the derived note links back to the source note.
- If the request cannot be completed, replace the `.o0:` line with a blocked callout:
  ```markdown
  > [!warning] Bump blocked
  > <reason>
  ```
  and set queue status to `blocked`.
- After writing the result, fire a **completion notification** (see below).

### 5. Completion Notification

Fire a `terminal-notifier` notification so the human can jump directly to the AI-written response in Obsidian.

Template (see `references/notification.md` for full spec):

```bash
VAULT_NAME=$(basename "$PWD")
NOW=$(date '+%Y-%m-%d %H:%M:%S')
ENCODED_FILEPATH=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<source-note-name>")
ENCODED_HEADING=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "<target-heading-or-anchor>")
terminal-notifier \
  -title "bump: done" \
  -message "[${NOW}] ${SOURCE_NOTE}: ${REQUEST_SUMMARY}" \
  -open "obsidian://adv-uri?vault=${VAULT_NAME}&filepath=${ENCODED_FILEPATH}&heading=${ENCODED_HEADING}"
```

Rules:

- `-title` is always `"bump: done"` (or `"bump: blocked"` on failure).
- `-message` includes a `[yyyy-MM-dd HH:MM:SS]` timestamp, the source note name, and a truncated request summary (≤60 chars).
- `-open` uses `obsidian://adv-uri` (Advanced URI plugin) to deep-link to the AI response location.
  - For `inline`: link to the heading or nearest anchor above the callout.
  - For `branch`: link to the derived note (`filepath=<derived-note-name>`, no heading).
- **All query parameter values must be percent-encoded** via `urllib.parse.quote(value, safe='')`.
- Notification fires in both manual `$bump` and hook-driven invocations.
- If `terminal-notifier` is not installed, skip silently (do not fail the bump).

## Derived Note Shape

When `branch` is chosen, prefer a compact structure like this:

```markdown
#ai-agent-note

# <Derived Note Title>

Source: [[<source note>]]
Requested from: <quoted or paraphrased target>
Request: <bump_request text>

## Follow-up
<answer>

## Related
- [[<source note>]]
```

Naming rules:

- Respect `bump_title::` if it is set.
- If the source note is a `desk` dialogue note and the marked span clearly belongs to `Turn-N`, prefer a title that preserves the side-thread feel, such as `<source note> - Turn-N.1 - <topic>`.
- Otherwise prefer `<source note> - <short topic>`.

If the source note already carries obvious `#prj-*` or other project-scoping tags that materially help retrieval, preserve that scope in the derived note.

## Guardrails

- Do not treat ordinary `==highlight==` emphasis as a bump request unless `.o0:` is present.
- **Never write `bump::*` inline fields into the note.** All metadata belongs in `.bump/queue/`.
- Do not leave `.o0:` in the note after processing — always replace it with the AI response.
- Do not dump long answers inline when a branch note is cleaner.
- Do not overwrite human prose outside the `.o0:` line and the immediately adjacent AI output.
- Do not create more than one derived note for the same `.o0:` request in a single pass.
- Keep the protocol vault-native: plain Markdown, callouts, and Wikilinks only.
