# Technique: Storyboarding (end-to-end flow)

## One-liner
トリガーから結果までの流れを叙述（または図示）し、引き継ぎ点・判断点・失敗点を明らかにする。抜け手順と計測点が見える。

## Use when
- 複数ステップの旅程が問題本体（障害対応、オンボーディング、チェックアウト）。
- 中核処理ではなく、引き継ぎ/境界で失敗している疑いがある。
- どこに介入・計測すべきか決めたい。

## Avoid when
- まず案の幅が欲しい（Brainwriting / Lotus Blossom）。
- 概念ジャンプが必要（Synectics / Provocation）。

## Inputs
- Actor(s): 誰がこの流れを体験するか。
- Start trigger + desired end state。

## Procedure (fast, 8–12 min)
1. 8〜12ステップでフローを書く（A → B → C）。
2. 次の2点をマークする。
   - decision points
   - failure points
3. failure pointごとに測定シグナルを1つ追加。
4. 1ステップを選んで改善実験を作る。

## Procedure (full, 20–30 min)
1. レーンを設定する。
   - ユーザーレーン、システムレーン、人手運用レーン（相当するもの）。
2. happy pathを追う。
   - 引き継ぎと待ち時間を含める。
3. 主要failure pathを追う。
   - どこで劣化し、どう検知し、どう対処するか。
4. レバレッジ点を特定する。
   - ボトルネックステップ、未知最大ステップ、最良計測点。
5. CPSオプションへ変換する。
   - 各案をレバレッジ点に対応させ、シグナル + エスケープハッチを付ける。

## Prompt bank (copy/paste)
- 「痛みの直前に何が起きているか？」
- 「どこで待っているか？」
- 「どこで責任を引き継いでいるか？」
- 「どこなら早期検知できるか？」
- 「最速で取れる計測シグナルは何か？」

## Outputs (feed CPS portfolio)
- 共有可能なフローモデル。
- 介入点 + 計測案の短いリスト。

## Aha targets
- 実問題が「引き継ぎ」「待ち」「検知欠落」であることの発見。

## Pitfalls & defusals
- Pitfall: 粒度が粗すぎる → Defusal: 手順と責任者を具体化する。
- Pitfall: シグナルがない → Defusal: 各failure pointに必ず検知シグナルを置く。

## Examples
### Engineering
Flow: 「incident → triage → mitigate → recover → follow-up」。
Leverage: 検知（シグナル不足）とrollback（遅さ）。
Option: error-budget alert + rollback playbook。
Signal: MTTR低下。
Escape hatch: ノイズ過多ならalert停止。

### Mixed domain
Flow: 「顧客苦情 → 受付 → 診断 → 解決 → フォロー」。
Leverage: 診断への引き継ぎ。
Option: 構造化受付フォーム + ルーティング。
Signal: 解決時間短縮。
Escape hatch: 完了率低下時はフォーム簡素化。
