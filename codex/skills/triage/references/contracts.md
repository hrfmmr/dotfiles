# Triage Contracts

This document is the contract reference index for `$triage`.

## Source of truth

- GitHub state machine / idempotency:
  - `state-machine.md`
- plan / `plan_label` / handoff payload:
  - `handoff-contract.md`

## Derived identifiers

- `repo-slug`:
  - The stable string formed by replacing `/` in `owner/repo` with `--`
- `plan_path`:
  - `.plans/gh-<repo-slug>--<issue-number>.md`
- `plan_label`:
  - `plan:gh-<repo-slug>--<issue-number>`
- `triage_issue_key`:
  - `<owner/repo>#<issue-number>`

## bd metadata keys

The root epic must store at least the following keys.

- `triage_issue_key`
- `triage_plan_path`
- `triage_plan_label`

## GitHub bot comment families

- success:
  - `[triage:success]`
- failure:
  - `[triage:failed]`
- skip/reconcile:
  - `[triage:skipped]`

Each comment must include a stable sentinel so it can be rediscovered and updated on reruns.
