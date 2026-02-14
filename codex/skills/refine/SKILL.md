---
name: refine
description: 既存の Codex スキルを $ms の更新で洗練し、SKILL.md,scripts/,references/,assets/ を更新して quick_validate で検証する。スキルの改善/反復/修正/リファクタ/拡張/改名、トリガーやメタデータ調整、scripts/references/assets 追加、UI メタ再生成、セッション分析の知見反映で使用。
---

# Refine

## Overview

$ms を使って証拠を最小の検証済み更新に変換し、対象スキルを洗練する。

## Inputs

- 対象スキル名またはパス
- 改善シグナル（ユーザーフィードバック、セッション分析メモ、エラー、欠落手順）
- 制約（最小差分、必須ツール、検証要件）

## Example Prompts

- 「pdf スキルに小さなスクリプトを追加して検証して」
- 「セッション分析のメモを使って gh スキルのワークフローを直して」

## Workflow (Double Diamond)

### Discover

- 対象スキルの `SKILL.md`, `scripts/`, `references/`,`assets/` を読む。
- 使用証拠を収集: 混乱点、欠落手順、不適切トリガー、古いメタデータ。
- 例のプロンプトが無ければ、スキルを発火すべき現実的なプロンプトを 2〜3 件作る。

### Define

- 1 行の問題文と 2〜3 個の成功基準を書く。
- 証拠に対応する最小の変更セットを選ぶ。
- 制約を明示する（quick_validate 必須、最小差分、必要なツール）。

### Develop

- 候補更新を列挙: frontmatter の説明、ワークフロー手順、新リソース、メタデータ再生成など。
- 最小切開を優先。繰り返し再利用されるか決定性に必要な場合のみリソース追加。

### Deliver

- $ms を呼び出して対象スキルに変更を適用する。
- SKILL.md の frontmatter は対象スキルの規約に合わせる（通常は name/description のみ）。
- スクリプト追加時は代表的なサンプルを実行して挙動確認。

## Validation

対象スキルで quick_validate を必ず実行する。
例: `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/<skill-name>`。

## Output Checklist

- トリガーが正確でワークフローが明快な `SKILL.md`
- 妥当性がある場合のみ新規/更新されたリソース（scripts/references/assets）
- quick_validate の検証シグナル（必要ならスクリプト実行結果）

