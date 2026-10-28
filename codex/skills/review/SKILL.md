---
name: review
description: "Critical review gate for a target PR or current working artifact. Emit structured findings and decision (`approve|request_changes`) compatible with mesh Round E. Runs the four review lanes sequentially in a single agent by default; fans out one sub-agent per lane only on explicit request (`--multi-agent`)."
---

# Review

## Intent
Run a critical third-party review and return a strict decision artifact.

## Modes
- `pr-comment`: review a target PR and post inline review comments on changed diff lines.
- `artifact-report`: review current working artifact in-memory and return report to caller context.

### Artifact Scope Rules (`artifact-report`)
- Review only files directly modified by the current agent in the ongoing work context.
- Exclude unstaged or dirty diffs that were not directly modified by the current agent, even if present in the working tree.
- Emit findings only for in-scope files; do not report out-of-scope file noise.

### PR Scope Rules (`pr-comment`)
- Review the effective diff and discussion context of the target PR.
- Do not expand scope beyond the PR unless the caller explicitly asks for repository-wide concerns that block merge.
- Post review output as inline comments on changed files and changed diff lines, not as a top-level PR comment.

## Required inputs
- `--mode pr-comment|artifact-report`
- one of:
  - `--target-pr <num>`
  - `--artifact <id>`
- Mode binding is strict:
  - `pr-comment` requires `--target-pr <num>`
  - `artifact-report` requires `--artifact <id>`
  - reject mismatched mode/target combinations instead of guessing intent

## Optional inputs
- `--multi-agent`: run each review lane in its own sub-agent, in parallel. Treat an explicit caller request for per-lane sub-agents the same way. Without it, use the single-agent default.

## Output contract (required)
- `decision: approve|request_changes`
- `findings` (array)
- `summary` (1-5 lines)

## Execution Model
- Act as the review orchestrator for the requested target.
- Default (single agent): run every review lane sequentially in one reviewer agent and preserve the lane artifact contract. Do not spawn sub-agents, other agents, parallel reviews, or workflows, so token usage does not spike. The reviewer agent is the current session, or the one reviewer sub-agent a caller delegated the whole review to.
- Opt-in (multi-agent): only with `--multi-agent` or an explicit caller request for per-lane sub-agents, spawn one reviewer sub-agent per lane and run them in parallel against the same target. If sub-agent spawning is unavailable, fall back to the single-agent default.
- Reviewer subagents must not modify files, apply patches, or post comments directly.
- Only the orchestrator may emit the final `decision/findings/summary` artifact or post PR review comments.

### Execution Flow
1. Resolve the review scope from `--mode` and its required target input.
2. Gather the target context once and pass the same scope to every lane.
3. Run the lanes one after another (default), or fan them out in parallel with `--multi-agent`.
4. Normalize, deduplicate, and rank findings centrally.
5. Emit one final artifact; in `pr-comment` mode, reconcile matching AI-authored inline comments so each canonical finding converges to at most one live thread before posting any new comments.

### Review Lanes
Run these lanes in both modes:
- `correctness`: bugs, spec deviations, regressions
- `security-performance`: security, abuse, performance, scalability
- `tests-conventions`: missing tests, coverage gaps, test strategy gaps, code-level convention deviations
- `technical-judgment`: architecture fit with existing codebase patterns, design justification, rejected alternatives, responsibility boundaries

Lane rules:
- Give every lane the same target context and the same output schema.
- Keep lanes independent; do not let one lane rewrite another lane's findings. In the single-agent default, close one lane's findings and summary before starting the next, and do not drop or soften an earlier lane's finding while reviewing a later lane.
- Allow a lane to return zero findings when its perspective is clean.
- Require `technical-judgment` to check whether the change follows existing architectural conventions such as layering, module boundaries, extension points, naming patterns, and whether any deviation is intentional and justified.

### Lane Output Contract
Each reviewer lane must return:
- `lane`
- `findings` (array using the required finding schema below)
- `summary` (1-3 lines scoped to that lane)

Lane contract rules:
- Keep lane summaries scoped to that lane's perspective; cross-lane synthesis belongs only in the final summary.

