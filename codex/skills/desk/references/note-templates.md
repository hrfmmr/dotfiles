# Task note templates

## Initial Task Note Structure (Init step 4)

```markdown
---
(frontmatter — see SKILL.md)
---

# <Task Name>

## 現在地

<!-- 状況: 2〜5 文の文章。何の課題で、これまでに何が分かり・決まり、いまどこで進んでいる／止まっているか、次に誰が何をするか。この段落だけで言えるように書く -->

- **位置**: M0/N (not started)
- **未決の論点**: D-1 <topic in words>, D-2 <topic in words>
- **残TODO**: N件 — 次: <next item, as a sentence>
- **Next Action (human)**: <what to do, where, why it is needed, how to know it is done — only what is still open; nested bullets when more than one>
- **Next Action (agent)**:
- **as of**: Turn-1

## 設計

### 背景
<!-- prose: who is in trouble, what happens now, why it matters, and why this task exists. Facts the reader needs before 問題定義 -->

### 問題定義
<!-- one line -->

### 成功基準
<!-- testable completion conditions -->

### 前提 (Facts)
<!-- verified facts, constraints, links — each fact as a sentence saying what is known, how it was confirmed, and when; see references/writing-for-recap.md -->

### 設計方針・構成
<!-- whole-picture diagram (mermaid) first, then the current design; rewrite in place as it changes -->

## Milestones

| bd_issue:: | summary:: | milestone_status:: |
|------------|-----------|-------------------|

## 論点

#### D-1 <topic — named so the reader sees what is being decided>
decision_status:: open
- 問い: <what must be decided, why it matters now, what changes depending on the answer>
- 選択肢:
  - A <name>: <what it is; its benefit; what it costs or risks>
  - B <name>: <same>
- 判断: <open: 未決。推奨とその理由、まだ分かっていないこと / decided: the chosen option and who decided>
- 根拠: <confirmed facts, source statements, and inference, kept apart>
- 影響先: <what this decision changes>

## Event Log
<!-- Turn-N headings appended here, one per progress event -->
```

## 論点 lifecycle

Field-writing rules (explanation, one bullet per option, certainty kept visible) and a worked example: `references/writing-for-recap.md`.

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
