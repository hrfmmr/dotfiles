## Conversation rules

- Provide all answers in Japanese

## Problem-Solving Default: Double Diamond

Use Double Diamond to avoid converging too early: separate "are we solving the right problem?" from "are we building the right thing?"

- Discover (diverge): gather evidence and broaden the problem space (repo reading/search, repro, constraints).
- Define (converge): lock a one-line problem statement + success criteria (contract/invariants/acceptance).
- Develop (diverge): generate options/prototypes when there are real trade-offs.
- Deliver (converge): implement, validate, and ship with a proof trail.

## Skill routing

- Discover/Define: `$grill-me`, `$tk`(advice-mode)
- Develop: `$creative-problem-solver` (five-tier portfolio)
- Planning/Issue tracking: `$gen-plan`, `$gen-beads`, `$beads`
- Deliver: `$tk`, `$commit`

## Issue Tracking

If the `BEADS_DIR` environment variable is present, this project adopts `bd` based issue management.
Before performing any issue-related operations, execute:

`echo $BEADS_DIR`

If the command returns a valid path, follow the beads workflow defined in the `$beads` skill and use `bd` for issue management.
If no path is returned, do not use beads for issue tracking.
