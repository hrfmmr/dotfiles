# Task note templates

## Initial Task Note Structure (Phase 0 step 3)

```markdown
---
(frontmatter)
---

# <Task Name>

## Planning

### Snapshot
<!-- Written after grill-me snapshot is finalized -->

### Plan
<!-- Finalized execution plan -->

## Milestones

| bd_issue:: | summary:: | milestone_status:: |
|------------|-----------|-------------------|

## Dialogue
<!-- Turn-N headings appended here -->
```

## Turn-N Artifact Callouts

When a Turn produces a linkable artifact, append a dedicated callout block **inside the Turn-N** (after the Agent narrative, before the next Turn heading). This makes artifacts scannable on cold resume.

**Derived note** — learning note, investigation report, design doc:
```markdown
> [!note] Derived Note
> [[📝Derived Note Name]]
```

**PR** — pull request created or updated:
```markdown
> [!abstract] PR
> [#123 PR title](https://github.com/org/repo/pull/123)
```

**Branch task note** — sub-issue or delegated investigation:
```markdown
> [!info] Branch
> [[🔧Branch Task Note Name]]
```

Rules:
- One callout per artifact. A single Turn may contain multiple callouts.
- Place callouts at the **end** of the Agent section, after the narrative text.
- Use the exact callout type (`note` / `abstract` / `info`) for consistency across desk and desk-live.
