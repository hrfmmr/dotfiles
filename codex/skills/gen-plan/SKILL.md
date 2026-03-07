---
name: gen-plan
description: 明示指定された plan Markdown パス、GitHub Issue、または指定がなければ `$PLAN_DIR/{sanitized-branch-name}.md` を生成/更新する。Issue 指定時は `.plans/gh-number.md` 形式を使い、最新 plan を `gh` で issue comment に反映する。依頼があるときのみ使用。初回作成前に確認が必要。
---

# Gen-Plan

## Contract

- スコープ: 1 回の実行で扱う plan は 1 ファイルのみ。
- 入力ソースと出力先の優先順位:
  1. ユーザーが plan Markdown ファイルパスを明示した場合は、そのパスを `target plan file` として採用する。
  2. ユーザーが GitHub Issue 番号または URL を明示した場合は、その issue を plan source とし、`.plans/gh-<number>.md` を `target plan file` とする。
  3. 明示指定がない場合は `$PLAN_DIR/<git-branch-name>.md` を `target plan file` とする。
- 明示指定パスを使う場合、`$PLAN_DIR` の設定/存在は前提にしない。
- GitHub Issue 指定を使う場合、`$PLAN_DIR` の設定/存在は前提にしない。
- 明示指定パスは `.md` 拡張子のファイルパスであること。判定不能または `.md` 以外なら停止して確認する。
- GitHub Issue 指定は issue 番号または URL として一意に解釈できること。判定不能なら停止して確認する。
- 明示指定がない場合のみ、ファイル名は `<git-branch-name>.md` とし、`plan.md` / `PLAN.md` は作成しない。
- 明示指定がない場合のみ、`<git-branch-name>` は `git rev-parse --abbrev-ref HEAD` で取得し、ファイル名として安全に使うため `/` は `--` に正規化する（パス区切りとして扱わず、ディレクトリ階層は作らない）。
- 明示指定がない場合のみ、`HEAD` が detached でブランチ名を決定できないときは停止して確認する。
- 明示指定がない場合のみ、`$PLAN_DIR` が未設定または存在しないディレクトリを指すときは停止して確認する。
- GitHub Issue 指定時は `gh issue view <number> --json number,title,body,url` を使って issue 本文を取得し、本文を draft plan Markdown として扱う。
- GitHub Issue 指定時は `.plans` ディレクトリがなければ作成してよい。
- GitHub Issue 指定時に `.plans/gh-<number>.md` が既に存在する場合は、そのローカル plan を更新対象とし、issue 本文は必要に応じて差分確認用の上流 draft として参照する。
- `target plan file` が存在しない場合は確認フローに入り、その後そのファイルを作成する。
- `target plan file` が存在する場合は、その内容を入力として同じファイルを更新する（同名ファイルの上書き更新を許可）。
- 元計画を読み込むときは、テンプレート内の `<INCLUDE CONTENTS OF PLAN FILE>` を**そのまま置き換える**。
- GitHub Issue 指定で `target plan file` が未作成の場合は、issue 本文を初期入力として plan を生成し、結果を `.plans/gh-<number>.md` に保存する。
- GitHub Issue 指定時は、plan 更新後に `gh issue comment <number> --body-file .plans/gh-<number>.md` で最新 plan を comment として投稿する。
- 判断が必要で進められないときのみ質問する。

## Clarification flow (when needed)

- まず調査。判断が必要な質問だけを聞く。
- `GRILL ME: HUMAN INPUT REQUIRED` ブロックを使い、番号付き質問にする。
- GitHub Issue URL の repo/number が `gh` で確定できる場合は質問しない。
- 回答後、必要なら追加質問を続け、不要になったら `target plan file` を作成する。

## Source preparation

- plan Markdown パス指定時は、そのファイル内容を元計画として読む。
- GitHub Issue 指定時は、まず `gh issue view` で本文を取得する。
- GitHub Issue 指定時にローカル plan が未作成なら、issue 本文を元計画として使う。
- GitHub Issue 指定時にローカル plan が既にあるなら、通常はそのローカル plan を元計画として使う。ユーザーが再シードを明示したときだけ issue 本文で置き換える。
- 明示指定がない場合は `$PLAN_DIR/<git-branch-name>.md` の内容を元計画として読む。
- GitHub Issue 指定時は、生成・更新した plan を `.plans/gh-<number>.md` に保存してから comment 投稿に進む。

## Iterate on the plan

目的: 下記のプロンプトを内部指示として使い、`target plan file` を作成または更新する。

出力ルール:
- plan ファイルにはプロンプトの**回答**のみを含める。プロンプト本文は書かない。
- 先頭に `>` を付けない。通常の Markdown とする。
- 元計画の挿入は**そのまま**。引用・インデント・コードフェンスは付けない。
- 各変更案には、少なくとも 1 つの「計画差分（pseudocode 相当）」を必ず含める。
- 「計画差分（pseudocode 相当）」は、実装コードではなく計画レベルの手順/構造変更を示す疑似コードまたは差分ブロックで表現する。
- GitHub Issue 指定時に comment 投稿する本文は、保存済みの `.plans/gh-<number>.md` の内容と一致させる。
- `gh` への書き込みが禁止された状況では、投稿コマンドを提示して停止する。書き込みを黙ってスキップしない。

### Prompt template (internal only — never write this into the plan file)

この計画全体を丁寧に見直し、アーキテクチャ改善・新機能・機能変更などを含めて、より良く、より堅牢/信頼性が高く、より高性能で、より魅力的/有用になるように最良の改訂案を考えてください。

各変更案について、なぜプロジェクトを良くするのかの詳細な分析と根拠/正当化を示し、下記の元の Markdown 計画に対する git-diff 形式の変更を併記してください。さらに、各変更案ごとに計画レベルの疑似コード差分（pseudocode diff 相当）を必ず併記してください:

<INCLUDE CONTENTS OF PLAN FILE>
