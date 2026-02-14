# Technique: SCAMPER (mutate a baseline)

## One-liner
既存案を変異させるための構造化エンジン。Substitute, Combine, Adapt, Modify, Put to use, Eliminate, Reverse。

## Use when
- ベース案はあるが、より良い変種が必要。
- フルリセットせずに創造性を出したい。
- 安定して選択肢を生むプロンプト群が欲しい。

## Avoid when
- ベース案がまったくない（Brainstorming / Brainwriting）。
- 核が「Xを良くするとYが悪化」の矛盾（TRIZ）。

## Inputs
- Baseline（現行解、計画、API、ワークフロー）。
- 目標成果 + 制約。

## Procedure (fast, 8–12 min)
1. ベースラインを1〜2行で書く。
2. SCAMPERプロンプトを走らせ、各文字2〜3案生成。
3. 上位3案を選び、実験（シグナル + エスケープハッチ）へ変換。

## Procedure (full, 15–25 min)
1. Baseline inventory
   - 構成要素/手順を列挙（A → B → C）。
   - ボトルネックステップを特定。
2. SCAMPER sweep
   - S: 構成要素を置換（ツール、担当、IF）。
   - C: 手順や責務を統合。
   - A: 近接領域から適応。
   - M: 量/頻度/順序を変更。
   - P: 既存資産を別用途へ転用。
   - E: 手順/権限/判断を削除。
   - R: 方向・順序・所有・デフォルトを反転。
3. Converge
   - 速度最適1案、可逆性最適1案、シグナル最適1案を選ぶ。

## Prompt bank (copy/paste)
- Substitute: 「この手順を別の担当/ツールに置換すると？」
- Combine: 「2手順を1境界に統合すると？」
- Adapt: 「似た制約を解いている他領域は？」
- Modify: 「10分の1頻度/10倍頻度なら？」
- Put to use: 「再利用できる既存資産は？」
- Eliminate: 「安全を保って削れる最小ステップは？」
- Reverse: 「逆デフォルトにすると？」

## Outputs (feed CPS portfolio)
- ベースラインに根ざした変種セット（説明しやすい）。
- 具体化された実験候補の短冊。

## Aha targets
- 可逆なデフォルト。
- 安全を落とさず手順を削る（ガードレール置換）。

## Pitfalls & defusals
- Pitfall: 制約違反の変種が多い → Defusal: 常に制約を冒頭に明示する。
- Pitfall: Modifyだけで終わる → Defusal: 各文字最低1案を強制する。
- Pitfall: テスト不能 → Defusal: 上位案を測定可能実験へ書き換える。

## Examples
### Engineering
Baseline: フレーキーなテストスイート。
- Eliminate: 共有グローバル状態を排除。
- Combine: セットアップを単一fixtureへ統合。
- Reverse: 内部実装より境界契約をテスト。
Signal: flake率低下。
Escape hatch: 破壊的ならfixture変更を戻す。

### Mixed domain
Baseline: 週次チーム定例。
- Eliminate: 会議を廃止し、非同期更新に置換。
- Reverse: 成果報告より先にblocker共有。
- Substitute: 進行役をローテーション。
Signal: 割り込み減 + 優先順位の明確化。
Escape hatch: blocker増加時は15分会議を復帰。
