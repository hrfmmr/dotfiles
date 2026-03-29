# Async Dialogue Protocol

## Q-ID Scheme

ID scheme for questions during the Planning phase and within Turn-N entries.
Follows the artifact rules established in the retrospective skill's dialogue protocol.

### ID Naming Convention

- Root questions: `Q-1`, `Q-2`, `Q-3`, ...
- Derived questions: `Q-1-1`, `Q-1-2`, `Q-2-1`, ... (branch structure expressing parent-child relationships)
- All headings are flat (same level) to enable full overview via Obsidian outline.

### State Management

Managed via Dataview inline fields:
- `status:: unanswered` — awaiting response
- `status:: done` — answered

### Note Layout (Planning Section)

```markdown
## Planning

> [!info] Async Response Guide
> Write your responses freely in each answer block.
> After writing, change `status:: unanswered` to `status:: done`.
> Once some or all answers are written, auto-detection kicks in (obsidian-git auto-commit → signal detection).

### Q-1: <question title>
status:: unanswered

> Write your response here

### Q-2: <question title>
status:: unanswered

> Write your response here

### Snapshot
<!-- Written after grill-me snapshot is finalized -->

### Plan
<!-- Finalized execution plan -->
```

### Per-round Updates

1. Read responses from questions marked `status:: done` and append Insight:

```markdown
### Q-1: <question title>
status:: done

> <user's response>

**Insight**: <derived implications>
```

2. Add derived questions as they emerge:

```markdown
### Q-1-1: <derived question title>
status:: unanswered

> Write your response here
```

3. Sync to bd issue:
```bash
bd edit <issue-id> --append-notes "Q-1: A=<answer summary> / Insight=<implications>"
bd edit <issue-id> --append-notes "New question: Q-1-1: <title>"
```

## Turn-N Protocol (Execution Phase)

Protocol for requesting human input during execution.

### Format

```markdown
### Turn-N
input:: pending

**Context**: <why this decision is needed>
**Question**: <specific question>
**Options**: <enumerate choices if applicable; omit otherwise>

> Write your response here. Change `input:: pending` to `input:: done` when finished.
```

### Agent Behavior

1. After writing Turn-N, transition to `status: human_response_required`.
2. Fire `terminal-notifier`.
3. If parallelizable sub-issues exist, continue work on those.
4. Check for signal file (`.desk/signals/<task-name>.ready`) at work-cycle boundaries.
5. On detection, verify `input:: done` in Turn-N, read the response, and resume.
6. Delete the signal file. Transition back to `status: in_progress`.

### Multiple Turns

Turns are appended sequentially. Prioritize the most recent unresolved Turn.

```markdown
### Turn-1
input:: done
...

### Turn-2
input:: pending
...
```
