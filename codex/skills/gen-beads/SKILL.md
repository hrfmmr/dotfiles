---
name: gen-beads
description: Markdown の計画を完全な bd beads グラフ（タスク/サブタスク/依存）に変換し、bd のみで作成・編集した後に最適化する。plan.md/plan-*.md/DESIGN/IMPLEMENTATION/ARCHITECTURE などの計画文書の bead 化や、計画から bd タスク生成の依頼で使用。
---

# Gen Beads

## Overview
Markdown 計画を、明確な依存関係と自己文書化されたコメントを持つ bead グラフへ変換する。並列実行を最適化するため、単一の直列チェーンではなく DAG を優先する。

## Inputs

- 計画 Markdown のパス
- スコープ境界、順序制約、優先度の指示
- ワークフロー制約（例: "stacked PR なし", "merge で close", "必ず直列", "molecule を使う"）
- 実行対象を隔離する `plan_label`（例: `plan:checkout-v2`）

## Defaults (override if the user says otherwise)

- Parallel-first: `bd ready` で複数の未ブロック作業が出るよう最大化。
- `blocks` は真の前提のみ。ソフトな順序は `tracks`/`related`。
- PR を開いたら bead は完了扱い。stacked PR 可。
- 中粒度: 各 bead は独立して PR 可能。
- checkpoint/integration bead を頻繁に入れる（合流点）。
- 各 bead コメントに小さなメタデータブロックを追加:
  - `Workstream: <name>`
  - `Role: contract | implementation | integration | checkpoint`
  - `Parallelism impact: unlocks <n> beads`（可能な範囲で）
  - (Optional) Double Diamond: `contract` = Define; `implementation` = Develop/Deliver; `integration|checkpoint` = Deliver。
- エージェントルーティングラベルは付けない。
- molecule は繰り返しチェックリストにのみ使用。
- 実行オーケストレーション互換のため、生成・更新したすべての task/sub-task/bead に `plan_label` を付与する（epic にも同ラベルを推奨）。

## Workflow

1. 計画ファイルを特定して読む。候補が複数ある場合はパスを確認する。
2. 主要なワークストリーム、タスク、リスク、マイルストーン、暗黙依存を抽出。
3. 仕事を分離できる「契約」（API 形、スキーマ、インタフェース、CLI 署名、設定フォーマット）を特定。
4. 依存が曖昧で `blocks` になりそうなら、決める前に質問する。
5. "Generate Step Prompt" を**そのまま**使って beads を生成。作成・依存追加は bd コマンドのみ。
6. "Review Prompt" を**そのまま**使って各 bead を評価し、必要なら bd で修正。
7. 作成/更新内容と未解決の曖昧点を報告。
8. 作成/更新後に `plan_label` 付与漏れがないことを確認し、漏れがあれば `bd label add` で補正する。

## Generate Step Prompt (use verbatim)

```
では、以上の内容をすべて引き受けてさらに詳細化し、タスク/サブタスク/依存関係の構造を重ねた、包括的かつ粒度の細かい beads を作成してください。全体が完全に自己完結・自己文書化されるように、詳細なコメント（背景、理由/正当化、検討事項など、将来の自分が目的・意図・思考過程・プロジェクト全体目標への寄与を理解できる情報）を含めてください。

並列化ルール（重要）:
- 単一の直列チェーンではなく DAG を作る。「各 bead が前の bead に依存」になっているなら止めて、並列ワークストリームに再構成する。
- まず主要ワークストリーム（例: frontend/backend、data model/API、infra/CI、docs/migrations など）を特定し、各ワークストリームに epic（または親 bead）を作る。
- 複数ワークストリームを並列に進められるように、明示的な「契約」bead（API/spec/schema/interface/config 形式の決定）を作る。
- 複数の並列 bead に依存する checkpoint/integration bead を合流点として追加し、頻繁なフィードバックループを強制する。

依存関係ルール:
- `blocks` は、本当に前提が無ければ着手できない場合にのみ使う。
- 依存が不確かで `blocks` になりそうなら、追加前に人間に確認する。
- 「推奨順」「できれば先に」「手戻り削減」程度なら `blocks` より `tracks` / `related` を優先する。

PR + 粒度の前提:
- 各 bead は独立して PR 可能（中粒度）。
- bead の完了は PR を開いた時点とみなす。stacked PR は許容。
- エージェントのルーティングラベルは付けない。割り当ては手動で維持する。
- ただし実行対象隔離ラベル（`plan_label`）は必須で付与する。これはルーティングラベルではなく実行境界ラベル。

すべての bead に、明確な受け入れ基準と少なくとも 1 つの検証シグナル（test/build/lint コマンド、または精密な手動チェック）を含める。\nbead コメントには短いメタデータブロックを付ける:
- ワークストリーム: <name>
- 役割: contract | implementation | integration | checkpoint
- 並列化インパクト: <n> 個の bead を解放（ベストエフォート）

コメントのフッタ例:
```
ワークストリーム: Backend API
役割: contract
並列化インパクト: 3 個の bead を解放
```

理由の 1 行例（任意・短く）:
```
理由: 契約を先に決めて 3 つの並列実装を解放する。
```

bead の作成/修正/依存追加は `bd` ツールのみを使う。
```

## Review Prompt (use verbatim)

```
各 bead を徹底的に確認する。意味が通っているか、最適か、ユーザーにとってより良くする変更が可能か。可能なら bead を修正する。実装前の「計画空間」での調整は、圧倒的に速く安全。

さらに: 依存グラフの並列性を監査する。
- グラフがほぼ直列なら再構成する: ワークストリーム分割、契約 bead の導入、`blocks` の削減。
- `blocks` は真の前提だけに限定し、ソフト順序は `tracks` / `related` に降格。
- checkpoint/integration の合流点が頻繁に存在すること。
- 各 bead が独立 PR 可能で、明確な受け入れ + 検証を持つこと。
- 各 bead コメントに Workstream/Role/Parallelism のメタデータブロックがあること。
- 対象 issue 全件に同一 `plan_label` が付与されていること（実行対象集合の隔離）。
- グラフ作成後に `bd ready` を実行する。不要に直列なために 1 件しか出ない場合は、並列作業が可能になるまで依存を見直す（真の前提は維持）。
```

## Guardrails

- beads の作成/更新/依存追加は bd コマンドのみ。bead ファイルの手編集は禁止。
- 計画の意図を維持する。計画が不整合・欠落している場合は決める前に質問する。
- 単一チェーンではなく、並列化可能なワークストリームと合流点を優先する。
- 大きなタスクより、小さく合成可能な bead と明示的な前提を優先。
- molecule は繰り返しチェックリストにのみ使う（デフォルト構造にしない）。
- `plan_label` が未指定なら作成を止めて確認する（暗黙値で進めない）。
- bd issue の metadata（title/description/design/notes/acceptance など）の自然言語記述は、原則として日本語で記述する。
- 専門用語・固有名詞・仕様名・引用は無理に直訳せず、必要に応じて原語を維持する。

## Output Expectations

- 並列実行向けに設計された、タスク/サブタスク/依存を備えた整合的な bead グラフ。
- 作成/更新の要約と、残る質問の一覧。
