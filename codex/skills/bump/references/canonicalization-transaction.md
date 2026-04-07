# Canonicalization Transaction

When a candidate reaches `ready` status, the dispatcher writes canonical metadata to the **queue entry** — not to the source note. The note remains untouched until the worker produces its result.

## Transaction Steps

1. Acquire `flock`-based advisory lock on `.bump/runtime/<note-path-hash>.lock`.
2. Re-read the source note from disk.
3. Re-run the recognizer; verify the same `fingerprint` (`.o0:` token) is still present.
4. Write canonical fields to the queue JSON entry (`.bump/queue/<candidate_id>.json`):
   ```json
   {
     "status": "canonicalized",
     "bump_id": "<stable-id>",
     "request_text": "<normalized request>",
     "mode": "auto",
     "title_hint": null,
     "agent_instruction": null,
     "source_syntax": "shorthand:.o0",
     "fingerprint": "<fingerprint>"
   }
   ```
5. **Do not modify the source note.** The `.o0:` line stays in place until the worker replaces it with the AI response.
6. Release lock.

## Failure Handling

- If `flock` acquisition fails (another process holds the lock): set queue status back to `seen` and retry on the next dispatcher cycle.
- If `fingerprint` no longer matches after re-read (compare-and-swap failure): set queue status back to `seen`. The next cycle will re-evaluate.
- If the source note no longer exists: set queue status to `discarded`.

## Interaction with Obsidian

Obsidian writes notes via tmp+rename (atomic). The `flock` lock targets a separate `.lock` file, not the note itself, so it does not conflict with Obsidian's write pattern. Since canonicalization no longer modifies the note, there is no race between the dispatcher and Obsidian's writes. The note is only modified once — by the worker, when it replaces the `.o0:` line with the AI response.
