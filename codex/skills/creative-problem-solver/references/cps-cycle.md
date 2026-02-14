# Technique: CPS Cycle (Clarify → Ideate → Develop → Implement)

## One-liner
ループを防ぐための進行骨格。範囲と制約を明確化し、発散で案を出し、上位案を実験仕様（シグナル + エスケープハッチ）へ強化し、最後に最小の可逆ステップへ落とす。

## Use when
- 議論が堂々巡りで、要件も曖昧。
- 斬新さより、追跡可能性が必要。
- 多制約問題で「唯一解」より「次に良い一手」が欲しい。

## Avoid when
- すでに方向が決まっており、実行手順だけ欲しい。
- 60秒で再フレームだけしたい（Oblique Draw / Random Stimulus）。

## Inputs (minimum viable)
- Goal: 1文。
- Constraints: 時間、予算、ポリシー、技術、人。
- Unknowns: 計画を変える可能性がある不確実性。

## Procedure (fast, 5–10 min)
1. Clarify: 契約文を書く。「うまくいった状態は…」。強制約を1〜3個明記。
2. Ideate: 批評なしで候補を10〜20件出す。
3. Develop: 3候補を選び、各候補を実験形式へ書き換える。
   - Hypothesis → Expected signal → Escape hatch。
4. Implement (conceptual): 最良候補に対し、最小の可逆な次アクションを提案する。

## Procedure (full, 20–45 min)
1. Clarify
   - Goal / Non-goal / Constraints / Stakeholders を定義する。
   - 症状（何が痛いか）と機構（なぜ痛いか）を分ける。
   - 最適化対象（速度、品質、コスト、士気、リスク）を明示する。
2. Ideate (diverge)
   - 30件以上生成し、各案に動詞ラベルを付ける（reduce, split, cache, delegate, rename, automate）。
   - 技術レバー + プロセスレバー + インセンティブレバーを混ぜる。
3. Develop (converge)
   - 意図でクラスタ化し、3〜5クラスタに絞る。
   - 各クラスタ代表を1つ選び、以下を具体化する。
     - 前提、リスク、可逆性、判定方法。
4. Implement (plan)
   - 具体化候補を5-tier CPSポートフォリオに配置する。
   - ユーザーにtier選択を求め、勝手に実行しない。

## Prompt bank (copy/paste)
- Clarify
  - 「これが成功したら、観測可能に何が変わるか？」
  - 「何は絶対に変えてはいけないか？」
  - 「交渉不能な制約は何か？」
  - 「最小の“十分良い”到達点は？」
- Ideate
  - 「ボトルネックを変える方法を20個。」
  - 「Xを変えられないなら何をする？」
  - 「48時間で出す必要があるなら何をする？」
- Develop
  - 「1日/1週間で期待するシグナルは？」
  - 「間違っていた場合のエスケープハッチは？」
  - 「最小の可逆実験は何か？」

## Outputs (feed CPS portfolio)
- 明確な契約文。
- 発散で得た候補一覧。
- シグナル + エスケープハッチ付きの実験3〜5件。

## Aha targets
- 問題を「ボトルネック」「キュー」「インセンティブ不一致」「インターフェース境界」として再表現できる。
- 「最善案を選ぶ」から「識別力の高い最速実験を回す」へ転換できる。

## Pitfalls & defusals
- Pitfall: Clarifyに留まり続ける → Defusal: 時間制限し、未知は「検証すべき前提」へ移す。
- Pitfall: 発散に批評が混ざる → Defusal: フェーズ分離を明示し、発散中は採点しない。
- Pitfall: Implementが実装実行になる → Defusal: 「最小可逆の次ステップ」提案までで止める。

## Examples
### Engineering
Goal: デプロイリスク低減。
- Clarify: 「週1回未満のロールバックで、毎日デプロイできる状態」。
- Ideate: canary, feature flag, contract test, staged rollout, shadow traffic。
- Develop: ロールバックトリガー付きcanary実験。
- Implement: 1サービスで実施し、ロールバック率測定。

### Mixed domain
Goal: チーム間アラインメント改善。
- Clarify: 「スプリント2週目の想定外依存が減る状態」。
- Ideate: 週次依存レビュー、共有ロードマップ、依存ごとの単一責任者。
- Develop: 30分の依存syncを2スプリント試行。
- Implement: 2回実施して、割り込み件数を測定。30分超過負担が大きければ停止。
