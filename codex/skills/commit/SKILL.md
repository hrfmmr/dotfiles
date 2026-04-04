---
name: commit
description: Create micro-commits with at least one validation signal per commit. Use when requests say "split this into micro commits," "stage only the minimal change and commit," "keep commits tiny while checks pass," or when parallel workers or slices need isolated, reviewable commits.
---

# Commit

## Intent
Carve changes into surgical commits: one coherent change, minimal blast radius, and at least one feedback signal before committing.

## Workflow (Surgeon's principle)

### 1) Scope the incision
- Identify the smallest change that can stand alone.
- Isolate unrelated edits. Avoid drive-by refactors or formatting unless required for correctness.

### 2) Stage surgically (non-interactive-first)
Inspect:
- `git status -sb`
- `git diff`

Stage only what you intend (prefer file-level staging in non-interactive environments):
- `git add <paths...>`
- `git restore --staged <paths...>`

Verify:
- `git diff --cached` matches the intended incision.

If you truly need hunk-level staging but the environment cannot do interactive staging, ask the user to split hunks locally or provide a patch you can apply.

### 3) Validate the micro scope
- Optional helper: `scripts/micro_scope.py` (compare staged vs. unstaged size).
- If the staged diff covers multiple concerns, split it before running checks.

### 4) Close the loop (required)
- Choose the smallest meaningful signal and run it.
- If the repository's test/check command is not discoverable, ask the user for the preferred command.
- Reference: `references/loop-detection.md`.

### 5) Commit
- Keep the message terse. Optimize for clarity over poetry.
- Use a Conventional Commits prefix by default (`feat:` / `fix:` / `chore:`).
- If no prefix is specified, choose one based on the change type (feature=`feat`, bug fix=`fix`, maintenance=`chore`).
- Commit only after at least one signal passes.

### 6) Repeat
Repeat until the working tree is clean or the remaining changes are intentionally deferred.

## Guardrails
- Don't widen scope without asking.
- Prefer the smallest check that meaningfully exercises the change.
- Don't claim completion without a passing signal.

## Resources
- `scripts/micro_scope.py`
- `references/loop-detection.md`
