# Common Usage Patterns

Practical patterns for using bd effectively across different scenarios.

Terminology note: "session checklist" means a lightweight per-session checklist.

## Contents

- [Knowledge Work Session](#knowledge-work-session) - Resume long-running research or writing tasks
- [Side Quest Handling](#side-quest-handling) - Capture discovered work without losing context
- [Multi-Session Project Resume](#multi-session-project-resume) - Pick up work after time away
- [Status Transitions](#status-transitions) - When to change issue status
- [Compaction Recovery](#compaction-recovery) - Resume after conversation history is lost
- [Issue Closure](#issue-closure) - Documenting completion properly

---

## Knowledge Work Session

**Scenario**: User asks "Help me write a proposal for expanding the analytics platform"

**What you see**:
```bash
$ bd ready
# Returns: bd-42 "Research analytics platform expansion proposal" (in_progress)

$ bd show bd-42
Notes: "COMPLETED: Reviewed current stack (Mixpanel, Amplitude)
IN PROGRESS: Drafting cost-benefit analysis section
NEXT: Need user input on budget constraints before finalizing recommendations"
```

**What you do**:
1. Read notes to understand current state
2. Create session checklist for immediate work:
   ```
   - [ ] Draft cost-benefit analysis
   - [ ] Ask user about budget constraints
   - [ ] Finalize recommendations
   ```
3. Work on tasks, mark session checklist items completed
4. At milestone, update bd notes:
   ```bash
   bd update bd-42 --notes "COMPLETED: Cost-benefit analysis drafted.
   KEY DECISION: User confirmed $50k budget cap - ruled out enterprise options.
   IN PROGRESS: Finalizing recommendations (Posthog + custom ETL).
   NEXT: Get user review of draft before closing issue."
   ```

**Outcome**: session checklist disappears at session end, but bd notes preserve context for next session.

**Key insight**: Notes field captures the "why" and context, session checklist tracks the "doing" right now.

---

## Side Quest Handling

**Scenario**: During main task, discover a problem that needs attention.

**Pattern**:
1. Create issue immediately: `bd create "Found: inventory system needs refactoring"`
2. Link provenance: `bd dep add new-issue main-task --type discovered-from`
3. Assess urgency: blocker or can defer?
4. **If blocker**:
   - `bd update main-task --status blocked`
   - `bd update new-issue --status in_progress`
   - Work on the blocker
5. **If deferrable**:
   - Note in new issue's design field
   - Continue main task
   - New issue persists for later

**Why this works**: Captures context immediately (before forgetting), preserves relationship to main work, allows flexible prioritization.

**Example (with MCP):**

Working on "Implement checkout flow" (checkout-1), discover payment validation security hole:

1. Create bug issue: beads MCP `create` tool with `{title: "Fix: payment validation bypasses card expiry check", type: "bug", priority: 0}`
2. Link discovery: beads MCP `dep` tool with `{from_issue: "checkout-1", to_issue: "payment-bug-2", type: "discovered-from"}`
3. Block current work: beads MCP `update` tool with `{issue_id: "checkout-1", status: "blocked", notes: "Blocked by payment-bug-2: security hole in validation"}`
4. Start new work: beads MCP `update` tool with `{issue_id: "payment-bug-2", status: "in_progress"}`

(CLI: `bd create "Fix: payment validation..." -t bug -p 0` then `bd dep add` and `bd update` commands)

---

## Multi-Session Project Resume

**Scenario**: Starting work after days or weeks away from a project.

**Pattern (with MCP)**:
1. **Check what's ready**: Use beads MCP `ready` tool to see available work
2. **Check what's stuck**: Use beads MCP `blocked` tool to understand blockers
3. **Check recent progress**: Use beads MCP `list` tool with `status:"closed"` to see completions
4. **Read detailed context**: Use beads MCP `show` tool for the issue you'll work on
5. **Update status**: Use beads MCP `update` tool with `status:"in_progress"`
6. **Begin work**: Create session checklist from notes field's NEXT section

(CLI: `bd ready`, `bd blocked`, `bd list --status closed`, `bd show <id>`, `bd update <id> --status in_progress`)

**Example**:
```bash
$ bd ready
Ready to work on (3):
  auth-5: "Add OAuth refresh token rotation" (priority: 0)
  api-12: "Document REST API endpoints" (priority: 1)
  test-8: "Add integration tests for payment flow" (priority: 2)

$ bd show auth-5
Title: Add OAuth refresh token rotation
Status: open
Priority: 0 (critical)

Notes:
COMPLETED: Basic JWT auth working
IN PROGRESS: Need to add token refresh
NEXT: Implement rotation per OWASP guidelines (7-day refresh tokens)
BLOCKER: None - ready to proceed

$ bd update auth-5 --status in_progress
# Now create session checklist based on NEXT section
```

**For complete session start workflow with checklist, see:** [WORKFLOWS.md](WORKFLOWS.md#session-start)

---

## Status Transitions

Understanding when to change issue status.

### Status Lifecycle

```
open → in_progress → closed
  ↓         ↓
blocked   blocked
```

### When to Use Each Status

**open** (default):
- Issue created but not started
- Waiting for dependencies to clear
- Planned work not yet begun
- **Command**: Issues start as `open` by default

**in_progress**:
- Actively working on this issue right now
- Has been read and understood
- Making commits or changes related to this
- **Command**: `bd update issue-id --status in_progress`
- **When**: Start of work session on this issue

**blocked**:
- Cannot proceed due to external blocker
- Waiting for user input/decision
- Dependency not completed
- Technical blocker discovered
- **Command**: `bd update issue-id --status blocked`
- **When**: Hit a blocker, capture what blocks you in notes
- **Note**: Document blocker in notes field: "BLOCKER: Waiting for API key from ops team"

**closed**:
- Work completed and verified
- Tests passing
- Acceptance criteria met
- **Command**: `bd close issue-id --reason "Implemented with tests passing"`
- **When**: All work done, ready to move on
- **Note**: Issues remain in database, just marked complete

### Transition Examples

**Starting work**:
```bash
bd ready  # See what's available
bd update auth-5 --status in_progress
# Begin working
```

**Hit a blocker**:
```bash
bd update auth-5 --status blocked --notes "BLOCKER: Need OAuth client ID from product team. Emailed Jane on 2025-10-23."
# Switch to different issue or create new work
```

**Unblocking**:
```bash
# Once blocker resolved
bd update auth-5 --status in_progress --notes "UNBLOCKED: Received OAuth credentials. Resuming implementation."
```

**Completing**:
```bash
bd close auth-5 --reason "Implemented OAuth refresh with 7-day rotation. Tests passing. PR #42 merged."
```

---

## Compaction Recovery

**Scenario**: Conversation history has been compacted. You need to resume work with zero conversation context.

**What survives compaction**:
- All bd issues and notes
- Complete work history
- Dependencies and relationships

**What's lost**:
- Conversation history
- session checklist lists
- Recent discussion

### Recovery Pattern

1. **Check in-progress work**:
   ```bash
   bd list --status in_progress
   ```

2. **Read notes for context**:
   ```bash
   bd show issue-id
   # Read notes field - should explain current state
   ```

3. **Reconstruct session checklist from notes**:
   - COMPLETED section: Done, skip
   - IN PROGRESS section: Current state
   - NEXT section: **This becomes your session checklist list**

4. **Report to user**:
   ```
   "From bd notes: [summary of COMPLETED]. Currently [IN PROGRESS].
   Next steps: [from NEXT]. Should I continue with that?"
   ```

### Example Recovery

**bd show returns**:
```
Issue: bd-42 "OAuth refresh token implementation"
Status: in_progress
Notes:
COMPLETED: Basic JWT validation working (RS256, 1hr access tokens)
KEY DECISION: 7-day refresh tokens per security review
IN PROGRESS: Implementing token rotation endpoint
NEXT: Add rate limiting (5 refresh attempts per 15min), then write tests
BLOCKER: None
```

**Recovery actions**:
1. Read notes, understand context
2. Create session checklist:
   ```
   - [ ] Implement rate limiting on refresh endpoint
   - [ ] Write tests for token rotation
   - [ ] Verify security guidelines met
   ```
3. Report: "From notes: JWT validation is done with 7-day refresh tokens. Currently implementing rotation endpoint. Next: add rate limiting and tests. Should I continue?"
4. Resume work based on user response

**For complete compaction survival workflow, see:** [WORKFLOWS.md](WORKFLOWS.md#compaction-survival)

---

## Issue Closure

**Scenario**: Work is complete. How to close properly?

### Closure Checklist

Before closing, verify:
- [ ] **Acceptance criteria met**: All items checked off
- [ ] **Tests passing**: If applicable
- [ ] **Documentation updated**: If needed
- [ ] **Follow-up work filed**: New issues created for discovered work
- [ ] **Key decisions documented**: In notes field

### Closure Pattern

**Minimal closure** (simple tasks):
```bash
bd close task-123 --reason "Implemented feature X"
```

**Detailed closure** (complex work):
```bash
# Update notes with final state
bd update task-123 --notes "COMPLETED: OAuth refresh with 7-day rotation
KEY DECISION: RS256 over HS256 per security review
TESTS: 12 tests passing (auth, rotation, expiry, errors)
FOLLOW-UP: Filed perf-99 for token cleanup job"

# Close with summary
bd close task-123 --reason "Implemented OAuth refresh token rotation with rate limiting. All security guidelines met. Tests passing."
```

### Documenting Resolution (Outcome vs Design)

For issues where the outcome differed from initial design, use `--notes` to document what actually happened:

```bash
# Initial design was hypothesis - document actual outcome in notes
bd update bug-456 --notes "RESOLUTION: Not a bug - behavior is correct per OAuth spec. Documentation was unclear. Filed docs-789 to clarify auth flow in user guide."

bd close bug-456 --reason "Resolved: documentation issue, not bug"
```

**Pattern**: Design field = initial approach. Notes field = what actually happened (prefix with RESOLUTION: for clarity).

### Discovering Follow-up Work

When closing reveals new work:

```bash
# While closing auth feature, realize performance needs work
bd create "Optimize token lookup query" -t task -p 2

# Link the provenance
bd dep add perf-99 auth-5 --type discovered-from

# Now close original
bd close auth-5 --reason "OAuth refresh implemented. Discovered perf optimization needed (filed perf-99)."
```

**Why link with discovered-from**: Preserves the context of how you found the new work. Future you will appreciate knowing it came from the auth implementation.

---

## Pattern Summary

| Pattern | When to Use | Key Command | Preserves |
|---------|-------------|-------------|-----------|
| **Knowledge Work** | Long-running research, writing | `bd update --notes` | Context across sessions |
| **Side Quest** | Discovered during other work | `bd dep add --type discovered-from` | Relationship to original |
| **Multi-Session Resume** | Returning after time away | `bd ready`, `bd show` | Full project state |
| **Status Transitions** | Tracking work state | `bd update --status` | Current state |
| **Compaction Recovery** | History lost | Read notes field | All context in notes |
| **Issue Closure** | Completing work | `bd close --reason` | Decisions and outcomes |

**For detailed workflows with step-by-step checklists, see:** [WORKFLOWS.md](WORKFLOWS.md)
