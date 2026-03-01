---
name: mesh
description: >
  Standalone beads-native orchestration profile for single-task, in-session
  sub-agent execution with dependency-aware task selection, agent/slot ownership,
  gate-based waiting, and durable workflow evidence in bd.
---

# Beads Orchestration

This is a standalone skill definition for beads-native orchestration.
It is designed for:
- one task in flight at a time
- local in-session worker execution
- durable orchestration state stored in beads (`bd`)

Core principles:
- Beads is the source of truth for planning, progress, and decisions.
- Work scope is isolated by `plan_label` (preferred) or `parent_epic` (compatibility fallback).
- Runnable work is discovered by `bd ready --label <plan_label> --type task` (or `--parent <parent_epic>` in fallback mode).
- Ownership and coordination are expressed with agent/slot/gate/comments/swarm.
- Multi-stage orchestration continuity is preserved in orchestrator-managed in-memory artifacts.

## Delegation Policy (Required)

Implementation should be produced by spawned workers.
The orchestrator is responsible for:
- resolving execution scope (`plan_label` or `parent_epic`)
- selecting exactly one runnable task
- mediating propose/critique/synthesize/vote rounds
- applying accepted output and running validation
- persisting status and evidence to beads

Safety constraints:
- workers must not apply patches directly
- workers return artifacts (diffs, analysis, decisions)
- only the orchestrator performs final integration

Worker execution mode:
- preferred: in-session spawned workers (one role per worker)
- fallback: if worker spawning is unavailable, run roles sequentially in the same session while preserving the same artifact contract

## Branch Safety (Required)

- Do not merge to protected branches unless explicitly instructed.
- Do not push unless explicitly instructed.

## Operating Contract (Required)

This profile runs in fixed local-sequential mode:
- `adapter=local`
- `max_tasks=1`
- `parallel_tasks=1`

If the user asks for meta-editing of this skill file itself, do not run orchestration.
Perform the edit/review request directly.

## Invocation Contract (Required)

Supported user arguments:
- `plan_label=<label>`
- `parent_epic=<id>`
- `ids=<id1,id2,...>`
- `integrate=false`
- `strict_output=true|false`

Notes:
- `plan_file` is intentionally not used.
- execution scope is defined by label-based issue sets (`plan_label`).
- compatibility fallback: if labels were not provisioned at planning time, scope can be resolved by `parent_epic`.

`strict_output` semantics:
- when `strict_output=true`, each worker response must be parseable JSON with top-level keys:
  - `role`
  - `task_id`
  - `artifact`
  - optional `outbox`
- when `strict_output=false`, markdown is allowed but the orchestrator must still parse required fields and normalize into the in-memory artifact bus

## Defaults

Fixed:
- `adapter=local`
- `max_tasks=1`
- `parallel_tasks=1`

Behavioral defaults:
- `integrate=true`
- `strict_output=false`
- roles: `proposer,critic_a,critic_b,skeptic,synthesizer,reviewer`
- fallback roles: `proposer,skeptic,synthesizer`
- `consensus_threshold=4/5` (or `3/3` in fallback)
- `consensus_retries=2`
- `review_max_cycles=3`
- `review_required_for_close=true`
- reviewer role: `reviewer` (third-party perspective, independent from implementation ownership)

## Source of Truth and Scope (Required)

Rules:
- never hand-edit `.beads/*`
- mutate state only with `bd` commands
- unless this skill explicitly specifies a `bd` operation, execute it according to `$beads`

Scope resolution order:
1. invocation argument `plan_label=<label>`
2. environment variable `BD_PLAN_LABEL`
3. invocation argument `parent_epic=<id>`
4. otherwise stop and request `plan_label` or `parent_epic`

Prechecks before work:
- `bd where --json`
- `bd status --json`

If beads is unavailable, stop and recommend:
- `bd doctor --fix`

## Preflight Record (Required)

Emit one line before worker fanout:

`orch_preflight orch_run_id=... scope_mode=label|parent plan_label=... parent_epic=... selected_adapter=local selection_reason=fixed_local_profile requested_workers=... local_cap=1 ids=... overrides=max_tasks=1,parallel_tasks=1,adapter=local`

## Task Selection Policy (Required)

Run one task at a time:
1. scoped `in_progress` task first
2. otherwise first scoped ready task
3. if `ids` is provided, restrict candidates to those ids

Deterministic tie-break:
- sort candidates by `(priority asc, created_at asc, id asc)` before choosing the first

Recommended queries:
- `bd list --status in_progress --label <plan_label> --type task --json`
- `bd ready --label <plan_label> --type task --json`
- fallback (epic scope): `bd list --status in_progress --parent <parent_epic> --type task --json`
- fallback (epic scope): `bd ready --parent <parent_epic> --type task --json`

## Task Metadata Contract (Required)

Use issue fields as the orchestration contract:
- acceptance criteria: `--acceptance`
- design decisions: `--design`
- current state/notes: `--notes`

Persist round artifacts as comments with typed prefixes:
- `[orch:proposal]`
- `[orch:critique]`
- `[orch:synthesis]`
- `[orch:vote]`
- `[orch:proof]`
- `[orch:review]`
- `[orch:review-cycle]`
- `[orch:revision-plan]`
- `[orch:revision]`

