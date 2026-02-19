---
name: commit
description: 最小差分のマイクロコミットを作成し、コミットごとに少なくとも 1 つの検証シグナルを取る。
---

# Commit

## Intent
変更差分をsurgical commitsへ切り分ける: 一貫した変更、最小の影響範囲、そしてコミット前に最低 1 つのフィードバックシグナル。

## When to use
- 「マイクロコミットに分けて」
- 「最小変更だけをステージしてコミットして」
- 「コミットを小さく保って、チェックを通す」

## Workflow (Surgeon's principle)

### 1) Scope the incision
- 単独で成立する最小変更を特定する。
- 無関係な編集は分離する。必要性のないリファクタや整形は避ける。

### 2) Stage surgically (non-interactive-first)
確認:
- `git status -sb`
- `git diff`

意図したものだけをステージ（非対話環境ではファイル単位を優先）:
- `git add <paths...>`
- `git restore --staged <paths...>`

検証:
- `git diff --cached` が意図した切り口と一致していること。

本当にハンク単位が必要で、環境が対話式に対応しない場合は、ユーザーにローカルでのハンク分割やパッチ提供を依頼する。

### 3) Validate the micro scope
- 任意の補助: `scripts/micro_scope.py`（ステージ済みと未ステージのサイズ比較）。
- ステージ済み差分が複数関心事なら、チェック前に分割する。

### 4) Close the loop (required)
- もっとも小さく意味のあるシグナルを選んで実行する。
- リポジトリのテスト/チェックコマンドが見つからない場合は、推奨コマンドを確認する。
- Reference: `references/loop-detection.md`。

### 5) Commit
- メッセージは簡潔に。詩的さより明瞭さ。
- デフォルトは Conventional Commits 接頭辞を使う（`feat:` / `fix:` / `chore:`）。
- 接頭辞の指定がない場合は変更の性質で選ぶ（機能追加=`feat`、不具合修正=`fix`、運用/雑務=`chore`）。
- 少なくとも 1 つのシグナルが通ってからコミットする。

### 6) Repeat
作業ツリーがクリーンになるか、残りが意図的に保留されるまで繰り返す。

## Guardrails
- スコープを勝手に広げない。
- 変更に意味のある最小チェックを優先する。
- 通過シグナルなしで完了を主張しない。

## Resources
- `scripts/micro_scope.py`
- `references/loop-detection.md`
