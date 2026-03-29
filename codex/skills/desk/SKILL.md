---
name: desk
description: >
  Obsidian タスクノート駆動の非同期 agent orchestration skill。タスク起票・計画・実行・完了の全ライフサイクルを、obsidian ノートを唯一の human interface として sub-agent に委譲する。
  Use when user says "$desk", "desk", "タスク起票", "タスク開始", "作業再開", or wants to orchestrate implementation/research/ad-hoc tasks via obsidian task notes with async human-agent dialogue.
---

# Desk

## Overview

Obsidian タスクノートを唯一の human interface として、sub-agent に作業を非同期委譲する orchestration layer。
自身は薄い制御層に留まり、作業具体は既存スキル（$wt / $grill-me / $tk / $review / $commit / $join / $beads）に委譲する。

## Prerequisites

- cwd が Obsidian vault root であること（任意の vault で動作する）
- obsidian-git プラグインが有効（auto-commit 間隔 ≈ 3 分）
- 実装/調査タスクでは対象 repo root の `.envrc` に `BEADS_DIR` が定義済みであること

## Invocation

| pattern | 動作 |
|---------|------|
| `$desk` | daily-note (yyyy-mm-dd.md) の `[[タスクノート]]` リンク + in_progress/human_response_required なノートを検出し、選択肢を提示。人間が明示選択して resume。 |
| `$desk <タスクノート名>` | 指定タスクを直接 resume または init。 |
| `$desk new` | 新規タスクを起票。 |

## Task Types

| type | target repo | worktree | bd issue | PR |
|------|-------------|----------|----------|----|
| 実装 | required | required | required | optional |
| 調査 | required | required | required | — |
| 非定型 | — | — | — | — |

## Frontmatter Spec

タスクノートの YAML frontmatter。タスク種別で required/optional が変わる。

```yaml
---
source_issue_link: ""      # 実装/調査: required, 非定型: optional
target_repo: ""            # 実装/調査: required
git_working_tree: ""       # 実装/調査: required
beads_dir: ""              # 実装/調査: required
bd_issue_id: ""            # 実装/調査: required
status: "not_started"      # required (全種別)
current_status_summary: "" # required (全種別)
pull_request_url: ""       # 実装: optional
figma_url: ""              # optional (全種別)
task_type: ""              # required: impl | research | adhoc
---
```

### Status 遷移

```
not_started → plan_ready → planning → in_progress → human_response_required ⇄ in_progress → in_review → done
```

## Phase 0: Init (`$desk new`)

1. **Signal hook チェック**: `scripts/setup-hook.sh "$PWD"` を実行。hook 未設置なら y/N 確認で自動インストール。スキップされた場合は警告を表示し続行（signal 検知が動作しない旨を伝える）。
2. 人間に `source_issue_link` と `task_type` を確認する。
3. `task_type` に応じて:
   - **impl/research**: `target_repo` を確認 → `.envrc` から `BEADS_DIR` を解決 → `$wt` で worktree 作成（path/branch 候補を提案し承認を得る）→ `$beads` で bd epic issue を作成。
   - **adhoc**: worktree/bd issue 不要。frontmatter の該当フィールドを空のまま残す。
4. タスクノートを vault root に作成（frontmatter 埋め + 空の Planning / Milestones / Dialogue セクション）。
5. `status: plan_ready` に遷移。

### タスクノート初期構造

```markdown
---
(frontmatter)
---

# <タスク名>

## Planning

### Snapshot
<!-- grill-me snapshot が確定後ここに書き出される -->

### Plan
<!-- 確定した実行計画 -->

## Milestones

| bd_issue:: | summary:: | milestone_status:: |
|------------|-----------|-------------------|

## Dialogue
<!-- Turn-N 見出しが追記される -->
```

## Phase 1: Planning

Sub-agent を spawn し、working tree を cwd として計画を詰める。

1. タスクノートの Planning セクションに Q-ID 体系で問いを書き出す（`references/async-dialogue-protocol.md` 参照）。
2. 非同期回答ガイドをノート内に記載し、`terminal-notifier` で通知を発火する。
3. 回答検知は **signal file 方式**（後述）。検知後、`status:: done` の問いから深掘りを再開。派生問いは `Q-n-m` で追加。
4. Open questions が出尽くしたら、Snapshot（raw）を Planning > Snapshot セクションに書き出す。bd issue にも同期。
5. 確定プランを Planning > Plan セクションに書き出す。
6. Milestones テーブルに大まかなクリティカルパスを Dataview inline field 付きで記入。
7. `status: in_progress` に遷移。

## Phase 2: Execution

Sub-agent が working tree 内で以下のループを回す。

```
loop until done:
  $tk (reasonable incision)
  → $review (approval gate)
  → $commit
  → checkpoint (see below)
  → signal check (see below)
```

### Checkpoint contract

各 `/commit` 成功後:
- `bd edit <issue-id> --append-notes "<commit-hash>: <変更要約>"` で bd issue に追記。
- `bd dolt commit` → `bd dolt push`。

