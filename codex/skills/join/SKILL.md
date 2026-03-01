---
name: join
description: "PR autopilot via `gh` only: create/manage PRs, keep branches current, enforce required CI gates, apply surgical code patches, and publish merge-ready handoff without merging. Use when asked to run or monitor PR automation, fix failing required checks, keep local/remote branch state clean, or prepare branch/PR cleanup for human merge."
---

# Join

## Intent
Run a continuous PR operator using `gh` commands only. Keep PRs created, green, and merge-ready with minimal-incision fixes. Do not approve or merge PRs unless explicitly instructed by the user.

## Command boundary (hard rule)
- Use only `gh` CLI commands (`gh pr`, `gh run`, `gh api`, `gh repo`).
- Do not run `git` or any non-`gh` command.
- If a required action cannot be completed with `gh` alone, pause automation for that PR and leave a blocking comment.

## Quick start
1. Ensure `gh auth status` succeeds.
2. Select target scope: explicit PR (`--pr`) or all open PRs.
3. Start the monitor loop.

## Invocation
Use when prompt intent matches `pr-autopilot --gh-only`.

Example prompt forms:
- `$join --pr 123 --watch required --fix minimal --no-merge`
- `$join --scope open --update-branch rebase --handoff on-green`
- `$join --create-missing-prs --mode remote`
- `$join --ci-stall 10m --on-stall pause+comment`

## Usage notes
- `--repo owner/repo` required before mutation.
- `--mode sequential` per PR (no parallel PR workers).
- `--gate required-only` (optional checks ignored for handoff).
- `--wait poll:30-60s` via `gh pr checks --required --json ...`.
- `--status comment:Join Operator --update in-place`.
- `--target --pr <num> | --target all-open`.
- `--boundary gh-only`; if blocked => `--pause pr --comment block`.
- `--no-merge --no-approve` unless user explicitly overrides.

## Auth preflight (required)
- Run these checks before any PR routing or mutation:
  - `gh auth status`
  - `gh repo view <owner>/<repo> --json nameWithOwner --jq .nameWithOwner`
- If either check fails:
  - Fail fast for the current run.
  - Do not mutate PRs (comments/reviews may be unavailable without auth).
  - Record reason as `auth_unavailable` in local operator logs/output only.

## Target routing contract
- Target one PR when explicit selector exists (`--pr <num>` or `target_pr_hint`).
- Otherwise, target all open PRs in the selected repo.
- Process target PRs sequentially.

## PR creation policy (gh-only)
- For every non-default branch discoverable via `gh api` without an open PR, create a PR.
- Use the repo PR template if present; else use `assets/pr-template.md`.
- Prefer `gh pr create --fill`.
- Default to ready-for-review (no drafts unless configured).

## Operating mode
Use one mode only:
- `gh`-only remote mode: no local checkout assumptions and no local workspace mutations.

Required fields:
- `patch_id`
- `producer`
- `repo` (`owner/repo`)
- `base_branch`
- `changed_paths` (non-empty)
- `intent_summary`

Optional routing hints:
- `target_pr_hint`
- `issue_refs`
- `confidence`
- `patch_file`

## Monitor loop
Process PRs sequentially (blocking per PR on CI):
1. Resolve target PR set (`--pr <num>` if provided; else open PRs).
2. List open PRs when needed: `gh pr list --state open --json number,title,headRefName,isDraft`.
3. For each PR:
   - If draft, mark ready: `gh pr ready <num>`.
   - Keep the branch current with `gh pr update-branch <num> --rebase` when available.
   - Enforce CI gate (required checks only; see below).
   - If failing, run the surgical fix loop.
   - When green, publish merge-ready handoff status.
   - Do not approve or merge.

## CI gate (required checks only)
- Gate on required checks only (`gh pr checks --required`). Optional checks do not block handoff.
- Detect “ungated” repos/PRs (no required checks):
  - If `gh pr checks <num> --required --json name` returns an empty list, treat CI as green and proceed to handoff.
