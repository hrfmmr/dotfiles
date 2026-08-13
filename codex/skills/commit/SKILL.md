---
name: commit
description: Create micro-commits with at least one validation signal per commit, and groom branch history into semantic-unit commits before PR handoff. Use when requests say "split this into micro commits," "stage only the minimal change and commit," "keep commits tiny while checks pass," "squash into semantic units," "clean up commit history," or "rewrite commit subjects in English," when parallel workers or slices need isolated, reviewable commits, or when a branch (including an existing PR's branch) needs its history squashed and force-pushed before review.
---

# Commit

## Intent
Carve changes into surgical commits: one coherent change, minimal blast radius, and at least one feedback signal before committing.

This skill is the standard commit path of the workflow. Micro-commits are the working style; a branch produced this way must satisfy the pre-PR grooming contract below before a PR is created from it.

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
- Absorb, don't stack: if this incision corrects or continues the intent of an **unpushed** prior commit (typo, missed file, review tweak) rather than opening a new reviewable intent, fold it in — `git commit --amend` when the target is HEAD, else `git commit --fixup=<sha>` followed by a non-interactive autosquash (`GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <sha>^`). Never absorb into pushed history here; that belongs to the pre-PR grooming contract.
- Keep the message terse. Optimize for clarity over poetry.
- Write the subject in English by default; an explicit repository convention for another subject language overrides this. English from creation avoids renames at the PR-boundary grooming, which requires English subjects.
- Use a Conventional Commits prefix by default (`feat:` / `fix:` / `chore:`).
- If no prefix is specified, choose one based on the change type (feature=`feat`, bug fix=`fix`, maintenance=`chore`).
- Commit only after at least one signal passes.

### 6) Repeat
Repeat until the working tree is clean or the remaining changes are intentionally deferred.

## Pre-PR grooming contract (squash to semantic units)

Run this before creating a PR from the branch. For an already-open PR, run it on demand — the same contract applies to that PR's branch.

### Autonomous hygiene inside the loop
- Step 5's absorb-don't-stack rule is the in-loop half of this contract: corrections to unpushed history fold into their unit at commit time, so grooming debt does not accumulate silently.
- Push checkpoint: immediately before pushing new history (the moment it becomes shared), run a grooming-debt check over the unpushed span and groom non-semantic commits on the spot — no force-push is involved for never-pushed history. Debt that is already pushed is recorded and deferred to this boundary contract, never rewritten ad hoc.
- The asymmetry is deliberate: unpushed history is free to rewrite; shared history is rewritten only under the full contract below (approval, tree-identity check, force-with-lease, re-sync).

### Target state
- One commit = one reviewable intent (qualitative criterion only; no numeric threshold). Collapse fixup/typo/comment-tweak chains and sliced same-area commits into the unit they belong to.
- Subject lines in English, Conventional Commits format (scope allowed, e.g. `feat(scope): ...`).
- Bodies may stay in the repository's prose language. Carry forward the key rationale from the original bodies; grooming must not discard why-content.

### Grooming span (base selection)
- Groom only this PR's own span: base = `git merge-base origin/<PR-base-branch> HEAD`.
- A stacked branch must first be rebased onto its current base, then groomed within its own span only. Never absorb base-branch commits into a unit.

### Method (non-interactive)
- `git rebase -i` is unavailable; use `git reset --soft <base>` and re-commit per unit, or script `GIT_SEQUENCE_EDITOR`.

### Safety invariants (mandatory)
- Content must not change: verify `git diff <old-head> <new-head>` is empty (tree byte-identical) before pushing.
- Push with `git push --force-with-lease` only.
- On a shared branch, get the owner's or orchestrator's go-ahead before force-pushing, and announce it to agents working the same branch.
- Report old head, new head, the resulting subject list, and the tree-identity check result.

### Relation to per-commit validation signals
- Grooming does not change content, so the signals already obtained on the original micro-commits remain valid. The mandatory tree-identity check substitutes for running a signal per squashed commit; do not re-run checks just because history was rewritten.

### Completion condition with live reviews
- If the branch has a live review session or unresolved review threads (e.g. a Hunk session, a bot review), grooming is complete only after re-syncing them by the owning skill's procedure (for Hunk: sidecar anchor update + session reload + in-place replies). A force-push that leaves review anchors stale is an unfinished grooming.

## Guardrails
- Don't widen scope without asking.
- Prefer the smallest check that meaningfully exercises the change.
- Don't claim completion without a passing signal.

## Resources
- `scripts/micro_scope.py`
- `references/loop-detection.md`
