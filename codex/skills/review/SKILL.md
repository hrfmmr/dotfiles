---
name: review
description: "Critical review gate for a target PR or current working artifact. Emit structured findings and decision (`approve|request_changes`) compatible with mesh Round E. By default one codex reviewer (gpt-6.1-sol, xhigh) runs the four review lanes sequentially: inside Herdr in a persistent agent pane below the caller that is reused for follow-up reviews, outside Herdr through `codex exec`; when codex is unavailable, Claude Opus 5.5 xhigh takes its place (a Herdr pane inside Herdr, `claude -p` outside). Fans out one reviewer per lane only on explicit request (`--multi-agent`). In `pr-comment` mode it posts one inline comment per finding and keeps one summary comment per PR, even when nothing is found."
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
- Post each finding as an inline comment on its changed file and diff line, and post exactly one summary comment for the whole review (PR Summary Comment Contract), even when there are no findings.

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
- `--multi-agent`: run each review lane in its own sub-agent, in parallel. Treat an explicit caller request for per-lane sub-agents the same way. Without it, use the single-reviewer default.
- `--model <name>` / `--effort <level>`: override the reviewer's model or reasoning effort. Change them only when the caller names them explicitly; otherwise use the defaults in Reviewer Agent.

## Output contract (required)
- `decision: approve|request_changes`
- `findings` (array)
- `summary` (1-5 lines)

## Execution Model
- Act as the review orchestrator for the requested target.
- Default (single reviewer): hand every review lane to one reviewer agent (see Reviewer Agent), which runs them sequentially and returns the lane artifacts. Spawn no other agents, parallel reviews, or workflows, so token usage does not spike.
- The orchestrator runs the lanes itself only when it is already the reviewer: a codex session running the selected model and effort, or an agent whose brief says it is the reviewer for this review (the codex reviewer or the Claude fallback). The brief tells every reviewer it is the leaf reviewer, so a reviewer never starts another reviewer.
- Opt-in (multi-agent): only with `--multi-agent` or an explicit caller request for per-lane reviewers, start one reviewer per lane and run them in parallel against the same target. Each lane reviewer follows Reviewer Agent (model, effort, fallback): inside Herdr one pane per lane in the bottom agent row, outside Herdr one `codex exec` per lane. Give each lane reviewer its own stable name (`rev-<caller agent name>-<lane>`, shortened to the name limit) and its own artifact path, and a brief that covers only its lane. If they cannot be started, fall back to the single-reviewer default.
- Reviewers must not modify files, apply patches, or post comments directly; the only file a reviewer writes is the artifact file the orchestrator named.
- Only the orchestrator may emit the final `decision/findings/summary` artifact or post PR review comments.

### Execution Flow
1. Resolve the review scope from `--mode` and its required target input.
2. Gather the target context once and pass the same scope to every lane.
3. Have the reviewer agent run the lanes one after another (default), or fan them out in parallel with `--multi-agent`.
4. Normalize, deduplicate, and rank findings centrally.
5. Emit one final artifact; in `pr-comment` mode, reconcile matching AI-authored inline comments so each canonical finding converges to at most one live thread before posting any new comments.
6. In `pr-comment` mode, post or update the single summary comment last, after the inline comments (PR Summary Comment Contract).

### Reviewer Agent
Default reviewer: codex, model `gpt-6.1-sol`, reasoning effort `xhigh` (`-m gpt-6.1-sol -c model_reasoning_effort=xhigh`). Use `--model` / `--effort` values only when the caller gave them.

