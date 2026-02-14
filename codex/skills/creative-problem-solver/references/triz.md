# Technique: TRIZ (resolve contradictions)

## One-liner
トレードオフが偽二択に見えるとき、矛盾を厳密に定義し、分離原理（+少数の発明原理）で抜け道を作る。

## Use when
- Xを良くするとYが悪化する（速度 vs 安全、柔軟性 vs 単純性）。
- 2つの悪い極端を往復してしまう。
- 「どちらかを選べ」が知的に不誠実に感じる。

## Avoid when
- まずゼロから幅広く案出ししたい（Brainstorming / Morphological Analysis）。
- 主課題が政治/合意形成（Six Thinking Hats）。

## Inputs
- Contradiction statement: 「<improve>を上げたいが、<degrade>が悪化する。」
- 文脈制約（変えられないもの）。

## Procedure (fast, 8–12 min)
1. 矛盾文を書く。
2. 4つの分離質問を行う。
   - time? space? condition? parts vs whole?
3. both/and候補を5〜10件生成。
4. 2候補を選び、実験（シグナル + エスケープハッチ）へ変換。

## Procedure (full, 20–35 min)
1. システム特定
   - 「対象物」とその境界は何か。
   - 活用できる資源は何か（時間、空間、情報、注意、未使用容量）。
2. 矛盾を明確化
   - Improve parameter: 何を上げたいか。
   - Worsen parameter: 何が傷むか。
3. 分離原理（主手段）
   - Separation in time: 重い処理を前後/非同期へ移す。
   - Separation in space: 厳格化をリスク領域だけに適用。
   - Separation on condition: リスク信号時だけ厳格化。
   - Separation between parts/whole: 部分最適しつつ全体挙動を守る。
4. 発明原理（軽量セット）
   - Segmentation: 分割（シャード、責務分割）。
   - Taking out: 痛い部分をクリティカルパス外へ。
   - Intermediary: バッファ/キュー/キャッシュ/プロキシを挿入。
   - Feedback: センシング + 制御ループ追加（error budget、alerts）。
   - Parameter change: 頻度・量・粒度を変更。
   - Local quality: セグメントごとに挙動を変える（hot path vs cold path）。
5. Converge
   - 高シグナルかつ可逆性の高い候補を選ぶ。

## Prompt bank (copy/paste)
- 「Yを常時払わずに、Xを“必要なときだけ”得るには？」
- 「厳格化を高リスク部分だけに限定できないか？」
- 「何をクリティカルパス外へ移せるか？」
- 「高価チェックを起動する安価シグナルは何か？」
- 「揺らぎを吸収するバッファは何か？」

## Outputs (feed CPS portfolio)
- both/and候補5〜10件。
- なぜトレードオフを突破できるかの明快な説明（説得に強い）。

## Aha targets
- 新しい分離次元（時間/空間/条件）で矛盾が崩れる。
- 厳格化を条件化するゲーティングシグナルの発見。

## Pitfalls & defusals
- Pitfall: 矛盾が曖昧（「UXを良くするとUXが悪化」） → Defusal: XとYを定量化する。
- Pitfall: 「トレードオフ受容」で終わる → Defusal: 先に分離質問を必須化。
- Pitfall: 過剰設計 → Defusal: 最小可逆の分離案を優先。

## Examples
### Engineering
Contradiction: 「応答を速くしたいが、厳格検証で遅くなる。」
- time分離: 書き込みは先に受理し、検証は非同期。次回書き込み時に拒否。
- condition分離: 異常シグナル時のみ厳格検証。
- intermediary: キュー/バッファを入れてワーカー検証。
Signal: p95改善かつ不正率上昇なし。
Escape hatch: 同期検証フラグへ即時復帰。

### Mixed domain
Contradiction: 「柔軟性を保ちたいが、信頼性も必要。」
- time分離: 週次で固定計画（信頼）+ 日次で柔軟枠。
- condition分離: 高リスクタスク時のみ厳格ルール。
- segmentation: コア約束と任意項目を分離。
Signal: 締切未達減少と自律性維持。
Escape hatch: 士気低下時に制約を緩和。
