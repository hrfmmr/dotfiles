# Technique: How Might We (HMW) reframing

## One-liner
観察や不満を、制約を可視化したまま解けるオープンな問いへ変換する。

## Use when
- 問題文が不満表現（「分かりにくい」など）になっている。
- 発想しやすい探索空間が必要。
- 制約を消さずに創造性を確保したい。

## Avoid when
- すでに良い問いがあり、次は発散だけでよい。
- 今すぐ具体計画が必要。

## Inputs
- 観察事実と制約。

## Procedure (fast, 4–7 min)
1. 不満/観察をそのまま書く。
2. 欲しい成果を抽出する。
3. 主要制約を「without ...」で追加する。
4. HMWを3バリエーション作る（広い/中間/狭い）。
5. 1つ選び、以降の発散に使う。

## Procedure (full, 10–15 min)
1. 観察を集める。
   - 「ユーザーはXをする」「Yが起きる」「〜のとき失敗する」。
2. HMW問いへ変換する。
   - Broad: 探索しやすい。
   - Focused: 制約を含む。
   - Experimental: 測定シグナルを含む。
3. 選ぶ。
   - 発想を生みつつ、検証可能な問いを採用する。

## Prompt bank (copy/paste)
- 「How might we <outcome> without <cost>?」
- 「<task>をデフォルトにしつつ、<edge case>も許容するには？」
- 「2週間で<pain>を50%減らすには？」

## Outputs (feed CPS portfolio)
- 質の高い発想プロンプト。
- 制約を反映した探索空間。

## Aha targets
- 「これはダメ」を「制約Y下でXを達成したい」へ変換できる。

## Pitfalls & defusals
- Pitfall: 広すぎる（例: すべてを改善） → Defusal: 制約と期限を追加する。
- Pitfall: 狭すぎる（例: このボタンを追加） → Defusal: 抽象度を1段上げる。

## Examples
### Engineering
Observation: 「この設定が分かりづらい。」
HMW: 「エッジケース向け明示オーバーライドを残しつつ、初期設定でセットアップが通るようにするには？」
Signal: セットアップ時間短縮。
Escape hatch: 上級オプションは expert flag の裏へ。

### Mixed domain
Observation: 「難しい作業を先延ばしする。」
HMW: 「モチベーション頼みでなく、難作業の着手摩擦を下げるには？」
Signal: 週あたり着手回数増。
Escape hatch: ストレス増ならタスク粒度を小さくする。