If metadata is missing:
1. run a hydration round
2. update `acceptance/design/notes`
3. continue normal rounds

## In-Memory Artifact Bus (Required)

This profile requires a strict in-memory artifact contract across rounds.
Durable beads writes are checkpoints, not the active execution bus.

Per-task in-memory state must include:
- `task_id`
- `task_meta`
- `proposal`
- `critiques` (by role key: `critic_a`, `critic_b`, `skeptic`)
- `synthesis`
- `votes` (by role key)
- `reviews` (by cycle; each includes `decision`, `findings`, `summary`)
- `revision_plan` (current cycle)
- `review_issue` (parent review issue id, optional)
- `review_subtasks` (map: `finding_id -> issue_id`, optional)
- `mail` (optional orchestrator-mediated follow-up messages)
- `retry_counters` (`worker_retry`, `parse_retry`, `consensus_cycle`)
- `review_cycle` (current review cycle count)
- `history` (prior round artifacts for audit/debug)

Execution invariants:
- Round N must consume artifacts from Round N-1 in memory.
- Within one run, comments/notes are not the primary handoff mechanism between rounds.
- Every mutation to in-memory artifacts must be append-audited in `history`.
- If the run is interrupted, recovery can rebuild from beads comments, but live flow is memory-first.

Required handoff order:
1. `task_meta` -> Proposal
2. `proposal` -> Critique
3. `proposal + critiques` -> Synthesis
4. `synthesis` -> Vote
5. `vote consensus` -> Implementation/Validation
6. `validation result` -> Review Gate
7. `review decision` -> Integration decision

Worker outbox rule:
- A worker may return `outbox` messages.
- The orchestrator must deliver them via targeted follow-up before dependent next-round work.

## Agent and Ownership Model (Required)

Recommended structure:
- worker entities: `type=agent` with `gt:agent`
- role entities: `type=role` with `gt:role`
- role attachment: `bd slot set <agent> role <role>`
- work attachment: `bd slot set <agent> hook <task>`

Important:
- hook slot is 0..1 (clear before replacing)
- `bd agent state` requires valid agent labeling

## Round Protocol (Per Task)

### Round A: Proposal
- produce plan, assumptions, risk
- persist as `[orch:proposal]`
- required output fields:
  - `plan` (1-5 bullets)
  - `assumptions`
  - `risk` (`low|medium|high`)
  - optional `outbox`
- store the parsed artifact in memory as `proposal`

### Round B: Critique
- gather correctness, scope, and risk objections
- persist as `[orch:critique]`
- required output fields (per critic role):
  - `findings`
  - `must_fix`
  - `vote_flip_conditions`
  - `risk`
  - optional `outbox`
- store artifacts in memory under `critiques.<role>`

### Round C: Synthesis
- integrate accepted critique points
- output one unified diff or `NO_DIFF:<reason>`
- persist as `[orch:synthesis]`
- required output fields:
  - `decision_log` (accepted/rejected points + reason)
  - `patch` (exactly one unified diff block, or `NO_DIFF:<reason>`)
  - `validation_commands`
  - optional `outbox`
- store parsed artifact in memory as `synthesis`

### Round D: Vote
- each role returns `agree` or `disagree`
- purpose: design consensus on plan/architecture/risk tradeoffs
- non-goal: final artifact quality approval
- consensus rule:
  - 5-role set: `agree >= 4`
  - 3-role fallback: `agree == 3`
- retry up to `consensus_retries`
- if still failing, mark task `blocked` with reason `no_consensus`
- required output fields:
  - `vote: agree|disagree`
  - `reason` (one line)
- store votes in memory under `votes.<role>`
- do not emit final quality findings in this round

### Round E: Review Gate (Required)
- run reviewer subagent from a third-party perspective
- purpose: final artifact quality gate before closure
- non-goal: redesign debate; route design changes via `revision_plan` back to Vote
- reviewer evaluates:
  - bugs, spec deviations, regressions, security, performance, and missing tests
  - deviations from codebase conventions (naming, responsibility boundaries, exception handling, test style)
  - technical judgment points and why the chosen option is justified over alternatives
- required reviewer output:
  - `decision: approve|request_changes`
  - `findings` (array)
  - `summary` (1-5 lines)
- finding severity must be one of: `Critical|High|Medium|Low`
- finding label must be one of:
  - `MUST_FIX`: Must be addressed in this PR.
  - `SHOULD_CONSIDER`: Worth strong consideration in this PR.
  - `CAN_IGNORE`: No action needed at this time.
- each finding must include:
  - `finding_id`
  - `location` (`file:line`)
  - `severity`
  - `label`
  - `issue`
  - `evidence`
  - `minimal_fix`
  - `code_context` (short contextual code block; required)
- persist review artifacts as:
  - `[orch:review]`
  - `[orch:review-cycle]`
  - `[orch:revision-plan]`
  - `[orch:revision]`
- if no material issues are found, reviewer must explicitly state this in `summary`
- if `decision=request_changes`:
  1. create/update `revision_plan`
  2. run critique + vote consensus on the revision plan
  3. implement revisions
  4. rerun `validation_commands`
  5. run review again
