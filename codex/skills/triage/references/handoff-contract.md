# Triage Handoff Contract

This document is the source of truth for the artifact contract that `$triage` hands to `$mesh`.

## One issue, one scope

- The input unit is one GitHub issue.
- The output unit is one plan file, one `plan_label`, one root epic, and one task graph whose issues all share that same `plan_label`.

## Naming rules

- `repo-slug` is the stable string produced by replacing `/` in `owner/repo` with `--`.
- plan file path:
  - `.plans/gh-<repo-slug>--<issue-number>.md`
- `plan_label`:
  - `plan:gh-<repo-slug>--<issue-number>`

This naming scheme avoids issue-number collisions even when multiple repositories are handled.

## bd graph shape

- root epic:
  - one epic that groups the workstream for exactly one triaged issue
- tasks:
  - all share the same `plan_label`
  - include acceptance / design / notes
  - are selectable by `$mesh` via `bd ready --label <plan_label> --type task --json`

## GitHub writeback payload

The success bot comment must include the following fields.

- `issue_repo`
- `issue_number`
- `plan_path`
- `plan_label`
- `epic_id`
- `task_ids`
- `ready_query`
- `comment_sentinel`

`comment_sentinel` is the stable token used to rediscover the triage comment on reruns, so the existing comment can be updated instead of creating a new one.

## Handoff payload

The minimum payload handed to `$mesh` is:

- `issue_repo`
- `issue_number`
- `plan_path`
- `plan_label`
- `epic_id`
- `task_ids`
- `ready_query`
- `writeback_comment_locator`

## Ownership boundary

- `$triage` is responsible for translating a GitHub issue into a plan and a `bd` graph.
- After receiving the handoff payload, `$mesh` does not reinterpret the original GitHub issue text.
- `$mesh` begins task selection from `plan_label` and `ready_query`.
