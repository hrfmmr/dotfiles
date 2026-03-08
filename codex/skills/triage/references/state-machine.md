# Triage State Machine

This document is the source of truth for `$triage`'s GitHub state machine and idempotency contract.

## Repository guardrail

- This skill operates on issues in the target repository resolved from the current cwd by default.
- Repository-specific allow / deny policy belongs to the turn context, not to the skill text itself.

## Selection rule

Only issues that satisfy all of the following conditions are eligible for triage.

- Has `auto:triage`
- Does not have `auto:triaged`
- Does not have `auto:triage-failed`
- Does not already have a triage completion marker derived from a bot comment

This prevents the patrol loop from selecting issues that already succeeded or have already been stopped on failure.

## States

| State | Observable marker | Meaning |
| --- | --- | --- |
| queued | `auto:triage` present, `auto:triaged` / `auto:triage-failed` absent | waiting for triage |
| running | triage is in progress within a single-issue transaction | triage running |
| triaged | `auto:triaged` present and a success bot comment exists | triage completed successfully |
| failed | `auto:triage-failed` present or a failure bot comment exists | triage stopped on failure |

## Transitions

### Success

- Preconditions:
  - the issue satisfies the selection rule
  - plan generation or update succeeds
  - `bd` graph generation succeeds
  - `bd dolt commit` and `bd dolt push` succeed
- Writes:
  - add `auto:triaged`
  - keep `auto:triage`
  - add or update the bot comment
- Bot comment must include:
  - issue number
  - plan path
  - `plan_label`
  - epic ID
  - primary task IDs

### Failure

- Failure means any error before the success writes complete.
- Writes:
  - add or update the failure comment
  - add `auto:triage-failed`
- Policy:
  - do not auto-retry
  - use both the selection rule and the failure marker so the next patrol cycle does not pick the same issue back up automatically

## Idempotency rules

- Collapse success output into one triage comment per issue.
- When rerunning the same issue, update the existing triage comment instead of creating a new one first.
- Generate `plan_label` deterministically from the issue number.
- Update the bead ID list in the bot comment to reflect the IDs confirmed by the current run.
- Only perform successful triage writeback after Dolt push succeeds.

## Operational notes

- Failure-stop exists to preserve visible failure, not to implement automatic backoff.
- Triage completion includes successful Dolt push, not just GitHub writeback.
- Do not run the continuous loop with `--write-github off`, because success / failure markers would not be written to GitHub and the next cycle could triage the same issue again.