Inside Herdr (`HERDR_ENV=1`), the reviewer lives in its own agent pane directly below the caller, so follow-up reviews go to the same agent. Follow the base `herdr` skill for every pane and agent command, and parse ids from its JSON.
1. Name the reviewer `rev-<caller agent name>` (or `rev-<short topic>` when the caller has no name), cut to the `[a-z][a-z0-9_-]{0,31}` limit. If `herdr agent get <name>` finds it alive and its pane is one this orchestrator started, reuse it: for a codex agent go to step 4; for the Claude fallback go to step 5 (its model was fixed by its start flags).
2. Split below the caller and keep focus: `herdr pane split --current --direction down --cwd "<repo root>" --no-focus`. When a bottom agent row already exists, split its last pane to the right instead.
3. Start codex and set the label to the same name: `herdr agent start <name> --kind codex --pane <pane-id> --timeout 60000 -- -m gpt-6.1-sol -c model_reasoning_effort=xhigh`, then `herdr pane rename <pane-id> <name>`.
4. Check the effective model and effort: send `/status` to the codex agent and read what it reports. codex can drop to another model near its usage limit without saying so, and its status line can be hidden, so do not judge from the status line alone. If `/status` shows another model or effort, set them for this session with `/model`; if that fails, treat codex as unavailable.
5. Send the brief with `herdr agent prompt <name> "<brief>" --wait --timeout <ms>` through a background runner. The brief carries the mode, the scope and context the orchestrator gathered, the four lanes, the Lane Output Contract, and the finding schema. It says the agent is the leaf reviewer for this review, that the pass is review-only (no edits, commits, pushes, PR comments, or new reviewers), and asks it to write all lane outputs to one file at a path the orchestrator chose (outside the repo) and to reply with only that path. Writing that one artifact file is the only write allowed. Codex runs on the alternate screen, so a long structured answer read from the pane can be cut off.
6. Read the file and aggregate. For a follow-up review, send the same agent a new brief that names the new head and which earlier findings each change addressed, so `finding_id` values stay stable.
7. Leave the pane idle after the review so later follow-up reviews reach the same agent. Close it only when the caller or the human asks.

Outside Herdr: run `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh -s read-only -C <repo root> -o <artifact file> "<brief>"`, with the brief asking for all lane outputs as the final message, and read the artifact file.

When codex is unavailable (not installed, not logged in, usage limit reached, the model cannot be set, or the agent does not start or stalls):
- Inside Herdr: close the codex pane this orchestrator started (`herdr pane close <pane-id>`) so the name is released, split a new pane in the same position (step 2), and start a Claude Opus 5.5 xhigh agent there with the same name and brief: `herdr agent start <name> --kind claude --pane <new-pane-id> --timeout 60000 -- --model claude-opus-5-5 --effort xhigh`, then `herdr pane rename <new-pane-id> <name>`. Pass the model with these flags; never switch it with `/model` inside Claude Code, because that also rewrites the global default model.
- Outside Herdr: run `claude -p --model claude-opus-5-5 --effort xhigh "<brief>" > <artifact file>`, with the same brief asking for all lane outputs as the final message, and read the artifact file.
- State in the final `summary` that codex was unavailable, why, and which model reviewed instead.

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
- Inside Herdr, if the codex reviewer times out or returns no artifact, read its state (`herdr agent get` / `herdr agent read`). If it is still `working`, wait for it with a deadline (`herdr agent wait <name> --timeout <ms>`); if it does not settle, stop it (`herdr agent send-keys <name> esc`) and confirm it is idle. After the wait, check the state and the artifact again: a valid artifact for the requested head means the review succeeded. If the agent is `blocked`, read what it is asking and either resolve it within the review-only rules or fail the review. Only when the agent is `idle` or `done` and the artifact is still missing, send the brief once more with a new artifact path, and check that the artifact names the head that was asked for. If it fails again, switch to the Claude fallback in Reviewer Agent.
- Outside Herdr, if `codex exec` exits non-zero or leaves no usable artifact, check its exit code and output and run it once more. If it fails again, switch to the `claude -p` fallback in Reviewer Agent.
- Use the fallback once. If the Claude fallback also fails, fail the review instead of starting another reviewer.
- With `--multi-agent`, if one lane reviewer returns no response, retry that lane once.
- If that lane still fails, run it in the single reviewer agent before giving up.
- If a lane output is unparsable, request one strict reformat using the lane output contract.
- If a lane still cannot produce a valid artifact after fallback, fail the review rather than silently dropping that lane.
- If aggregation cannot produce valid `decision/findings/summary`, fail the review rather than emitting a partial artifact.
- If unresolved lane failure or aggregation failure remains, do not post PR review comments or the summary comment; return control to the caller with an explicit failure reason.

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
- Post one inline comment per aggregated finding. The review-level summary goes only in the summary comment (PR Summary Comment Contract), never in an inline comment.
- Before posting, fetch existing PR inline comments authored by the orchestrator or prior AI review runs and match them by changed file, changed diff line, and materially same issue.
- If one matching AI-authored inline comment already exists, update that comment in place with the consolidated body instead of creating a new thread.
- If multiple matching AI-authored inline comments already exist, keep one canonical thread, update it with the consolidated body, and delete the redundant duplicates after the update succeeds.
- Anchor each comment to the changed file and changed diff line that best matches the finding.
- Sort posted findings by severity (`Critical > High > Medium > Low`), then `finding_id`.
- If `findings` is empty, post no inline comments; still post or update the summary comment.
- Start every posted comment with the marker `[<model>:<effort>]`, for example `[gpt-6.1-sol:xhigh]`: the reviewer agent's model and its reasoning-effort level as its harness reports them (not the orchestrator's). If one of them is not exposed, omit only that part (`[gpt-6.1-sol]`); never guess. Do not add words such as `agent` or `AI` to the marker, and do not add a separate "AI agent review comment" line.
- Keep each inline comment focused on the anchored finding only; the overall `decision` and `summary` go in the summary comment and the returned artifact.
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

