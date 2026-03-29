# Async Dialogue Protocol

## Q-ID 体系

Planning フェーズおよび Turn-N 内での問いかけに使用する ID 体系。
retrospective skill の対話中の成果物ルールを踏襲。

### ID 命名規則

- root 問い: `Q-1`, `Q-2`, `Q-3`, ...
- 派生問い: `Q-1-1`, `Q-1-2`, `Q-2-1`, ...（branch 構造で親子関係を表現）
- 見出しレベルはすべてフラット（同一レベル）。Obsidian outline で全体像を一望可能にする。

### 状態管理

Dataview inline field で管理:
- `status:: unanswered` — 未回答
- `status:: done` — 回答済み

### ノート内レイアウト（Planning セクション）

```markdown
## Planning

> [!info] 非同期回答ガイド
> 各問いに対して回答欄に自由に記入できます。
> 回答を書き終えたら `status:: unanswered` を `status:: done` に変更してください。
> 全て（または一部）の回答を書いたら、自動検知されます（obsidian-git auto-commit → signal 検知）。

### Q-1: <問いのタイトル>
status:: unanswered

> ここに回答を記入

### Q-2: <問いのタイトル>
status:: unanswered

> ここに回答を記入

### Snapshot
<!-- grill-me snapshot が確定後ここに書き出される -->

### Plan
<!-- 確定した実行計画 -->
```

### 対話ラウンドごとの更新

1. `status:: done` の問いから回答を読み取り、Insight を追記:

```markdown
### Q-1: <問いのタイトル>
status:: done

> <ユーザーの回答>

**Insight**: <浮かび上がった示唆>
```

2. 派生問いが生まれたら追加:

```markdown
### Q-1-1: <派生した問いのタイトル>
status:: unanswered

> ここに回答を記入
```

3. bd issue にも同期:
```bash
bd edit <issue-id> --append-notes "Q-1: A=<回答要約> / Insight=<示唆>"
bd edit <issue-id> --append-notes "New question: Q-1-1: <タイトル>"
```

## Turn-N Protocol（Execution フェーズ）

実行中に human input が必要になった場合のプロトコル。

### フォーマット

```markdown
### Turn-N
input:: pending

**Context**: <背景説明 — なぜこの判断が必要か>
**Question**: <具体的な問い>
**Options**: <選択肢があれば列挙。なければ省略>

> ここに回答を記入。記入後 `input:: pending` を `input:: done` に変更。
```

### Agent 側の振る舞い

1. Turn-N を書き出したら `status: human_response_required` に遷移。
2. `terminal-notifier` で通知。
3. 他の並行可能な sub-issue があればそちらを進行。
4. signal file (`.desk/signals/<task-name>.ready`) を作業区切りでチェック。
5. 検知後、Turn-N の `input:: done` を確認し、回答を読み取って作業再開。
6. signal file を削除。`status: in_progress` に復帰。

### 複数 Turn の場合

Turn は連番で追記。直近の未解決 Turn を優先的に処理する。

```markdown
### Turn-1
input:: done
...

### Turn-2
input:: pending
...
```
