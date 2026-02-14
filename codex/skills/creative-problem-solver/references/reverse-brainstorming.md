# Technique: Reverse Brainstorming (make it worse → invert)

## One-liner
失敗や痛みを増やす方法を大量に出し、各項目をセーフガードや機会へ反転する。リスク可視化と計画強化に強い。

## Use when
- 詰まりを打破し、隠れ前提を露出したい。
- 方針を失敗に強くしたい。
- チームが楽観に寄りすぎている。

## Avoid when
- 士気が低く、ネガティブ議論で悪化しやすい（先にSix Thinking Hats）。
- 純粋な新規発想が欲しい（Provocation / Synectics）。

## Inputs
- 目標成果 + 現在アプローチ。

## Procedure (fast, 6–10 min)
1. 「どうすれば確実に失敗/悪化させられるか？」と問う。
2. anti-ideaを10〜20件出す。
3. 各anti-ideaをセーフガード/設計要件に反転する。
4. セーフガード2件を選び、実験へ書き換える。

## Procedure (full, 15–25 min)
1. Reverse prompt
   - 「努力しているふりをしながら、どうすればX（悪い状態）を最大化できるか？」
2. Anti-idea generation
   - 技術だけでなく、社会/プロセス失敗も含める。
3. Inversion
   - anti-ideaを次に変換する。
     - guardrails, checks, rollouts, incentives, ownership rules。
4. Converge
   - シグナルと可逆性が最も良いセーフガードを選ぶ。

## Prompt bank (copy/paste)
- 「これを静かに失敗させるには？」
- 「顧客の痛みを最大化するには？」
- 「3か月で保守不能にするには？」
- 「悪意または怠慢の自分なら何をする？」

## Outputs (feed CPS portfolio)
- リスク棚卸し。
- オプション化されたセーフガード短冊（Quick Winになりやすい）。

## Aha targets
- 隠れた結合点。
- 欠けたシグナル/指標（失敗しても気づけない点）。

## Pitfalls & defusals
- Pitfall: 皮肉スパイラル → Defusal: 時間制限し、反転工程を必須にする。
- Pitfall: 反転後が抽象論（「もっと連携」） → Defusal: 具体機構まで落とす。

## Examples
### Engineering
Prompt: 「悪いデプロイを確実化するには？」
- Anti-ideas: staging非同等、rollback無し、エラー無視。
- Inversions: staging parityチェック、rollback hook、error-budget alert。
Signal: rollback率低下。
Escape hatch: hotfix阻害時はparity gateを一時停止。

### Mixed domain
Prompt: 「協業関係を悪化させるには？」
- Anti-ideas: 難しい会話を避ける、意図を決めつける、謝らない。
- Inversions: 定期チェックイン、期待値明文化、修復儀式。
Signal: 再発衝突の減少。
Escape hatch: 形式化が過剰なら頻度調整。
