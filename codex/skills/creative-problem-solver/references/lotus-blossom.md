# Technique: Lotus Blossom (structured breadth)

## One-liner
中心課題から外側へ展開する。まず関連領域を8つ作り、各領域を新たな中心として再展開する。混沌なく幅を出せる。

## Use when
- 構造を保ったまま大量の案が欲しい。
- 無制限ブレストがノイズ化しやすい。
- 技術/プロセス/人など複数角度を網羅したい。

## Avoid when
- 案は十分あり、収束が必要（Affinity Diagramming）。
- 矛盾解消が必要（TRIZ）。

## Inputs
- 中心となる問題文。

## Procedure (fast, 10–15 min)
1. 中心にコア問題を書く。
2. 花びらとして関連サブ領域を8つ書く。
3. 花びら2つを選び、それぞれで具体アクションを8つ出す。
4. 収束して3アクションを選び、実験化する。

## Procedure (full, 20–35 min)
1. First ring（8 petals）
   - 例: tooling, process, incentives, training, observability, rollouts, ownership, customer experience。
2. Second ring
   - 各花びらから具体アクションを8個作る。
3. Converge
   - 意図でクラスタ化。
   - CPS tierごとに1案選び、シグナル + エスケープハッチを付ける。

## Prompt bank (copy/paste)
- 「この成果に影響する隣接領域を8つ挙げると？」
- 「この花びらで具体アクションを8つ挙げると？」
- 「この花びらで試せる最小可逆アクションは？」

## Outputs (feed CPS portfolio)
- 網羅性の高い16〜72案。
- tierへの自然なマッピング（Quick Win向き花びらとMoonshot向き花びらが見える）。

## Aha targets
- 解は単一施策ではなく、複数レバーの組合せだと分かる。

## Pitfalls & defusals
- Pitfall: 花びらが曖昧（「品質を上げる」など） → Defusal: 具体行動へ繋がるカテゴリ名にする。
- Pitfall: どの花びらも同じ案になる → Defusal: 花びらごとに異なる領域を強制する。

## Examples
### Engineering
Core: 「本番障害を減らす。」
Petals: testing, observability, rollouts, ownership, training, tooling, oncall, architecture。
「rollouts」を展開: canary, feature flags, staged deploy, rollback automation。
Signal: 障害件数/週の減少。
Escape hatch: まず1サービス限定で試す。

### Mixed domain
Core: 「健康を改善する。」
Petals: sleep, food, exercise, stress, environment, habits, social, tracking。
「environment」を展開: 健康食の事前準備、ジャンク撤去、運動道具の見える化。
Signal: 継続率向上。
Escape hatch: 負荷過多なら範囲縮小。
