# Plan layout

How a desk task note shows a plan so a cold reader sees, top to bottom, why the task exists → what it must solve → what changes when it is done → what was decided → how it proceeds → where it stands. The contract is in `SKILL.md` `### Plan layout`; this file holds the recipes.

Applies to a **planned task**: impl, or research with stages or several 論点 — work where a plan comes before execution. A small task (one fix) and adhoc may use any part of it but need none.

## Where each part lives

| part | place in the note | written when |
|---|---|---|
| 完了イメージ (before / after) | `## 設計` > `### 完了イメージ (before / after)`, right after 成功基準 | Init: the before diagram, and the after diagram when it can already be drawn. Plan approval: finalize both. |
| 論点の一覧 | top of `## 論点`, above the first `#### D-n` entry | Seed 論点 (Init step 3): one row per placeholder. Each decision: update its row. |
| 計画の段階 | `## Milestones` rows (one stage per row) and the derived note `段階ごとの構成図` linked from 設計方針・構成 | Plan approval |
| A stage's own plan | a stage design note per stage that needs one (see Nesting a stage's plan), linked from its Milestone row | When the stage turns out to need its own design |
| Execution state | 現在地 and Milestones only | During execution |

During execution, do not rewrite 完了イメージ, the 論点 rows, or the staged-diagram note unless the design itself changes (an event; see Event Gate). A changed design updates the diagrams in the same gate.

## 完了イメージ (before / after)

Shows, right after 背景 and 成功基準, what the task changes.

- One lead sentence: these are the current shape and the shape when this task is done; intermediate shapes are in the staged-diagram note (when one exists).
- `#### 今の形 (before)`: one mermaid diagram. Draw what exists today as `old`. Under it, a one-line `> ` caption: what is missing and what that costs.
- `#### 完了したときの形 (この task の範囲)`: one mermaid diagram on **the same skeleton** as before (same node names, same arrangement), with what this task adds (`new`), what it retires (`gone`), and what is undecided or built by another task (`unk`) overlaid. Under it, a one-line caption, then point to 成功基準 as the completion conditions instead of restating them; if the diagram shows a condition 成功基準 lacks, add it to 成功基準.
- Keep both diagrams at the same grain. Leave fine paths (individual endpoints, per-file detail) to the staged-diagram note. Drop lines that do not bear on the difference.
- Arrows: solid for communication and data flow; dotted for everything else (checks, reads, permissions, monitoring).
- The Design Briefing rules apply (render and look; 5–12 nodes; no `#` in node or edge text). The color codes inside `classDef` lines are the one allowed `#`.

```
classDef new fill:#fde68a,stroke:#b45309,color:#111
classDef old fill:#e5e7eb,stroke:#6b7280,color:#111
classDef gone fill:#ffffff,stroke:#9ca3af,stroke-dasharray:4 3,color:#6b7280
classDef unk fill:#dbeafe,stroke:#2563eb,color:#111
```

Legend to put once above the diagrams (and atop the staged-diagram note): 黄 = この task で足すもの、灰 = 前からあるもの、点線の白 = やめるもの、青 = 未決のものやほかの task が作るもの。

## 論点の一覧

A table above the entries, so the reader sees every decision at a glance before reading any entry. Each row points to its entry; detail stays in the entry.

```markdown
| 論点 | これは何か (背景と問題意識) | 判断 | 理由・根拠 |
|---|---|---|---|
| D-1 <topic> | <what is being decided, a short gloss of each mechanism it involves, and what the worry is> | <decided: the chosen option in one sentence / open: 未決 (推奨: <option>)> | <one or two sentences: the reason and the main evidence (official docs, measurement, who decided and when)> |
```

- **これは何か** is written for an engineer reading it for the first time: gloss each term before using it (`接続プールは、DB への接続を使い回すために前もって開いておく接続の束です`) and state the worry as `心配なのは、〜ことです`. Length is fine; do not compress it into jargon.
- A superseded or dropped 論点 keeps its row with the status in the 判断 cell (`superseded → D-4`, `dropped: <reason>`).
- The 判断 cell must agree with the entry's `decision_status::` and 判断 field; update both in the same write.

