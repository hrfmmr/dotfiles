# Task note templates

## Initial Task Note Structure (Init step 4)

```markdown
---
(frontmatter — see SKILL.md)
---

# <Task Name>

## 現在地

- **位置**: M0/N (not started)
- **未決の論点**: D-1, D-2
- **残TODO**: N件 — 次: <next item>
- **Next Action (human)**:
- **Next Action (agent)**:
- **as of**: Turn-1

## 設計

### 問題定義
<!-- one line -->

### 成功基準
<!-- testable completion conditions -->

### 前提 (Facts)
<!-- verified facts, constraints, links -->

### 設計方針・構成
<!-- whole-picture diagram (mermaid) first, then the current design; rewrite in place as it changes -->

## Milestones

| bd_issue:: | summary:: | milestone_status:: |
|------------|-----------|-------------------|

## 論点

#### D-1 <topic>
decision_status:: open
- 問い:
- 選択肢:
- 判断:
- 根拠:
- 影響先:

## Event Log
<!-- Turn-N headings appended here, one per progress event -->
```

## 論点 lifecycle

- `decision_status::` is one of `open | decided | superseded | dropped`. Do not use bare `status::` (collides with frontmatter `status` in Dataview).
- Decide: fill 判断 / 根拠 / 影響先 and set `decided`.
- Overturn: set the original to `superseded` and add `→ D-m`; add `D-m` with `supersedes D-n` in its 問い.
- Drop: set `dropped` with the reason; name the follow-up bd issue if one was opened.

## Turn-N format

```markdown
### Turn-N <yyyy-MM-dd HH:mm JST> — <the before/after, not the editing action>
- <the before/after that made this an event>
  - <finding 1 — concretely what it is, and the consequence if left unaddressed>
  - <finding 2 — same>
- Updated: D-2 → decided; M3 → done; status → in_review; 設計 > 設計方針・構成
```

Writing rules (plain language, one concrete finding per bullet, omit delegation mechanics, defer detail to 論点): see `SKILL.md` `### Turn format`.

## Turn-N Artifact Callouts

When a Turn produces a linkable artifact, append a dedicated callout block at the end of the Turn (after the bullets, before the next Turn heading). This makes artifacts scannable on cold resume.

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
- Use the exact callout type (`note` / `abstract` / `info`) for consistency.
