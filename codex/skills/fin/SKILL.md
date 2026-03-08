---
name: fin
description: Finalize a completed bd-scoped worktree task when the user asks to finish, wrap up, merge if needed, verify related bd issues are closed, link the PR, and remove the current git worktree.
---

# fin

Finalize a worktree-bound task with the smallest safe sequence: verify bd closure state, verify or repair PR linkage, check merge state, then remove the current worktree only when completion is real.

## When To Use

- Use this when the user wants to finish a cwd-scoped worktree task.
- Use this when the user asks to confirm related bd issues are done and clean up the worktree.
- Use this when the user wants a PR merged or verified before local teardown.

## Command Boundary

- Use `bd`, `gh`, and `git` only.
- Prefer the main repository checkout for `bd` operations when cwd is a git worktree and local `.beads` resolution is unreliable.
- Do not remove a worktree until every required completion check passes.

## Resolution Protocol

1. Resolve the execution context.
   - Identify the current worktree path from `pwd`.
   - Identify the current branch.
   - Identify the main repository checkout from the shared git directory.
   - If the repository uses beads, operate on the shared/main checkout for `bd`.

2. Resolve the primary bd issue for the current cwd.
   - First, infer it from the branch name pattern `wt/<issue-id>-...`.
   - If that fails, inspect worktree notes or obvious bd references for the cwd.
   - If you cannot identify exactly one primary issue, stop and report the ambiguity.

3. Resolve related sub-issues.
   - Enumerate the primary issue plus its child issues.
   - Treat those as the required closure set for this skill.
   - If any issue in that set is not closed, output a concise work-status summary and stop.
   - Use this exact stop prefix: `STOP: open bd issues remain`

4. Resolve the related PR.
   - If the primary bd issue already has `external_ref=pr:<number>`, use that PR.
   - Otherwise, find the PR by the current head branch.
   - If you find exactly one PR and the bd issue lacks the external ref, write both:
     - `bd update <issue-id> --external-ref pr:<number>`
     - `bd update <issue-id> --append-notes "Linked PR #<number> (pr:<number>)"`
   - If you cannot identify exactly one PR, stop and report the mismatch.

5. Check merge state.
   - If the PR is already merged, continue.
   - If the PR is open or otherwise unmerged, stop and ask the user whether to merge it.
   - Use this exact prompt format:
     - `HUMAN INPUT REQUIRED: Merge PR #<number> now? [y/N]`
   - Do not merge automatically without an explicit `y`.

6. Remove the current worktree only after completion is real.
   - Completion is real only when:
     - the primary bd issue is closed,
     - every related sub-issue is closed,
     - the related PR is linked to the primary bd issue,
     - the PR is merged.
   - Remove the current worktree from the main repository checkout, not from inside the worktree being deleted.
   - After removal, run `git worktree prune`.
   - Report the removed path and the prune result.

## Output Contract

- If any bd issue remains open:
  - Output `STOP: open bd issues remain`
  - Then list each open issue with its id, status, and one-line summary.
- If PR linkage was missing and was repaired:
  - State that the bd issue was updated with `pr:<number>`.
- If the PR is not merged:
  - Output only the required human-input line and stop.
- If cleanup succeeds:
  - State the primary issue, PR number, merge status, removed worktree path, and prune completion.

## Guardrails

- Do not guess across multiple candidate bd issues or PRs.
- Do not close still-open issues as part of this skill unless the user asks separately.
- Do not remove the current worktree when the PR is unmerged or linkage is unresolved.
- Do not leave PR linkage half-written; write both `external_ref` and the durable notes token together.
