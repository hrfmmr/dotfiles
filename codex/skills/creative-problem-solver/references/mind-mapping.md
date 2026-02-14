# Technique: Mind Mapping (externalize the space)

## One-liner
問題空間を放射状マップとして外在化し、クラスタ・欠落・次に効く再フレームを可視化する。

## Use when
- 論点が多く、認知負荷が高い。
- 関係者や制約の見落としが疑われる。
- 最も薄い枝（しばしば真のレバー）を見つけたい。

## Avoid when
- 案は十分あり、収束が必要（Affinity Diagramming）。
- 鋭いトレードオフ突破が必要（TRIZ）。

## Inputs
- 中心となる問題文。

## Procedure (fast, 5–8 min)
1. 問題を中央に置く。
2. 一次枝を5〜7本作る（stakeholders, causes, constraints, options, risks, signals）。
3. 各枝に2〜3の下位枝を追加する。
4. 「薄い枝」または「意外な枝」を次の再フレーム対象に選ぶ。

## Procedure (full, 15–25 min)
1. Branching pass（幅）
   - Stakeholders: 痛みを受ける人/変えられる人。
   - Mechanisms: 根本原因、ボトルネック、フィードバックループ。
   - Constraints: hard / soft。
   - Options: 候補レバー。
   - Signals: 改善を示す観測値。
   - Risks: 何が失敗するか。
2. Deepening pass（深さ）
   - 各枝で「なぜ/どうやって/他に」を問う。
3. Converge
   - 支配的仮説となる枝を1つ選ぶ。
   - その枝を狙うオプションを作る。

## Prompt bank (copy/paste)
- 「ここに表れていない関係者は誰か？」
- 「フィードバックループはどこか？」
- 「ボトルネックはどこか？」
- 「どんなシグナルが出たら計画を変えるか？」
- 「最も情報が薄い枝はどこで、なぜか？」

## Outputs (feed CPS portfolio)
- 探索空間の構造化マップ。
- 実験で狙う優先枝。

## Aha targets
- 問題の本体が「スキル不足」ではなく「権限」「ツール」「インセンティブ」「引き継ぎ」だと分かる。

## Pitfalls & defusals
- Pitfall: マッピングが終わらない → Defusal: 時間制限し、枝が反復し始めたら止める。
- Pitfall: 記述だけで終わる → Defusal: 1枝を必ず行動レバーに翻訳する。

## Examples
### Engineering
Problem: オンボーディングが遅い。
Branches: 環境、権限、ドキュメント、ツール、サンプルデータ、メンタリング。
Aha: 権限枝が薄い → 主ボトルネック候補。
Option: ロール事前付与 + アクセス申請自動化。
Signal: 初回PRまでの時間。

### Mixed domain
Problem: 常に圧倒される感覚がある。
Branches: 義務、エネルギー、境界、ルーチン、支援。
Aha: 境界枝が薄い → 制約設定不足。
Option: ノーミーティング枠を設定。
Signal: 週次ストレス評価。
Escape hatch: 協働悪化時は枠を調整。
