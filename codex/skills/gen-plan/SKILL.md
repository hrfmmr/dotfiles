---
name: gen-plan
description: 明示指定された plan Markdown パス、または指定がなければ `$PLAN_DIR/{sanitized-branch-name}.md` を生成/更新（ファイル上限なし）。依頼があるときのみ使用。初回作成前に確認が必要。（branchは `git rev-parse --abbrev-ref HEAD` で取得し、`/` を `--` に正規化する）
---

# Gen-Plan

## Contract

- スコープ: 1 回の実行で扱う plan は 1 ファイルのみ。
- 出力先の優先順位:
  1. ユーザーが plan Markdown ファイルパスを明示した場合は、そのパスを `target plan file` として採用する。
  2. 明示指定がない場合は `$PLAN_DIR/<git-branch-name>.md` を `target plan file` とする。
- 明示指定パスを使う場合、`$PLAN_DIR` の設定/存在は前提にしない。
- 明示指定パスは `.md` 拡張子のファイルパスであること。判定不能または `.md` 以外なら停止して確認する。
- 明示指定がない場合のみ、ファイル名は `<git-branch-name>.md` とし、`plan.md` / `PLAN.md` は作成しない。
- 明示指定がない場合のみ、`<git-branch-name>` は `git rev-parse --abbrev-ref HEAD` で取得し、ファイル名として安全に使うため `/` は `--` に正規化する（パス区切りとして扱わず、ディレクトリ階層は作らない）。
- 明示指定がない場合のみ、`HEAD` が detached でブランチ名を決定できないときは停止して確認する。
- 明示指定がない場合のみ、`$PLAN_DIR` が未設定または存在しないディレクトリを指すときは停止して確認する。
- `target plan file` が存在しない場合は確認フローに入り、その後そのファイルを作成する。
- `target plan file` が存在する場合は、その内容を入力として同じファイルを更新する（同名ファイルの上書き更新を許可）。
- 元計画を読み込むときは、テンプレート内の `<INCLUDE CONTENTS OF PLAN FILE>` を**そのまま置き換える**。
- 判断が必要で進められないときのみ質問する。

## Clarification flow (when needed)

- まず調査。判断が必要な質問だけを聞く。
- `GRILL ME: HUMAN INPUT REQUIRED` ブロックを使い、番号付き質問にする。
- 回答後、必要なら追加質問を続け、不要になったら `target plan file` を作成する。

## Iterate on the plan

目的: 下記のプロンプトを内部指示として使い、`target plan file` を作成または更新する。

出力ルール:
- plan ファイルにはプロンプトの**回答**のみを含める。プロンプト本文は書かない。
- 先頭に `>` を付けない。通常の Markdown とする。
- 元計画の挿入は**そのまま**。引用・インデント・コードフェンスは付けない。
- 各変更案には、少なくとも 1 つの「計画差分（pseudocode 相当）」を必ず含める。
- 「計画差分（pseudocode 相当）」は、実装コードではなく計画レベルの手順/構造変更を示す疑似コードまたは差分ブロックで表現する。

### Prompt template (internal only — never write this into the plan file)

この計画全体を丁寧に見直し、アーキテクチャ改善・新機能・機能変更などを含めて、より良く、より堅牢/信頼性が高く、より高性能で、より魅力的/有用になるように最良の改訂案を考えてください。

各変更案について、なぜプロジェクトを良くするのかの詳細な分析と根拠/正当化を示し、下記の元の Markdown 計画に対する git-diff 形式の変更を併記してください。さらに、各変更案ごとに計画レベルの疑似コード差分（pseudocode diff 相当）を必ず併記してください:

<INCLUDE CONTENTS OF PLAN FILE>
