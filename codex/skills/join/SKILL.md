---
name: join
description: "PR autopilot via `gh` only: target explicit PRs or all open PRs, create/manage PRs, keep branches current, gate on required checks, apply minimal remote fixes, optionally invoke `$review` as a review gate, and publish merge-ready handoff without merging. After creating a PR it watches review activity by default (in-session poll until reviewDecision is decisive or a timeout), reporting in-session without posting PR comments. Use for PR monitoring, CI-failure triage, branch hygiene, review-comment watch, and human-merge handoff."
---

# Join

## Intent
Run a continuous PR operator using `gh` commands only. Keep PRs created, green, and merge-ready with minimal-incision fixes. Do not approve or merge PRs unless explicitly instructed by the user.

## Command boundary (hard rule)
- Use only `gh` CLI commands (`gh pr`, `gh run`, `gh api`, `gh repo`).
- Do not run `git` or any non-`gh` command.
- Exception: when linking a created PR to an existing bd issue, allow `bd show` and `bd update` only for that linkage write.
- If a required action cannot be completed with `gh` alone, pause automation for that PR and report the block to the user in-session (do not post a PR comment).
- Never post operator status/handoff/block/stalled comments to a PR (no `Join Operator` comments). Report all such state to the user in-session; the only `gh` writes allowed are PR/branch mutations the user asked for and, when explicitly instructed, a formal `gh pr review`.

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
- `$join --pr 123 --review auto --review-target pr --no-merge`

## Usage notes
- `--repo owner/repo` required before mutation.
- `--mode sequential` per PR (no parallel PR workers).
- `--review off|auto|required` (default: `auto`).
- `--review-target pr|artifact` (default: `pr`).
- `--gate required-only` (optional checks ignored for handoff).
- `--wait poll:30-60s` via `gh pr checks --required --json ...`.
- `--status in-session` (report status to the user in the session; never post or maintain PR comments).
- `--target --pr <num> | --target all-open`.
- `--boundary gh-only`; if blocked => `--pause pr` and report the block in-session.
- `--no-merge --no-approve` unless user explicitly overrides.
- `--watch` is default-on after PR creation; `--no-watch` opts out. Tune with `--watch-interval 180s` and `--watch-timeout 2h` (see Post-create review watch).

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
- If `.github/pull_request_template.md` exists on the target base branch, create the PR body from that template and fill every markdown heading with obvious context (do not leave heading sections empty).
  - Fill with concrete values from available fields (`intent_summary`, `changed_paths`, `issue_refs`, `patch_id`, current validation/check state).
  - Keep template heading structure unchanged; append concise bullets/sentences under each heading as needed.
  - Apply the PR description content policy (below) when writing the content under each heading.
- If the repo template does not exist, use `assets/pr-template.md` (own fallback structure) or `gh pr create --fill`.
- Prefer explicit body create when template is present: `gh pr create --title <title> --head <branch> --base <base> --body "<rendered-template-body>"`.
- Default to ready-for-review (no drafts unless configured).
- If `issue_refs` includes one or more bd issue IDs and `BEADS_DIR` is present, record PR linkage on each issue immediately after creation:
  - Set external reference: `bd update <issue-id> --external-ref pr:<number>`
  - Append durable log token for extraction: `bd update <issue-id> --append-notes "Linked PR #<number> (pr:<number>)"`
  - Verify linkage write: `bd show <issue-id> --json`
  - This linkage write is one-directional (PR info → bd). Never write bd issue IDs or bd-specific context back into PR-visible text; see "PR description content policy" below.
- After a PR is created successfully (and linked, if applicable), start the post-create review watch by default unless `--no-watch` was passed (see Post-create review watch).

