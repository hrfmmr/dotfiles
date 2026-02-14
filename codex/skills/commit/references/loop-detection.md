# Tight Loop Detection (Heuristics)

Goal: コミット前に、少なくとも 1 つの高速で関連性の高いシグナルを実行する。変更を検証できる範囲で、できるだけ小さいループを優先する。

## Selection Order
1. プロジェクト提供のタスクランナー（Make）
2. 言語標準のテストランナー
3. Lint / typecheck / 静的解析
4. 最小限の実行ログまたはスモークチェック

## Task Runners (fastest wins)
- Makefile: `test`, `check`, `lint` を探し、`make <target>` を実行。

## When in doubt
- 変更を検証できる最小のシグナルを優先する。
- コマンドが不明確またはリスクがある場合は、ユーザーに推奨チェックを確認する。

