---
name: triage
description: "Continuous GitHub issue intake for `auto:triage`: monitor an explicit repo, reuse `gen-plan` and `gen-beads` logic to turn one issue into one plan and one `plan_label`-scoped bd backlog, sync via Dolt, and hand off ready work to `mesh`. Use when prompts ask to patrol GitHub issues into orchestration backlog or run upstream triage loops."
---

# Triage

## Intent

Run the upstream orchestration intake loop:

- watch one explicit GitHub repository
- find open issues marked for automatic triage
- convert each issue into exactly one local plan file and one `plan_label`-scoped bd graph
- sync the graph via Dolt
- leave GitHub evidence that lets humans and `$mesh` find the generated backlog

## Safety Contract

- Operate on the repository resolved from the current cwd by default, unless the user explicitly names another target.
- Any repository-specific allow/deny policy belongs to the invocation context, not to this skill definition.
- Use `gh` for GitHub operations and `bd` for beads operations. Never hand-edit `.beads/*`.
- Reuse the planning logic from `$gen-plan` and the graph-shaping rules from `$gen-beads`, but do not require their exact CLI contract.
- Process issues sequentially. One GitHub issue is one transaction boundary.
- Do not create or mutate GitHub issues outside the selected repo.

## Invocation

Default target:

- resolve the current repository from cwd
- allow `--repo owner/repo` only as an explicit override when the user wants to target another repository

Defaults:

- `--label auto:triage`
- `--done-label auto:triaged`
- `--failed-label auto:triage-failed`
- `--interval 5m`
- `--limit 20`
- `--write-github on`

Useful toggles:

- `--once`
- `--dry-run`
- `--write-github off`

Behavioral notes:

- A polling cycle may drain multiple eligible issues, but each issue must complete or stop independently before the next issue begins.
- `--write-github off` may skip labels and comments for local rehearsal, but still uses the same cwd-based repository resolution.
- `--write-github off` is valid only with `--once` or `--dry-run`. In continuous mode it would remove the machine-readable terminal markers and cause the same issue to be triaged again on the next cycle.

## Contracts

Treat [`references/contracts.md`](references/contracts.md) as the detailed source of truth for:

- issue state machine
- idempotency rules
- plan and `plan_label` naming
- bd metadata keys
- bot comment fields
- human re-entry after failure

If the reference and this file disagree, the reference wins.

## Preflight

1. Run `gh auth status`.
2. Run `bd where --json`.
3. Run `bd status --json`.
4. Refuse unsafe targets:
   - stop if the repo target cannot be resolved from cwd and no explicit override is provided
   - stop if the repo is missing
5. Require a usable Dolt remote unless this is an explicit `--dry-run` rehearsal.
6. If a Dolt remote is configured, run `bd dolt pull`.
7. Ensure `.plans/` exists.
8. Load the contract reference and start the loop.

## Eligibility Query

Use one of these equivalent query forms:

```bash
gh issue list \
  --repo <owner/repo> \
  --state open \
  --label auto:triage \
  --search "-label:auto:triaged -label:auto:triage-failed sort:created-asc" \
  --json number,title,body,labels,url,updatedAt
```

```bash
gh search issues \
  --repo <owner/repo> \
  --state open \
  --label auto:triage \
  --json number,title,body,labels,url,updatedAt \
  -- -label:auto:triaged -label:auto:triage-failed sort:created-asc
```

Rules:

- Exclude `auto:triaged` to avoid reprocessing successful issues even though `auto:triage` remains.
- Exclude `auto:triage-failed` so failures do not auto-retry.
- Sort oldest-first to keep the patrol deterministic.
- Fetch enough fields to avoid extra GitHub reads until a single issue is selected.

## Loop Model

For `--once`:

1. fetch eligible issues
2. process them sequentially up to `--limit`
3. exit after the queue is drained or the first fatal preflight failure

For continuous mode:

1. fetch eligible issues
2. process them sequentially up to `--limit`
3. sleep for `--interval`
4. repeat

The loop itself is long-lived, but the processing unit is always one issue.
If `--write-github off` is set, stop unless `--once` or `--dry-run` is also set.

## Single-Issue Transaction

For each selected issue:

0. Optionally prepare the transaction payload with `python3 scripts/triage_once.py prepare --issue <number>`.
1. Read the full issue via `gh issue view <number> --repo <resolved-owner/repo> --json number,title,body,url`.
2. Resolve transaction identifiers from the contract reference:
   - `plan_path`
   - `plan_label`
   - `triage_issue_key`
3. Check for an existing bd root by `triage_issue_key` metadata before creating anything new.
4. Run the plan stage by reusing `$gen-plan` logic:
   - derive `repo_slug` by replacing `/` in `<owner/repo>` with `--`
   - `python3 codex/skills/triage/scripts/triage_once.py seed-plan --issue <number>` may seed the first local plan shell
   - if `.plans/gh-<repo-slug>--<number>.md` exists, treat it as the primary source and use the issue body as upstream context
   - otherwise seed the first plan from the issue body
   - save the result back to `.plans/gh-<repo-slug>--<number>.md`
