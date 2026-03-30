# Desk Sequence Diagrams

## 1. Normal Execution Flow (happy path)

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant E1 as Executor (session 1)
    participant TN as Task Note
    participant BD as bd issue
    participant Hook as Stop Hook

    H->>R: $desk run <task>
    R->>TN: Read frontmatter + latest Turn
    R->>BD: bd show <issue-id>
    R->>R: Create .desk/runtime/<task>.lock
    R->>E1: Agent tool (run_in_background)
    R-->>H: (idle — human can interact)

    activate E1
    E1->>TN: Read context (cold resume)
    E1->>E1: $tk → $review → $commit
    E1->>BD: bd comments add <commit-hash>
    E1->>TN: Update frontmatter (heartbeat)
    E1->>E1: Work complete
    E1->>TN: status: done / in_review
    E1->>R: Delete .desk/runtime/<task>.lock
    deactivate E1

    Note over R,Hook: Root session goes idle
    Hook->>Hook: Check signals + locks → allow
    Hook-->>R: {"decision":"allow"}
```

## 2. Human Input Required → Cold Resume

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant E1 as Executor (session 1)
    participant TN as Task Note
    participant OG as obsidian-git
    participant CS as check-signals.sh
    participant Hook as Stop Hook
    participant E2 as Executor (session 2)

    Note over E1: During execution, needs human judgment
    activate E1
    E1->>TN: Append Turn-N (input:: pending)
    E1->>TN: status: human_response_required
    E1->>E1: Delete .desk/runtime/<task>.lock
    E1->>H: terminal-notifier 📬
    E1->>E1: Terminate ✓
    deactivate E1

    Note over H: Human reads Turn-N in Obsidian
    H->>TN: Write response, change input:: done
    Note over H,OG: ≈3 min (auto-commit interval)
    OG->>OG: auto-commit fires
    OG->>CS: post-commit hook
    CS->>CS: Detect input:: done in diff
    CS->>CS: Create .desk/signals/<task>.ready

    Note over R,Hook: Root session goes idle
    Hook->>Hook: Check .desk/signals/ → found!
    Hook-->>R: {"decision":"block","reason":"$desk run <task>"}

    R->>TN: Read frontmatter + latest Turn (with response)
    R->>BD: bd show <issue-id>
    R->>R: Create .desk/runtime/<task>.lock
    R->>R: Delete .desk/signals/<task>.ready
    R->>E2: Agent tool (run_in_background)
    R-->>H: (idle)

    activate E2
    E2->>TN: Read Turn-N response
    E2->>E2: Continue work with human's answer
    E2->>E2: $tk → $review → $commit
    deactivate E2
```

## 3. Agent Crash → Auto-Recovery

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant E1 as Executor (session 1)
    participant Hook as Stop Hook
    participant E2 as Executor (session 2)
    participant TN as Task Note

    R->>E1: Agent tool (run_in_background)
    activate E1
    Note over E1: .desk/runtime/<task>.lock exists (pid:12345)
    E1->>E1: Working...
    E1->>E1: 💥 Crash (session dies)
    deactivate E1
    Note over E1: Lock remains, PID 12345 is dead

    Note over R,Hook: Root session goes idle
    Hook->>Hook: Check locks → pid:12345 dead!
    Hook-->>R: {"decision":"block","reason":"$desk run <task> --force"}

    R->>R: Delete stale .desk/runtime/<task>.lock
    R->>TN: Read frontmatter + latest Turn
    R->>R: Create new .desk/runtime/<task>.lock
    R->>E2: Agent tool (run_in_background)
    R-->>H: (idle)

    activate E2
    E2->>TN: Cold resume from last checkpoint
    E2->>E2: Continue work
    deactivate E2
```

## 4. Heartbeat Stale → Notification (no auto-action)

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant E1 as Executor (session 1)
    participant Hook as Stop Hook

    R->>E1: Agent tool (run_in_background)
    activate E1
    Note over E1: Lock exists, PID alive, but no heartbeat update >15min

    Note over R,Hook: Root session goes idle
    Hook->>Hook: Check locks → pid alive but heartbeat stale
    Hook->>H: terminal-notifier ⚠️ "Agent hung?"
    Hook-->>R: {"decision":"allow"}
    Note over R: Does NOT auto-recover (human decides)

    H->>R: $desk run <task> --force
    R->>R: Delete old lock, spawn new executor
    deactivate E1
```

## 5. $desk ps — Observability

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant PS as desk_ps.sh
    participant TN as Task Notes (*.md)
    participant RT as .desk/runtime/*.lock

    H->>R: $desk ps
    R->>PS: bash desk_ps.sh <vault>
    PS->>TN: grep -l '^status:' *.md
    PS->>TN: Extract frontmatter fields per note
    PS->>RT: Check lock files + kill -0 <pid>
    PS-->>R: Formatted table
    R-->>H: Display table
```

## 6. Full Lifecycle (Init → Done)

```mermaid
sequenceDiagram
    participant H as Human
    participant R as Root Session
    participant P as Planner
    participant E as Executor(s)
    participant TN as Task Note
    participant BD as bd issue

    H->>R: $desk new
    R->>TN: Create note (status: plan_ready)
    R->>BD: bd create epic

    H->>R: $desk run <task>
    R->>P: Spawn planner
    activate P
    P->>TN: Write Q-1..Q-N (status:: unanswered)
    P->>P: Terminate
    deactivate P

    Note over H: Async: answer questions in Obsidian
    Note over H,R: ... signal → Stop Hook → cold resume ...

    R->>P: Spawn planner (cold resume)
    activate P
    P->>TN: Write Snapshot + Plan + Milestones
    P->>TN: status: in_progress
    P->>P: Terminate
    deactivate P

    loop Cold resume chain (N sessions)
        Note over R: Stop Hook or $desk run
        R->>E: Spawn executor
        activate E
        E->>E: $tk → $review → $commit
        E->>BD: Checkpoint notes
        alt Human input needed
            E->>TN: Turn-N (input:: pending)
            E->>E: Terminate
            deactivate E
            Note over H: Respond → signal → resume
        else Work unit done
            E->>TN: Update milestones
            E->>E: Terminate
            deactivate E
        end
    end

    Note over R: All milestones complete
    R->>E: Spawn finisher
    activate E
    E->>TN: Final Turn-N (human check gate)
    E->>E: Terminate
    deactivate E

    H->>TN: Approve (input:: done)
    Note over H,R: ... signal → Stop Hook ...
    R->>E: Spawn finisher (cold resume)
    activate E
    E->>BD: Close epic
    E->>TN: status: done
    E->>E: Terminate
    deactivate E
```

## Message Types Summary

| channel | direction | sync/async | mechanism |
|---------|-----------|------------|-----------|
| Human → Root | sync | human types in CLI | direct input |
| Root → Executor | async | Agent tool (background) | spawn + terminate |
| Executor → Human | async | Turn-N in task note | obsidian notification |
| Human → Executor | async | input:: done → signal → cold resume | obsidian-git → hook → Stop Hook |
| Stop Hook → Root | sync | block + reason injection | hooks.Stop JSON |
| Executor → bd | sync | bd comments add | CLI within session |
| Executor → Task Note | sync | file write | Edit/Write tool |