### Aggregation Rules
- Wait for all lane results before producing the final artifact, unless a lane hard-fails and fallback retry is exhausted.
- Normalize all lane findings into the required final schema.
- Deduplicate materially identical findings across lanes; keep the highest severity and strictest label variant, and merge evidence when useful.
- For `pr-comment`, run one more anchor-level consolidation pass before posting. If multiple lane findings describe the same underlying issue on the same `file:line`, merge them into one canonical finding/comment payload.
- When merging same-anchor findings, keep the highest severity and strictest label, preserve one stable `finding_id`, and fold distinct evidence or minimal-fix details into the single posted body without repeating the same point.
- Preserve stable `finding_id` values when the same underlying issue persists across repeated review cycles.
- Sort final findings by severity (`Critical > High > Medium > Low`), then `finding_id`.
- Set final `decision=request_changes` if any aggregated finding has `label=MUST_FIX`; otherwise set `decision=approve`.
- Final `summary` must synthesize cross-lane conclusions in 1-5 lines and explicitly say when no material issues were found.

### Retry and Fallback
- With `--multi-agent`, if one lane sub-agent returns no response, retry that lane once.
- If that lane still fails, run it sequentially in the current session before giving up.
- If a lane output is unparsable, request one strict reformat using the lane output contract.
- If a lane still cannot produce a valid artifact after fallback, fail the review rather than silently dropping that lane.
- If aggregation cannot produce valid `decision/findings/summary`, fail the review rather than emitting a partial artifact.
- If unresolved lane failure or aggregation failure remains, do not post PR review comments; return control to the caller with an explicit failure reason.

## PR Inline Comment Contract

For `--mode pr-comment`, post one inline review comment per aggregated finding using this template, anchored to the corresponding changed diff line:

~~~md
[{model}:{effort}] [{severity}][{label}] {finding_id}

Issue: {issue}
Evidence: {evidence}
Minimal fix: {minimal_fix}

Code context:
```{language}
{code_context}
```
~~~

Template rules:
- Post one inline comment per aggregated finding; do not post a top-level summary comment to the PR.
- Before posting, fetch existing PR inline comments authored by the orchestrator or prior AI review runs and match them by changed file, changed diff line, and materially same issue.
- If one matching AI-authored inline comment already exists, update that comment in place with the consolidated body instead of creating a new thread.
- If multiple matching AI-authored inline comments already exist, keep one canonical thread, update it with the consolidated body, and delete the redundant duplicates after the update succeeds.
- Anchor each comment to the changed file and changed diff line that best matches the finding.
- Sort posted findings by severity (`Critical > High > Medium > Low`), then `finding_id`.
- If `findings` is empty, post no PR review comments.
- Start every posted comment with the marker `[<model>:<effort>]`, for example `[gpt-6.1-sol:xhigh]`: the running model and its reasoning-effort level as the harness reports them. If one of them is not exposed, omit only that part (`[gpt-6.1-sol]`); never guess. Do not add words such as `agent` or `AI` to the marker, and do not add a separate "AI agent review comment" line.
- Keep each inline comment focused on the anchored finding only; the overall `decision` and `summary` stay in the returned artifact.
- Never leave more than one live inline review thread for the same canonical finding on the same diff line.
- If a finding cannot be anchored to a changed diff line with confidence, do not post it as a PR comment; keep it only in the returned artifact for caller handling.

Each finding must include:
- `finding_id`
- `location` (`file:line`)
- `severity` (`Critical|High|Medium|Low`)
- `label` (`MUST_FIX|SHOULD_CONSIDER|CAN_IGNORE`)
- `issue`
- `evidence`
- `minimal_fix`
- `code_context`

## Review focus
- bugs, spec deviations, regressions, security, performance, missing tests
- code-level convention deviations
- technical judgment, architecture-fit with existing codebase conventions, and rejected alternatives rationale

## Mesh Integration

When called from `$mesh` Round E:
- use independent third-party reviewer subagents rather than implementation workers
- preserve a single consolidated review artifact for the orchestrator to persist as `[orch:review]`
- keep review findings stable enough that a repeated review cycle can track the same issue across revisions

## Decision handling
- `approve`: no blocking findings.
- `request_changes`: include actionable MUST_FIX first.

## Integration notes
- Called by `$join` after CI green and before handoff.
- If beads is in use and `MUST_FIX` exists, caller may open/update bd issues. (`$beads`)