## PR description content policy
- Write for the reader, not for the diff: every PR body must make Why, What, and How legible without forcing the reader into the diff itself. Favor plain, explicit phrasing over terse polish.
- Default heading set (fallback only, see `assets/pr-template.md`): Overview / Background / Changes / Notes. When a repo template exists, keep its headings (per "PR creation policy" above) but hold the same clarity bar inside them.
- Shape each heading the same way: open with a plain-language summary in prose, then list the key points as bullets beneath it. Don't open a heading with a bare bullet list — give the reader prose to orient on first, however long that takes to be clear.
- Under each topic in Changes, lead with the reason before the mechanics — a reader should know *why* a change exists before seeing *what* it touches. If a topic needs more than a bullet's worth of explanation, give it its own `### <Topic>` subsection instead of cramming it into the bullet.
- Surface any prerequisite the reader needs but the diff won't show (a prior incident, an upstream change, a constraint) — don't assume shared context.
- Carry origin context forward: if the patch comes from a `$desk` task, append `source issue link: <url>` as the last line of Overview (or the template's closest equivalent heading), using the task note path/URL as `<url>`.
- `bd` stays internal: no `bd` issue ID or bd-specific detail ever appears in PR-visible text (description or any comment the skill posts). Linkage flows one way — PR → bd via `bd update` — never the reverse.
- Default to Japanese content unless the invoking context says otherwise.

### Self-check before publishing
Before sending the body via `gh pr create`/`gh pr edit`, confirm:
- Each topic states *why*, not just *what*.
- Any non-obvious prerequisite/background fact is stated.
- `source issue link: <url>` is present at the end of Overview if the patch originated from a `$desk` task.
- No `bd` issue ID or bd-specific text appears anywhere in the body or in skill-authored comments.
- Heading structure matches the repo template if one exists, otherwise the four-heading fallback.

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
   - Run review gate when `--review != off` (see Review integration).
   - When green and review gate is satisfied, report merge-ready handoff to the user in-session.
   - Do not approve or merge.

## Review integration
- Trigger point: after required checks are green, before handoff.
- Invocation:
  - PR mode: `$review --mode pr-comment --target-pr <num>`
  - Artifact mode: `$review --mode artifact-report --artifact join:<patch_id>`
- Policy:
  - `--review off`: skip review gate.
  - `--review auto`: run review gate; if unavailable/error, continue with handoff and record `review_skipped`.
  - `--review required`: run review gate; if unavailable/error, pause automation for that PR and report the block reason in-session.
- Reviewer output contract (must match mesh Round E):
  - `decision: approve|request_changes`
  - `findings[]` with `finding_id, location, severity, label, issue, evidence, minimal_fix, code_context`
  - `summary`
- Decision handling:
  - `approve`: continue to handoff.
  - `request_changes`: report the consolidated findings to the user in-session; post a formal `gh pr review --request-changes` only on explicit user instruction; return to surgical fix loop.
- Beads integration:
  - If `BEADS_DIR` is present and any finding label is `MUST_FIX`, open/update bd issue(s) and link finding ids.

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
  - If the snapshot does not change for 10 minutes while not all checks are `bucket=pass`, pause automation for that PR and report a summary with links to the stuck checks to the user in-session.
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
   - Report a summary to the user in-session.
   - Request changes as a last resort only on explicit user instruction (`gh pr review --request-changes`).
   - Pause automation for that PR.

## Handoff (no merge)
- When required checks are green (or no required checks exist), review gate is satisfied, and no pause condition:
  - Report to the user in-session: ready for human review/merge (do not post a PR comment).
  - Keep the PR open.
- Policy:
  - Never run `gh pr merge` (any flags).
  - Never run `gh pr review --approve` unless explicitly instructed by the user.
- Confirm handoff state:
  - `gh pr view <num> --json state,mergeStateStatus,reviewDecision`

## Post-create review watch (default-on)
After creating a PR, watch its review activity by default until the review outcome is decisive. Skip only when `--no-watch` was passed.

- Mechanism: in-session self-poll via `ScheduleWakeup`. The main session re-invokes itself on each interval and polls; between polls the session stays free for the user. This watch does not survive the session ending (accepted trade-off; use a detached routine if cross-session durability is needed).
- Cadence: poll every `--watch-interval` (default `180s`, within the prompt-cache window). Do not drop below 60s.
- Baseline: at watch start, record counts and ids for reviews, inline review comments, and issue (conversation) comments, plus `reviewDecision`. Use these as the diff anchor.
  - reviews: `gh api repos/<owner>/<repo>/pulls/<num>/reviews`
  - inline comments: `gh api repos/<owner>/<repo>/pulls/<num>/comments`
  - conversation comments: `gh api repos/<owner>/<repo>/issues/<num>/comments`
  - decision/state: `gh pr view <num> --json reviewDecision,mergeStateStatus,state`
- Each poll: detect anything new vs baseline — new formal reviews, new inline comments, new bot/conversation comments (e.g. a Codex review bot), or a `reviewDecision` change. Summarize new content to the user in-session and advance the baseline. Never post a PR comment.
- Stop conditions (any one):
  - `reviewDecision` becomes decisive: `APPROVED` or `CHANGES_REQUESTED`.
  - `--watch-timeout` elapses (default `2h`) — stop and report current state. This caps the common case where a bot only comments and no required reviewer is set, so `reviewDecision` never becomes decisive.
  - The PR is merged or closed.
- On `CHANGES_REQUESTED` or actionable findings: summarize the findings to the user in-session and hand off. Do not auto-enter the surgical fix loop, and never merge or approve. The user decides whether to address, discuss, or fix.
- Continue the no-PR-comment rule throughout: the watch reports only in-session.

## Adaptive polling
- Poll under 60s unless CI is slow.
- Use recent CI duration to back off (cap at 120s).
- Exponential backoff on API errors.

## Status reporting
- Report status to the user in the session output (and local operator logs); never post or maintain any PR comment.
- Keep a concise running status (created / green / review / handoff / blocked / stalled) in-session so the user can act.
- Do not post a `Join Operator` comment to the PR under any condition.

## Gh-only block report (in-session)
```
join: gh-only automation block

This PR needs an action outside the gh-only boundary (for example, manual conflict resolution or a local-only edit path).
Apply the needed commit manually, then resume automation.
```

## Stalled CI report (in-session)
```
join: required checks stalled

Required checks showed no progress for 10 minutes.
Investigate the linked runs, unblock CI, then resume automation.
```

## Recipes (gh-only)
- Default branch: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`
- Branch discovery: `gh api repos/<owner>/<repo>/branches --paginate --jq '.[].name'`
- PR template check: `gh api repos/<owner>/<repo>/contents/.github/pull_request_template.md?ref=<base> --jq .path`
- PR template fetch (decoded): `gh api repos/<owner>/<repo>/contents/.github/pull_request_template.md?ref=<base> --jq '.content | gsub("\n"; "") | @base64d'`
- Create: `gh pr create --fill --head <branch>`
- Create with rendered template body: `gh pr create --title <title> --head <branch> --base <base> --body "<rendered-template-body>"`
- Open PRs: `gh pr list --state open --json number,title,headRefName,isDraft`
- Mark ready: `gh pr ready <num>`
- Update branch: `gh pr update-branch <num> --rebase`
- PR head OID: `gh pr view <num> --json headRefOid --jq .headRefOid`
- Required checks (summary): `gh pr checks <num> --required`
- Required checks (poll JSON): `gh pr checks <num> --required --json name,bucket,startedAt,completedAt,link,workflow`
- Actions runs (by branch): `gh run list --branch <branch> --limit 10`
- Actions run logs: `gh run view <run-id> --log-failed`
- Request changes: `gh pr review <num> --request-changes --body "<reason>"`
- Review trigger (example): `$review --mode pr-comment --target-pr <num>`
- Handoff state: `gh pr view <num> --json state,mergeStateStatus,reviewDecision`
- bd issue linkage (exception path): `bd update <issue-id> --external-ref pr:<num>`
- bd issue linkage log token: `bd update <issue-id> --append-notes "Linked PR #<num> (pr:<num>)"`

## Assets
- `assets/pr-template.md`
