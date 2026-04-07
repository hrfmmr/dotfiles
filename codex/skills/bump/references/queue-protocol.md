# Queue Protocol

The bump hook pipeline separates detection from dispatch via a persistent queue under `.bump/queue/`.

## QueuedCandidate Schema

```text
QueuedCandidate:
  candidate_id        # UUID assigned at first enqueue
  fingerprint         # copied from Candidate AST
  source_note_path
  source_syntax
  request_text        # the human's follow-up question or task
  target_locator      # line range or heading anchor of the target span
  target_excerpt      # first ~120 chars of the target for logging
  mode                # "inline" | "branch" | "auto"
  title_hint          # user-specified derived note title or null
  agent_instruction   # extra constraints or null
  bump_id             # assigned at canonicalization
  first_seen_commit   # SHA of the commit that first surfaced this candidate
  last_seen_commit    # SHA of the most recent commit that re-confirmed it
  first_seen_at       # ISO8601 timestamp
  stable_after        # ISO8601 timestamp; dispatch is blocked until this passes
  status              # see Status Transitions below
  response_at         # ISO8601 timestamp; set when worker completes
  response_by         # "ai-agent"
  response_link       # [[Derived Note]] for branch, null for inline
```

## Status Transitions

```
seen ──→ ready ──→ canonicalized ──→ dispatched ──→ done
  │        │            │                │
  │        │            │                └──→ blocked
  │        │            └──→ seen  (CAS failure: retry next cycle)
  │        └──→ seen   (settle window reset by new edit)
  └──→ discarded  (candidate disappeared or duplicate fingerprint in terminal state)
```

- `seen`: candidate detected but not yet stable.
- `ready`: settle window elapsed and revalidation passed.
- `canonicalized`: shorthand rewritten to canonical block in the note.
- `dispatched`: worker launched with `bump_id`.
- `done` / `blocked`: terminal states written by the worker.
- `discarded`: candidate no longer valid; no further processing.

## Persistence

Queue entries are stored as individual JSON files: `.bump/queue/<candidate_id>.json`.
This avoids contention on a single file when multiple commits arrive in rapid succession.
