# Candidate AST

All recognizers emit a common AST. The hook pipeline and dispatcher consume only this shape.

## Fields

```text
Candidate:
  source_note_path   # absolute or vault-relative path to the note
  source_syntax      # which recognizer matched (e.g. "canonical", "shorthand:.o0")
  target_locator     # line range or heading anchor of the marked target
  target_excerpt     # first ~120 chars of the target span for logging
  request_text       # the human's follow-up question or task
  mode_hint          # "inline" | "branch" | "auto" | null
  title_hint         # user-specified derived note title or null
  is_complete        # bool: request_text is non-empty AND target is resolvable
  fingerprint        # SHA-256 of (source_note_path + target_locator + normalized request_text)
```

## Semantics

- `fingerprint` is the identity key. Two candidates with the same fingerprint are the same request regardless of commit.
- `is_complete` is a boolean predicate. The dispatcher never promotes an incomplete candidate past `seen`.
- `source_syntax` is recorded so canonicalization knows which rewrite rule to apply.
- `target_locator` must survive minor edits (prefer heading anchor over line number when available).