- repeat until `approve` or `review_max_cycles` is reached

## Retry and Recovery Semantics (Required)

- `no_response`:
  - retry the same worker once (`worker_retry += 1`)
  - if still failing and 5-role mode is active, switch to fallback 3-role for this task
- `proposal_unparsable`:
  - one strict follow-up request
  - if still unparsable, block task with `proposal_unparsable`
- `no_diff_parsed`:
  - one strict follow-up request to synthesizer
  - if still unparsable, block task with `no_diff_parsed`
- `invalid_vote_shape`:
  - one strict follow-up per invalid vote
  - if unresolved, count as `disagree`
- `review_no_response`:
  - retry reviewer once
  - if still failing, block task with `review_no_response`
- `invalid_finding_shape`:
  - one strict follow-up request to reviewer
  - if still invalid, block task with `invalid_finding_shape`
- `no_consensus`:
  - rerun critique -> synthesis -> vote cycle
  - increment `consensus_cycle`
  - preserve prior cycle artifacts in `history`

Retry invariant:
- Retries must not overwrite prior artifacts destructively.
- Current-cycle artifacts are active; previous cycles remain queryable in memory history.

Review-cycle invariant:
- Every review cycle must append durable evidence to issue comments.
- Findings must remain traceable via stable `finding_id`.

## Integration, Validation, Persistence

When `integrate=false`:
- do not apply patch
- do not run validation
- do not mutate issue status
- return synthesis artifacts only

When `integrate=true`:
1. apply patch
2. run validation commands
3. require review approval when `review_required_for_close=true`
4. persist status transitions:
   - set `in_progress` at start if needed
   - `bd close <id> --reason "vote consensus + validation pass + review approve + no open MUST_FIX findings"` on success
   - `bd update <id> --status blocked` on failure

Close is allowed only when all are true:
- `vote_consensus=true`
- `validation_pass=true` (latest revision cycle)
- `review_decision=approve`
- `open_must_fix_findings=0`

Always append an outcome comment:
- outcome state
- vote tally
- validation command(s) and result
- review decision and review cycle count
- review issue/subtask linkage summary (if created)

Durability boundary:
- Beads stores durable checkpoints and resumability evidence.
- The orchestrator in-memory bus remains the authority for live multi-stage continuity.
- This split is intentional and must not be collapsed into comment-only handoffs.

## External Wait Handling (Gates)

Use gates for asynchronous or external conditions:
- create gate issue
- connect gate as blocker (`--type blocks`)
- resolve/check gate when condition is satisfied

This keeps waiting logic inside the dependency graph and preserves resumability.

## Review Findings Issue Flow (Required)

When review returns `request_changes` with findings:
1. create one parent review issue
2. create one child sub-task issue per finding
3. connect parent-child linkage only (do not substitute with `blocks`)
4. store created ids in the in-memory bus and append linkage evidence to comments
5. close child issues as each finding is resolved and re-reviewed
6. close the parent review issue only after all child finding issues are closed

## Known Caveats and Fallbacks

Observed in current CLI versions:
- `bd update --claim` may be unstable in some environments
- `bd merge-slot acquire` may fail in some environments

Operational fallback:
- use explicit transition: `bd update <id> --status in_progress --assignee <agent>`
- prefer single-joiner integration when merge-slot is unreliable

## Reporting Contract (Required)

Return:
- selected task and final state
- consensus cycles and vote tally
- validation commands and outcomes
- issue mutations performed
- preflight line including `orch_run_id`

## Error Handling

- missing `plan_label` and `parent_epic`: request one and stop
- beads unavailable: recommend `bd doctor --fix`
- no runnable task: report and exit cleanly
- no consensus after retries: set blocked (`no_consensus`)
- unparsable synthesis: one follow-up retry, then blocked
- review decision unparsable: one strict follow-up retry, then blocked (`review_unparsable`)
- review not approved within `review_max_cycles`: set blocked (`review_not_approved`)
- missing validation requirements: set blocked (`missing_validation_requirements`)

## Command Quick Reference

```bash
# find scoped runnable tasks
bd ready --label <plan_label> --type task --json
bd ready --parent <parent_epic> --type task --json  # fallback

# claim/start (primary)
bd update <id> --claim --json

# fallback start
bd update <id> --status in_progress --assignee <agent> --json

# ownership
bd slot set <agent-id> hook <task-id>
bd agent state <agent-id> working

# persist artifacts
bd comments add <task-id> "[orch:proposal] ..."
bd comments add <task-id> "[orch:critique] ..."
bd comments add <task-id> "[orch:vote] agree 4/5"
bd comments add <task-id> "[orch:review] decision=request_changes ..."

# gate flow
GATE_ID=$(bd create "Wait for external approval" --type gate --description "..." --json | jq -r '.id')
bd dep add <task-id> "$GATE_ID" --type blocks
bd gate resolve "$GATE_ID" --reason "approved"

# complete
bd close <task-id> --reason "vote consensus + validation pass + review approve + no open MUST_FIX findings"
```