## PR Summary Comment Contract

For `--mode pr-comment`, also post exactly one top-level PR comment that summarizes the whole review, so the PR shows that a review ran and what it covered even when it found nothing. Post it after the inline comments.

~~~md
<!-- review-summary -->
[{model}:{effort}] Review summary (head `{short_sha}`)

Decision: {approve|request_changes} — findings: {total} (Critical {n} / High {n} / Medium {n} / Low {n})

| lane | findings | summary |
|---|---|---|
| correctness | {n} | {lane summary} |
| security-performance | {n} | {lane summary} |
| tests-conventions | {n} | {lane summary} |
| technical-judgment | {n} | {lane summary} |

Checked: {what the reviewer verified, with the commands or files when useful}
Not checked: {what the reviewer could not verify and why}
Cautions: {non-blocking notes for whoever merges or applies, if any}
~~~

Summary comment rules:
- Post it in every completed `pr-comment` review, including when `findings` is empty. Skip it only when the review failed (Retry and Fallback).
- Keep exactly one live summary comment per PR. Before posting, list the PR's issue comments (`gh api repos/<owner>/<repo>/issues/<num>/comments`) and find one authored by the authenticated user whose body starts with `<!-- review-summary -->`. If found, update it in place (`gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<file>`) with the new head, counts, and summaries; otherwise create it (`gh pr comment <num> --body-file <file>`). Never add a second summary comment for a re-review.
- Use the same `[<model>:<effort>]` marker rule as the inline comments: the reviewer agent's model and effort as its harness reports them. When the reviewer's own output does not expose them, use what `/status` (or the start flags) showed, and never guess.
- If the orchestrator verified something beyond the reviewer (for example, live state the reviewer could not reach), put it after a `---` line at the end, labelled with the orchestrator's own model, so it is not read as the reviewer's finding.
- Write the prose in the PR's language (follow the inline comments and the PR body). Keep each lane summary to 1-3 lines; detail stays in the inline comments and the returned artifact.
- Do not put internal tracker IDs, secrets, account IDs, or local file paths in the comment.

## Review focus
- bugs, spec deviations, regressions, security, performance, missing tests
- code-level convention deviations
- technical judgment, architecture-fit with existing codebase conventions, and rejected alternatives rationale

## Mesh Integration

When called from `$mesh` Round E:
- use the independent reviewer from Reviewer Agent (single reviewer by default, per-lane reviewers only with the explicit opt-in) rather than implementation workers
- preserve a single consolidated review artifact for the orchestrator to persist as `[orch:review]`
- keep review findings stable enough that a repeated review cycle can track the same issue across revisions

## Decision handling
- `approve`: no blocking findings.
- `request_changes`: include actionable MUST_FIX first.

## Integration notes
- Called by `$join` after CI green and before handoff.
- If beads is in use and `MUST_FIX` exists, caller may open/update bd issues. (`$beads`)