5. Run the beads stage by reusing `$gen-beads` logic:
   - require the resolved `plan_label`
   - create or update a plan-scoped epic and descendant tasks with `bd` only
   - keep the graph parallel-first and checkpoint-friendly
   - ensure every generated issue carries the same `plan_label`
6. Record bd metadata on the root epic so later cycles can find the existing graph.
7. Run `bd ready --label <plan_label> --type task --json` and capture the ready snapshot for handoff.
8. After the atomic mutation set, run:

```bash
bd dolt commit -m "triage: <resolved-owner/repo>#<number>"
bd dolt push
```

9. Apply GitHub writeback according to the state machine:
   - `python3 codex/skills/triage/scripts/triage_once.py apply-writeback ...` may perform the label/comment mutation
   - success: add `auto:triaged`, remove `auto:triage-failed` if present, post success comment
   - failure: add `auto:triage-failed`, post failure comment, do not auto-retry
10. Continue to the next issue.

## Plan Stage

Reuse the `$gen-plan` logic, not the literal skill invocation:

- target path is always `.plans/gh-<repo-slug>--<number>.md`
- existing local plan wins over issue body when both exist
- issue body seeds the first local plan when no plan exists yet
- the saved plan is the source of truth for the later beads stage

Keep the output normal Markdown. If you revise an existing local plan, preserve useful local context and only incorporate issue-body changes that strengthen the execution plan.

## Beads Stage

Reuse the `$gen-beads` logic, not the literal skill invocation:

- all issue creation and mutation goes through `bd`
- `plan_label` is mandatory
- prefer DAGs over serial chains
- add acceptance criteria and at least one validation signal to every created task
- add checkpoint/integration tasks when multiple workstreams must converge
- store `triage_issue_key`, `triage_plan_path`, and `triage_plan_label` as bd metadata on the root epic

When reopening an existing triaged issue for manual repair, update the existing graph rather than creating a duplicate plan scope.

Use metadata lookup as the first reconciliation path:

```bash
bd list \
  --type epic \
  --label <plan_label> \
  --metadata-field triage_issue_key=<owner>/<repo>#<number> \
  --json
```

## GitHub Writeback

Success path:

- add `auto:triaged`
- keep `auto:triage`
- remove `auto:triage-failed` if present
- post a `[triage:success]` comment using the required fields from the contract reference
- `python3 codex/skills/triage/scripts/triage_once.py writeback-success --issue <number> --epic-id <epic> --task-id <task>...` may apply the success writeback atomically
- helper entrypoint:

```bash
python3 codex/skills/triage/scripts/triage_once.py apply-writeback \
  --issue <number> \
  --status success \
  --epic-id <epic-id> \
  --task-id <task-id> --task-id <task-id>
```

Failure path:

- add `auto:triage-failed`
- keep `auto:triage`
- do not add `auto:triaged`
- post a `[triage:failed]` comment with the stop reason and recovery instruction
- do not auto-retry until a human clears the failure condition
- `python3 codex/skills/triage/scripts/triage_once.py writeback-failure --issue <number> --stop-reason <reason>` may apply the failure writeback atomically
- helper entrypoint:

```bash
python3 codex/skills/triage/scripts/triage_once.py apply-writeback \
  --issue <number> \
  --status failed \
  --stop-reason "<one-line reason>"
```

Skip/reconcile path:

- if the plan file and bd root already exist and represent the same `triage_issue_key`, repair labels/comments instead of creating a second graph
- post `[triage:skipped]` only when a no-op reconciliation still needs durable evidence

## Mesh Handoff

`$triage` ends at backlog production. It must leave enough information for `$mesh` to start without rereading the original GitHub issue:

- `plan_label`
- root epic id
- ready snapshot from `bd ready --label <plan_label> --type task --json`
- plan path
- GitHub source issue key

`$mesh` owns task execution after that point. `$triage` must not perform implementation, validation, PR creation, or review on behalf of the generated backlog.

## Validation

Run at least these checks before declaring the skill valid:

```bash
uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py codex/skills/triage
```

```bash
gh issue list \
  --repo <validation-owner/repo> \
  --state open \
  --label auto:triage \
  --search "-label:auto:triaged -label:auto:triage-failed sort:created-asc" \
  --json number,title,labels
```

```bash
python3 codex/skills/triage/scripts/triage_once.py \
  list \
  --repo <validation-owner/repo>  # optional override; defaults to cwd repo
```

```bash
python3 codex/skills/triage/scripts/triage_once.py \
  seed-plan \
  --repo <validation-owner/repo> \  # optional override; defaults to cwd repo
  --issue <number>
```

```bash
python3 codex/skills/triage/scripts/triage_once.py render-comment \
  --repo <validation-owner/repo> \  # optional override; defaults to cwd repo
  --issue <number> \
  --status failed \
  --stop-reason "validation"
```

Manual proof:

- walk one success scenario and show why the issue drops out of the eligibility query
- walk one failure scenario and show why the issue also drops out of the eligibility query until a human intervenes
- confirm the recorded `plan_label` is enough for `$mesh` to discover ready work
