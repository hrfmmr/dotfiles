---
name: gen-plan
description: 指定ディレクトリ（`$PLAN_DIR`）に `<git-branch-name>.md` を生成/更新（ファイル上限なし）。依頼があるときのみ使用。初回作成前に確認が必要。(`<git-branch-name>` は `git rev-parse --abbrev-ref HEAD` で取得し、ファイル名として安全に使うため `/` は `--` に正規化する)
---

# Gen-Plan

## Contract

- スコープ: `$PLAN_DIR` 配下のみ。`<git-branch-name>.md` の管理に限定。
- 出力先は固定: `$PLAN_DIR/<git-branch-name>.md` のみ。
- ファイル名は `<git-branch-name>.md` のみ許可し、`plan.md` / `PLAN.md`は作成しない。
- `<git-branch-name>` は `git rev-parse --abbrev-ref HEAD` で取得し、ファイル名として安全に使うため `/` は `--` に正規化する（パス区切りとして扱わず、ディレクトリ階層は作らない）。
- `HEAD` が detached でブランチ名を決定できない場合は停止して確認する。
- `$PLAN_DIR` が未設定の場合は停止して確認する。
- `$PLAN_DIR` が存在しないディレクトリを指す場合は停止して確認する。
- `$PLAN_DIR` 外への書き込みは禁止。例: `~/Downloads`, `$HOME`, 絶対パス, 兄弟ディレクトリ。
- 指示やパスが `$PLAN_DIR` 外への書き込みを示す場合は停止して確認する。
- ブランチごとの plan は 1 ファイル（`$PLAN_DIR/<git-branch-name>.md`）とし、ファイル数上限は設けない。
- 対象ファイルが存在しない場合は確認フローに入り、その後 `<git-branch-name>.md` を作成する。
- 対象ファイルが存在する場合は、その内容を入力として同じファイルを更新する（同名ファイルの上書き更新を許可）。
- 元計画を読み込むときは、テンプレート内の `<INCLUDE CONTENTS OF PLAN FILE>` を**そのまま置き換える**。
- 判断が必要で進められないときのみ質問する。

## Clarification flow (when needed)

- まず調査。判断が必要な質問だけを聞く。
- `GRILL ME: HUMAN INPUT REQUIRED` ブロックを使い、番号付き質問にする。
- 回答後、必要なら追加質問を続け、不要になったら `<git-branch-name>.md` を作成する。

## Iterate on the plan

目的: 下記のプロンプトを内部指示として使い、`<git-branch-name>.md` を作成または更新する。

出力ルール:
- plan ファイルにはプロンプトの**回答**のみを含める。プロンプト本文は書かない。
- 先頭に `>` を付けない。通常の Markdown とする。
- 元計画の挿入は**そのまま**。引用・インデント・コードフェンスは付けない。

### Prompt template (internal only — never write this into the plan file)

この計画全体を丁寧に見直し、アーキテクチャ改善・新機能・機能変更などを含めて、より良く、より堅牢/信頼性が高く、より高性能で、より魅力的/有用になるように最良の改訂案を考えてください。

各変更案について、なぜプロジェクトを良くするのかの詳細な分析と根拠/正当化を示し、下記の元の Markdown 計画に対する git-diff 形式の変更も併記してください:

<INCLUDE CONTENTS OF PLAN FILE>