## 論点 entry additions

On top of the fields in `references/note-templates.md`:

- **判断 on a decided entry** also says, per option not taken, why it was not taken (one bullet each).
- **残ること**: what is still open after the decision, or what execution must confirm (which milestone, which check). Omit the field when nothing remains.
- An assigned D-id is never renumbered. A new topic takes the next number; a withdrawn one stays as `dropped`.

## 計画の段階 (staged plans)

When the plan proceeds in stages, each Milestone row is one stage, named the same everywhere (Milestones, the staged-diagram note, 現在地 位置). In 設計方針・構成, list the stages as a numbered list (one line each, marking any stage that needs a human hand, e.g. `本番への反映 (人)`) and link the derived note.

The derived note `<task prefix>--段階ごとの構成図` (create it per `### Derived notes`) holds:

1. A legend callout: the color and arrow legend above, with the same `classDef`.
2. `## 全体の流れ (最後の形)`: one diagram.
3. `## 今の形 (before)`: the same diagram as 完了イメージ's before.
4. One `## 段階 N <name>` per stage: bullets for 前の段階からの違い / 始める前の条件 / 確かめること, then the diagram, a one-line caption, and a `データの流れ:` paragraph.
5. `## 段階ごとの要約`: a table (段階 / 足すもの / やめるもの / 始める前の条件 / 人の手).

A plan with no stages (one step) skips this note; 完了イメージ is enough.

## Nesting a stage's plan

A stage can itself be a sizable design task — its own decisions, its own before/after, its own sub-stages. Do not pour that detail into the root note: give the stage a **stage design note** that repeats the root's plan layout one level down, so the root stays the overview and the reader can move whole ↔ detail at every level.

- **When**: the stage has 論点 of its own, or its design no longer fits a few lines in the staged-diagram note. A stage that is only execution needs no note.
- **Name and links**: `<task prefix>--<Mn> <stage name>` (a derived note; inherit `#prj-*` tags). Its first line is a breadcrumb back to the parent (`↑ [[<parent note>]] > <Mn> <stage name>`). The parent links down from the stage's Milestone row (`summary:: <Mn> <stage name> → [[<stage note>]]`), from the stage's section in the staged-diagram note, and from 設計方針・構成.
- **Contents, same order as the root**: `## 背景` (why this stage exists, pointing to the parent rather than retelling it) → `## 問題定義` → `## 成功基準` (the stage's done conditions) → `## 完了イメージ (before / after)` (before = the shape this stage starts from, i.e. the previous stage's after; after = this stage's after in the staged-diagram note, drawn finer) → `## 設計方針・構成` → `## 論点` (its own 論点の一覧 and entries) → `## 段階` (sub-stages as a numbered list, and a staged-diagram section or note when they need diagrams).
- **Recursion**: the same rule applies inside a stage note — a sub-stage that is itself a design task gets its own note one level further down. Keep each level readable on its own: a level summarizes its children in one row or one line each and links to them; detail lives only in the deepest note that needs it.
- **What stays in the root**: the task's state and history. Stage notes have no 現在地, Event Log, frontmatter `status`, or bd mirror; 現在地, Milestones, the Event Log, and bd stay in the root note, written by the root session. A design change in a stage note is an event recorded in the root's Event Log, and the root's bd `design` snapshot names each stage note and its open 論点.
- **論点 ids across levels**: one D-n sequence per task, so an id points to one decision wherever it appears. A stage note's 論点 take the next free numbers; the entries live in the stage note. The root's 論点の一覧 keeps its own decisions and one row per stage note (`<Mn> の論点: D-7〜D-9、未決 1 件 → [[<stage note>]]`), and 現在地 未決の論点 lists every open D-n with its topic and the note it lives in. The done gate counts open 論点 in stage notes too.
