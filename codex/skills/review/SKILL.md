---
name: review
description: "Critical review gate for a target PR or current working artifact. Emit structured findings and decision (`approve|request_changes`) compatible with mesh Round E."
---

# Review

## Intent
Run a critical third-party review and return a strict decision artifact.

## Modes
- `pr-comment`: review a target PR and post consolidated review output.
- `artifact-report`: review current working artifact in-memory and return report to caller context.

## Required inputs
- `--mode pr-comment|artifact-report`
- one of:
  - `--target-pr <num>`
  - `--artifact <id>`

## Output contract (required)
- `decision: approve|request_changes`
- `findings` (array)
- `summary` (1-5 lines)

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
- codebase convention deviations
- technical judgment and rejected alternatives rationale

## Decision handling
- `approve`: no blocking findings.
- `request_changes`: include actionable MUST_FIX first.

## Integration notes
- Called by `join` after CI green and before handoff.
- If `BEADS_DIR` is present and `MUST_FIX` exists, caller may open/update bd issues.
