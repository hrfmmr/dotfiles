---
name: grill-me
description: 曖昧/矛盾する依頼を、まず調査し、その後に判断が必要な質問だけで詰める。要件が不足・対立・暗黙のトレードオフがある場合、または「要件整理/スコープ定義/最適化/改善/圧力テスト/厳しく質問して」などの依頼で使用。実装前で止める。
---

# Grill Me

## Double Diamond fit
Grill Me は最初のダイヤ（Discover + Define）に位置する: 文脈を広げ、その後に作業定義へ収束させる。
- Discover: まず調査。発見可能な事実は聞かない。
- Define: 1 行の問題文 + 成功基準を作り、判断が必要な質問だけをする。
- Handoff: 選択肢/トレードオフが残れば `$creative-problem-solver`、実装が可能なら `$tk`へ。

## Quick start
1. まず調査。聞かずに分かることは聞かない。
2. 事実/判断/未解決を短いスナップショットで維持。
3. 判断が必要な質問だけをする（独立なら 2〜3 件。依存があるなら 1 件）。`request_user_input` が使えるなら優先。
4. 回答を反映して繰り返し、未解決がなくなるまで続ける。
5. 詳細な beads を生成して停止（実装しない）。

## High-pressure clarification mode
ユーザーがpressure-testingを求めた場合の厳格モード。
1. 1 ターンに 2 件の難しい判断質問（独立なら 2、依存なら 1）。
2. 具体化を強制（指標/日付/範囲/責任者）。曖昧なら同じ `id` で再質問。
3. 優先順序: 目的 -> 制約 -> 非目標 -> トレードオフ -> 受け入れシグナル。
4. 口調は簡潔に。実装案は出さない。
5. スナップショットに問題文/成功基準/未解決が揃ったら終了。

## Asking questions (tool-aware)
- 未解決質問をキューで管理。
- 独立質問はバッチで（2 件を優先、最大 3 件）。依存がある場合のみ 1 件。
- 高圧モードでは 2 件優先。
- `request_user_input` が使えるなら必ず使う。使えない場合は fallback を使う。
- 回答後は Snapshot と未解決キューを更新:
  - 回答済みを削除
  - 回答から生まれたフォローアップを追加
  - ブロックする質問は前に挿入

### Loop pseudocode
```text
open_questions := initial judgment calls (ordered)
answered_ids := set()

while open_questions not empty:
  batch := take_next(open_questions, max=3, prefer=2)

  if tool_exists("request_user_input"):
    tool_args := { questions: batch_to_tool_questions(batch) }
    raw := call request_user_input(tool_args)
    resp := parse_json(raw)
    answers_by_id := resp.answers
  else:
    note "request_user_input not available; using fallback"
    render fallback numbered block for batch
    answers_by_id := extract answers from user reply

  for q in batch:
    a := answers_by_id[q.id].answers (may be missing/empty)
    if a missing/empty and q still required:
      keep q in open_questions (re-ask; rephrase; same id)
    else:
      remove q from open_questions
      answered_ids.add(q.id)
      update Snapshot with facts/decisions from a

  followups := derive_followups(answers_by_id, Snapshot) using rules below
  enqueue followups:
    - if a follow-up blocks other questions, prepend it
    - otherwise append it
    - dedupe by id against open_questions and answered_ids
```

### Follow-up derivation rules
判断が必要で進行に必須な場合のみ follow-up を作る。次の順で適用:

- 範囲拡大があれば（"also"/"while you're at it" など）: 「この追加はスコープ内か？」（include/exclude）。
- 依存が出たら（"depends on"/"only if" など）: 「どの条件を前提にするか？」。
- 競合優先があれば（速度 vs 安全 など）: 「どちらを優先するか？」（2〜3 選択肢）。
- 曖昧なら（"faster"/"soon"/"better" など）: 「具体的な指標/日付/範囲は？」。
- 複数要求が 1 つの user_note にある場合は分割。
- 発見可能な事実を問う follow-up は作らず、調査に回す。

Follow-up hygiene:
- `id` は意図に基づく安定名（snake_case）。再質問でも同じ id。
- `header` は 12 文字以下。
- `question` は 1 文。
- 選択肢が小さい場合は options、自由記述なら options を省略。

## `request_user_input` (preferred)
可能ならこのツールで質問する。

### Call shape
- `questions: [...]` に 1〜3 件。
- 各項目は必須:
  - `id`: 安定識別子
  - `header`: 12 文字以内
  - `question`: 1 文
  - `options`（任意）: 2〜3 の排他選択肢
    - 推奨オプションは先頭に置き、`(Recommended)` を付ける
    - free-form なら options を省略
- 同じ概念の再質問は同じ `id` を使う。

Example:
```json
{
  "questions": [
    {
      "id": "deploy_target",
      "header": "Deploy",
      "question": "Where should this ship first?",
      "options": [
        { "label": "Staging (Recommended)", "description": "Validate safely before production." },
        { "label": "Production", "description": "Ship directly to end users." }
      ]
    }
  ]
}
```

### Response shape
ツールは `answers` マップを返す:
```json
{
  "answers": {
    "deploy_target": { "answers": ["Staging (Recommended)", "user_note: please also update the docs"] }
  }
}
```

### Answer handling
- `answers[<id>].answers` をユーザー入力として扱う。
- TUI では option のラベル + optional `user_note:` が返ることがある。
- ` (Recommended)` のサフィックスは解釈時に除去。
- `user_note:` は自由記述として扱い、事実/判断/フォローアップを抽出。
- 必要な回答が欠けていれば再質問（同じ id）。

## Snapshot template
```
Snapshot
- Stage: Discover | Define
- Problem statement:
- Success criteria:
- Facts:
- Decisions:
- Open questions:
```

## Human input block (fallback)
`request_user_input` が無い場合は一行だけ注記して、この見出しと番号付きリストを使う:
```
GRILL ME: HUMAN INPUT REQUIRED
1. ...
2. ...
3. ...
```

