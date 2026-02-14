# Technique: Forced Connections (systematic recombination)

## One-liner
無関係な2つ（または離れた問題要素2つ）を意図的に接続してハイブリッド案を作る。Random Stimulusより体系的。

## Use when
- 新規性は欲しいが、手順は構造化したい。
- 要素や関係者が多く、意外な組み合わせを探したい。
- 中品質のひらめきを短時間で多く欲しい。

## Avoid when
- 主課題が明示的な矛盾（TRIZ）。
- 深い共感・合意形成が主課題（Six Thinking Hats）。

## Inputs
- Set A: 5〜10個の「対象要素」（部品、関係者、制約、資産）。
- Set B: 5〜10個の「接続先」（ランダム語、パターン、他領域解）。

## Procedure (fast, 6–10 min)
1. Set A（問題要素）を列挙する。
2. Set B（ランダム/異領域パターン）を列挙する。
3. 6〜10ペアを選び、「BはAにどう効くか？」を考える。
4. 上位2案を実験へ変換する。

## Procedure (full, 15–25 min)
1. 小さな行列を作る。
   - 行: 問題要素。
   - 列: 異領域パターン（marketplace, subscription, cache, triage, delegation など）。
2. 各セルで1案作る。
   - 「<pattern>を<element>へ適用すると何が起きるか？」
3. 収束する。
   - (a) 表現が変わる、(b) テスト可能、の両方を満たす案を残す。

## Prompt bank (copy/paste)
- 「<pattern>で<problem element>のコストをどう下げるか？」
- 「<pattern>の最小版をどう試すか？」
- 「これが marketplace / triage desk / assembly line なら対応工程は？」

## Outputs (feed CPS portfolio)
- ハイブリッド案一覧（「要素YにパターンXを適用」）。
- 高シグナル実験1〜3件。

## Aha targets
- 新しい分解の仕方（ルーティング問題、トリアージ問題、バッチング問題）。

## Pitfalls & defusals
- Pitfall: 抽象のまま終わる → Defusal: 必ず具体物（API、チェックリスト、ポリシー）にする。
- Pitfall: 低価値案が多すぎる → Defusal: シグナル + 可逆性で採点し、少数に絞る。

## Examples
### Engineering
Set A: ログインフロー、レート制限、サポートチケット。
Set B: 「空港保安」「トリアージ」「サブスクリプション」。
- トリアージ × サポートチケット → 重症度ルーティング + 次アクションテンプレ。
- サブスク × レート制限 → tier別上限 + バーストクレジット。
Signal: サポート負荷減 / 429減少。
Escape hatch: 不公平ならtierを撤回。

### Mixed domain
Set A: 個人財務、運動、友人関係。
Set B: 「canary」「batching」「feedback loop」。
- feedback loop × 財務 → 週次で1指標（バーンレート）レビュー。
- batching × 友人関係 → 週1の定期キャッチアップ枠。
Signal: 安定性・継続性向上。
Escape hatch: ストレス増なら儀式を停止。
