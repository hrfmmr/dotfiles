---
name: ms
description: Codex スキルを作成/更新/リファクタする。SKILL.md,scripts/references/assets を含む。スキル設計/雛形作成/編集/検証/改善や、作成・更新・トリガー・メタデータに関する依頼で使用。
---

# ms

## Overview

最小差分で Codex スキルを作成・更新する。外部レジストリは使わず、スキルフォルダ内で完結させ、スキルをスリムに保つ。

## Hard constraints

- 最小差分: 要件を満たすために必要な変更だけを行う。
- 追加ドキュメント禁止: README/INSTALL/CHANGELOG 形式のファイルは追加しない。
- Frontmatter:
  - 既定: `name` と `description` のみ。
  - システムスキル更新時は、許可されている既存キー（例: `metadata`, `license`, `allowed-tools`）を保持。
  - `name` はハイフン区切り（<=64 文字）でフォルダ名と一致させる。
  - `description` はトリガー面。"when to use" のヒントを含める。角括弧は使わない。<=1024 文字。
- SKILL.md 本文:
  - 命令形で書く。
  - 500 行以内。詳細は `references/` に退避。
  - トリガーは本文に書かず、frontmatter `description` に書く。
- 完了前に必ず `quick_validate.py` を実行する。
  - 推奨（グローバルインストール不要）:
    - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <path/to/skill>`
  - 注意: skill-creator スクリプトは PyYAML が必要（`import yaml`）。

## Workflow Decision Tree

- 既存の該当スキルがある: Update Workflow。
- 該当スキルがない: Create Workflow。
- 名前/場所/トリガーが不明: 1〜3 の質問で確認してから進める。

## Create Workflow

1. 重複排除: 意図を既にカバーするスキルがないか探す。近似の新規作成より更新を優先。
2. Discover/Define: 具体的なユーザープロンプトを 2〜3 集め、以下を作る:
   - 問題文（1 行）
   - 成功基準（どうなれば成功か）
3. 再利用アセット計画: `scripts/` / `references/` / `assets/` が必要か判断し、必要最低限だけ作る。
4. 初期化（雛形）:
   - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/init_skill.py <skill-name> --path ~/.codex/skills`
   - `--resources scripts,references,assets` は必要な場合のみ付ける。
   - すぐ UI メタデータが必要なら `--interface key=value` を付ける（複数指定可）。
5. `SKILL.md` を執筆:
   - frontmatter `description` に具体的なトリガー（ファイル種別/ツール/タスク/キーフレーズ）を含める。
   - 本文は手順・決定木・`references/` への導線を中心に構成する。
6. 検証:
   - `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/<skill-name>`
7. ユーザーと反復: トリガーを絞り、重複を削り、再利用可能な処理は `scripts/` に昇格。

## Update Workflow (In Place)

1. 対象スキルのフォルダを `~/.codex/skills`（またはシステムスキルなら `~/.codex/skills/.system`）で特定。
2. 現在の `SKILL.md` とリソースを読み、必要な最小変更を特定。
3. その場で編集:
   - トリガーが変わるなら frontmatter `description` を更新。
   - ワークフロー/タスク/参照は最小差分で調整（整形の無駄な変更はしない）。
   - リソースフォルダの追加/削除は実際に再利用が生まれる場合のみ。
4. `uv run --with pyyaml -- python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <path/to/skill>` で検証。
5. 変更点と次のステップを要約。

## Trigger Examples

- 「OpenAPI 仕様を管理して SDK を生成するスキルを作って」
- 「このスキルの SKILL.md をリファクタして references/ にスキーマを追加して」
- 「SKILL.md を 500 行以内に収め、詳細は references/ に移して」

