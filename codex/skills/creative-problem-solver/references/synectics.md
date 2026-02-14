# Technique: Synectics (analogy ladder)

## One-liner
類推のはしごを上る（直接類推 → 擬人化 → 象徴化、場合によっては空想）ことで表現を作り替え、最後に具体レバーへ戻す。

## Use when
- 小改良ではなく概念ジャンプが必要。
- 同じ言葉で問題を言い換えるだけになっている。
- 新しいモデルによるAhaが欲しい。

## Avoid when
- 問題が組合せ設定中心（Morphological Analysis）。
- 主要障害が矛盾（TRIZ）。

## Inputs
- 明確な改善対象（何を良くしたいか）。
- 比喩フェーズで一時的に「変な発想」を許容する姿勢。

## Procedure (fast, 6–10 min)
1. 直接類推: 「これは〜のようだ」を3件出す。
2. 擬人化類推: 「自分がこのシステムなら、どう感じるか」。
3. 象徴類推: 短い比喩へ圧縮（例: signal vs noise、leaky bucket）。
4. 翻訳: 比喩が示す具体レバーを3件抽出する。

## Procedure (full, 15–25 min)
1. 直接類推（3〜5件）
   - 解法が成熟した領域から選ぶ（医療、物流、製造、生態系）。
2. 擬人化類推
   - 制約を受ける要素の視点を取る（ユーザー、当番、サブシステム）。
3. 象徴類推
   - 二語で本質を定義（例: 「注意税」「信頼負債」）。
4. 行動へ翻訳
   - 各比喩について性質を列挙し、以下へ対応付ける。
     - constraints, levers, failure modes, measurable signals。
5. 収束する。
   - 問題表現を最も変える比喩を採用。

## Prompt bank (copy/paste)
- 「これは〜に似ている（全く異なる3領域を選ぶ）。」
- 「自分がボトルネックなら何を望むか？」
- 「この問題を二語で象徴すると？」
- 「この比喩は、何を remove / buffer / route せよと言っているか？」

## Outputs (feed CPS portfolio)
- 新しい表現（比喩）+ 具体レバー3件。
- そこから導いた実験候補。

## Aha targets
- プリミティブ切替（features→flows、bugs→risk exposure、customers→queues）。

## Pitfalls & defusals
- Pitfall: 比喩が可愛いだけで終わる → Defusal: constraints/levers/signalsへの翻訳を強制。
- Pitfall: 比喩を作り続けて終わる → Defusal: 時間制限し、最強の表現転換1つを選ぶ。
- Pitfall: 都合の良い類推だけ採用 → Defusal: 複数類推を並べて比較。

## Examples
### Engineering
Problem: 警報ノイズ過多。
- Direct: 煙感知器、スパムフィルタ、空港保安。
- Personal: 「当番として、不要呼び出しで起こされる。」
- Symbolic: 「signal vs noise」。
Levers: 重症度ルーティング、重複除去、エラーバジェット、閾値調整。
Signal: ページ数/週 + MTTR。

### Mixed domain
Problem: 会議で衝突が再発。
- Direct: 交差点、オーケストラ、裁判。
- Personal: 「寡黙参加者として会話に合流できない。」
- Symbolic: 「優先通行」。
Levers: 進行ルール、発言順、明示的ターンテイク。
Signal: 参加分布。
Escape hatch: 会議遅延が増えたら戻す。
