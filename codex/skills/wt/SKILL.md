---
name: wt
description: Create or reuse a git worktree for a bd issue when work should be isolated in its own checkout, especially in repositories that use BEADS_DIR and want issue-linked branches under __worktrees__/.
---

# WT

## Overview

Create a git worktree and branch for the bd issue that represents the working scope. Prefer an explicitly named bd issue; otherwise use the obvious parent epic when that is the durable scope, and fall back to the current in-progress issue only when no better parent exists.

## Workflow

1. Confirm the repository context.
- Run `echo $BEADS_DIR` to see whether beads is active.
- If the session context is stale, run `bd prime`.
- Discover the default remote branch with `git symbolic-ref refs/remotes/origin/HEAD`.
- If beads is active, inspect the repository-root Dolt remote config with `bd dolt remote list` and remember the `origin` value for possible worktree sync.

2. Resolve the target bd issue before touching git.
- If the user explicitly named a bd issue ID, use it.
- Otherwise inspect the active scope with `bd list --status=in_progress --json` and `bd show <issue-id> --json`.
- If the current issue is a child task and its parent epic is the obvious long-lived scope for the worktree, use the parent epic.
- If more than one issue is equally plausible, ask one short question before creating anything.

3. Derive stable names from the chosen issue.
- Read the title from `bd show <issue-id>`.
- Convert the title to a short lowercase kebab-case slug.
- Use branch name `wt/<issue-id>-<slug>`.
- Use worktree path `__worktrees__/<issue-id>-<slug>`.
- Keep the issue ID intact even if the slug is shortened.
- If a matching branch or worktree already exists for that issue, reuse it instead of inventing a variant.

4. Prepare the base checkout safely.
- Prefer the repository default branch as the base for a new issue branch.
- Run `git fetch origin` before creating the worktree when the remote exists.
- Prefer `bd worktree create` over raw `git worktree` so the new checkout shares the same `.beads` database through redirect files.
- If the current checkout is not on the intended base ref and switching it would disturb in-progress work, stop and ask before changing the current checkout.

5. Create or reuse the worktree.
- Ensure `__worktrees__/` exists.
- Inspect existing state with `git worktree list` and `git branch --list "wt/<issue-id>-<slug>"`.
- If the target worktree path already exists, reuse it.
- If the target branch already exists in another worktree, report that path and reuse it rather than creating a second checkout for the same branch.
- Otherwise create the worktree with:

```bash
bd worktree create "__worktrees__/<issue-id>-<slug>" --branch "wt/<issue-id>-<slug>"
```

6. Verify the result immediately.
- Run `git worktree list`.
- Run `git -C "__worktrees__/<issue-id>-<slug>" branch --show-current`.
- If beads is active, run `cd "__worktrees__/<issue-id>-<slug>" && bd worktree info`.
- If beads is active, run `cd "__worktrees__/<issue-id>-<slug>" && bd dolt remote list`.
- If the worktree has no Dolt `origin` but the repository root does, run `cd "__worktrees__/<issue-id>-<slug>" && bd dolt remote add origin <repository-root-origin>`.
- Re-run `cd "__worktrees__/<issue-id>-<slug>" && bd dolt remote list` and confirm the worktree matches the repository-root `origin`.
- Confirm that the created or reused checkout points at the expected branch and path.

7. Record and report the mapping.
- If beads is active, append a note to the target issue with the branch and worktree path.
- After a bd mutation block, run `bd dolt commit` and `bd dolt push`.
- Report the resolved issue ID, chosen branch, worktree path, whether it was created or reused, and any reason you had to stop short.

## Guardrails

- Do not create a worktree until the target bd issue is unambiguous.
- Do not drop the bd issue ID from branch or directory names.
- Do not create a second worktree for the same branch when an existing one can be reused.
- Do not use raw `git worktree` when `bd worktree create` can satisfy the request.
- Do not invent a Dolt remote value; copy the repository-root `origin` only when the worktree is missing it.