各ステータス遷移時:
- タスクノート frontmatter の `status` と `current_status_summary` を更新。
- Milestones テーブルの `milestone_status::` を更新。

### Human input required

作業中に human input が必要になった場合:

1. タスクノートの Dialogue セクションに `Turn-N` 見出しを追加。

```markdown
### Turn-1
input:: pending

**Context**: <背景>
**Question**: <判断を求める問い>
**Options**: <選択肢があれば>

> ここに回答を記入。記入後 `input:: pending` を `input:: done` に変更。
```

2. `status: human_response_required` に遷移。frontmatter `current_status_summary` を更新。
3. `terminal-notifier` で obsidian:// URL 付き通知を発火。
4. 他に並行で進められる sub-issue があればそちらを進行。
5. signal file 検知で回答を読み取り、作業再開。`status: in_progress` に復帰。

### Sub-issue discovery

実行中に派生 sub-issue が発見された場合:
- `bd create "<title>" --parent <epic-id>` で sub-issue を作成。
- Milestones テーブルに行を追加。
- sub-issue 下にコンテキストをログしながら対処。

## Phase 3: Completion

1. 全 milestone 完了後、タスクノート Dialogue セクションに final human check の `Turn-N` を追加。
2. `status: in_review` に遷移。通知発火。
3. 人間の承認を得たら:
   - 実装タスク: 必要に応じて `$join` で PR 作成。frontmatter `pull_request_url` を更新。
   - bd epic issue を close。
4. `status: done` に遷移。

## Signal Mechanism

### obsidian-git post-commit hook

obsidian-git の auto-commit (≈3分間隔) を利用したイベント駆動。

```
auto-commit 発火
  → .git/hooks/post-commit 実行
    → scripts/check-signals.sh
      → 変更ファイルが入力待ちタスクノートに該当するか判定
        → 該当 & inline field `input:: done` を検知
          → .desk/signals/<task-name>.ready を作成
          → terminal-notifier で通知
```

### Agent 側の検知

Agent は作業サイクルの自然な区切り（各 `/commit` 後）に `.desk/signals/` をチェックする。
`.ready` ファイルを検知したら、対象タスクノートを読み直して回答を取得し、signal file を削除する。

## Cold Resume Protocol

セッション死亡後の作業再開手順。

0. **Signal hook チェック**: `scripts/setup-hook.sh "$PWD"` を実行。未設置なら y/N 確認でインストール。
1. `$desk` 呼び出し時、以下を収集:
   - daily-note (yyyy-mm-dd.md) 内の `[[タスクノート]]` リンク
   - vault root の `*.md` から frontmatter `status` が `in_progress` / `human_response_required` / `plan_ready` / `planning` のノートを検出
2. daily-note のリンクを優先候補として選択肢を提示。
3. 人間が選択後、タスクノートの frontmatter + Milestones + 直近の Dialogue Turn を読み込み。
4. bd issue が存在する場合、`bd show <issue-id>` で最新状態を取得。
5. コンテキストを復元し、`current_status_summary` に基づいて該当 Phase から再開。

## Notification

```bash
VAULT_NAME=$(basename "$PWD")
terminal-notifier \
  -title "desk: <タスク名>" \
  -message "<状況サマリー>" \
  -open "obsidian://open?vault=${VAULT_NAME}&file=<タスクノート名>&heading=<target_heading>"
```

## Dataview Integration

### 入力待ち一覧ビュー

タスクノート横断で `input:: pending` を集約するクエリ:

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  input AS "Input Status",
  current_status_summary AS "Summary"
FROM ""
WHERE input = "pending"
SORT file.mtime DESC
```

### アクティブタスク一覧

```dataview
TABLE WITHOUT ID
  file.link AS "Task",
  status AS "Status",
  task_type AS "Type",
  current_status_summary AS "Summary"
FROM ""
WHERE status AND status != "done" AND status != "not_started"
SORT file.mtime DESC
```

## Skill Delegation Map

| phase | delegated skill | purpose |
|-------|----------------|---------|
| Init | `$wt` | worktree 作成 |
| Init | `$beads` | bd epic issue 作成 |
| Planning | `$grill-me` (async adapted) | Q&A による要件明確化 |
| Execution | `$tk` | minimal-diff incision |
| Execution | `$review` | approval gate |
| Execution | `$commit` | micro-commit |
| Completion | `$join` | PR 作成 |
| All phases | `$beads` | bd issue CRUD & sync |

## Guardrails

- 元セッションへの同期 interrupt 禁止。human 対話は全てタスクノート Turn-N 経由の非同期。
- タスクノートと bd issue の二重書き込みは意図的設計（目的が異なる: 人間用 view vs agent 復元用 log）。
- bd issue body/notes はセッション死亡後の cold resume に十分な自己完結性を持たせる。
- 全 in_progress タスクに並行 agent を割り当て可。同一 BEADS_DIR への並行 write 競合リスクは許容。
- root epic close には必ず human check gate を含める。
