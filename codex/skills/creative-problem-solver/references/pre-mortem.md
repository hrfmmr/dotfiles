# Technique: Pre-mortem (assume failure → mine causes)

## One-liner
時間を先に進めて「失敗した前提」で原因を掘る。上位原因を緩和策と識別実験へ変換する。

## Use when
- 既に計画があり、コミット前にリスクを下げたい。
- ありきたりでない失敗モードを洗い出したい。
- 移行・ローンチ・組織変更など、失敗コストが高い。

## Avoid when
- まだ何をやるかを決める段階（Brainstorming / Morphological Analysis）。
- すでにリスク麻痺しているチーム。

## Inputs
- 計画（または有力候補）。
- 時間地平（「3か月後…」）。

## Procedure (fast, 8–12 min)
1. 「<時間>後、私たちは失敗した。なぜか？」と書く。
2. 失敗原因を10〜15件出す。
3. 発生確率 × 影響度で上位3件を選ぶ。
4. 各上位原因に、緩和策 + シグナル + エスケープハッチを付ける。

## Procedure (full, 20–30 min)
1. Setup
   - 計画名と成功基準を定義する。
2. Silent generation
   - 各参加者が私的に失敗原因を書く（アンカリング回避）。
3. Aggregate + cluster
   - 原因を tech / process / people / market で束ねる。
4. Convert to actions
   - 上位テーマごとに以下を設計する。
     - prevention（ガードレール）
     - detection（シグナル）
     - response（エスケープハッチ）
5. Converge
   - 複数原因を同時に下げる高シグナル実験を1〜2件選ぶ。

## Prompt bank (copy/paste)
- 「何が想定外だったか？」
- 「何を過小評価していたか？」
- 「どこで所有責任が曖昧だったか？」
- 「どの依存が失敗したか？」
- 「静かに進む失敗モードは何か？」

## Outputs (feed CPS portfolio)
- 優先順位付き失敗モード一覧。
- 実験 + ガードレールとして表現された緩和計画。

## Aha targets
- 真のリスクが技術ではなく、組織や所有責任だと見える。
- 「リスク」を「計測 + ロールバック計画」に変換できる。

## Pitfalls & defusals
- Pitfall: 悲観スパイラル → Defusal: 時間制限し、最後に必ず緩和策へ変換する。
- Pitfall: 原因が抽象（「コミュニケーション不足」） → Defusal: 具体機構（成果物、会議、責任者）へ落とす。

## Examples
### Engineering
Plan: 新service meshへ移行。
- 失敗原因: ownership不明、トラフィック劣化、観測性不足、rollback遅延。
Mitigations: canary rollout、指標ダッシュボード、rollback playbook。
Signal: エラー率 + レイテンシ。
Escape hatch: サービス単位で旧meshへ戻す。

### Mixed domain
Plan: コミュニティイベント開催。
- 失敗原因: 集客不足、アジェンダ不明、ボランティア疲弊。
Mitigations: 事前登録、アジェンダ草案、ロール分担ローテーション。
Signal: 期日までの登録数。
Escape hatch: 参加が低い場合は規模縮小。