- Wait for required checks (polling mode, single mechanism):
  - Sample every 30-60s: `gh pr checks <num> --required --json name,bucket,startedAt,completedAt,link`
  - Treat green only when all required checks are `bucket=pass`.
- Stalled CI (10 minutes with no observable progress):
  - Define “progress” as any change in the required-check snapshot (`name`, `bucket`, `startedAt`, `completedAt`).
  - While waiting, keep sampling with the same polling command above.
  - If the snapshot does not change for 10 minutes while not all checks are `bucket=pass`, pause automation for that PR and leave a summary comment with links to the stuck checks.
  - Treat `bucket=pending`, `bucket=skipping`, and `bucket=cancel` as “not green” (blocked) until resolved; do not mark as handoff-ready through them.
- Drill into GitHub Actions when needed:
  - Identify check links: `gh pr checks <num> --required --json name,bucket,link,workflow`
  - Find likely runs: `gh run list --branch <headRefName> --limit 10`
  - Watch a run live: `gh run watch <run-id> --compact --exit-status`
  - Fetch failing step logs: `gh run view <run-id> --log-failed`

## Surgical fix loop (gh-only)
Smallest change that makes CI green using `gh` only:
1. Read the failure from CI logs.
2. Apply the minimal fix via `gh api` using the Contents API on the PR head branch (single-file minimal edits preferred).
3. Re-run checks and re-evaluate.
4. Limit attempts (default 3). On exhaustion, permission issues, or hard conflicts:
   - Leave a summary comment.
   - Request changes as last resort.
   - Pause automation for that PR.

## Handoff (no merge)
- When required checks are green (or no required checks exist) and no pause condition:
  - Update status/comment to indicate: ready for human review/merge.
  - Keep the PR open.
- Policy:
  - Never run `gh pr merge` (any flags).
  - Never run `gh pr review --approve` unless explicitly instructed by the user.
- Confirm handoff state:
  - `gh pr view <num> --json state,mergeStateStatus,reviewDecision`

## Adaptive polling
- Poll under 60s unless CI is slow.
- Use recent CI duration to back off (cap at 120s).
- Exponential backoff on API errors.

## Status reporting
- Maintain a single PR comment titled `Join Operator` (comment mode only).
- Update the same comment in place (store/reuse the comment id; avoid comment spam).
- If comment update is not permitted, pause automation for that PR and leave one fallback comment when possible.

## Gh-only block comment template
```
Join Operator: gh-only automation block

This PR needs an action outside the gh-only boundary (for example, manual conflict resolution or a local-only edit path).
Apply the needed commit manually, then resume automation.
```

## Stalled CI comment template
```
Join Operator: required checks stalled

Required checks showed no progress for 10 minutes.
Investigate the linked runs, unblock CI, then resume automation.
```

## Recipes (gh-only)
- Default branch: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`
- Branch discovery: `gh api repos/<owner>/<repo>/branches --paginate --jq '.[].name'`
- Create: `gh pr create --fill --head <branch>`
- Open PRs: `gh pr list --state open --json number,title,headRefName,isDraft`
- Mark ready: `gh pr ready <num>`
- Update branch: `gh pr update-branch <num> --rebase`
- PR head OID: `gh pr view <num> --json headRefOid --jq .headRefOid`
- Required checks (summary): `gh pr checks <num> --required`
- Required checks (poll JSON): `gh pr checks <num> --required --json name,bucket,startedAt,completedAt,link,workflow`
- Actions runs (by branch): `gh run list --branch <branch> --limit 10`
- Actions run logs: `gh run view <run-id> --log-failed`
- Request changes: `gh pr review <num> --request-changes --body "<reason>"`
- Handoff state: `gh pr view <num> --json state,mergeStateStatus,reviewDecision`
- Handoff note (example): `gh pr comment <num> --body "Join Operator: required checks are green; ready for human merge."`

## Assets
- `assets/pr-template.md`
