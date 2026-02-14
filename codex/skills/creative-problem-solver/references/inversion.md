# Technique: Inversion (flip the problem)

## One-liner
目標や前提を反転し、「逆の解」を大量に出してから、再反転して具体レバーに変える。

## Use when
- 局所最適に詰まっている（「やれることは全部やった」）。
- 隠れた前提や聖域がある気がする。
- 大掛かりなpre-mortemなしで失敗洞察が欲しい。

## Avoid when
- すでに問題設定が明確で、実行だけが必要。
- 士気が不安定で、負の枠組みが悪化要因になる（先にSix Thinking Hats）。

## Inputs
- Goal / outcome（1文）。
- Constraints（hard/soft）。
- Current approach（任意、1〜2行）。

## Procedure (fast, 3–7 min)
1. 目標を書く: 「私たちはXを達成したい。」
2. 反転する。
   - 「Xの逆を最大化するには？」
   - または「Xを不可能にするには？」
3. 反転案（anti-move）を10個出す（批評なし）。
4. 各anti-moveをレバーへ反転する（ガードレール、デフォルト、インターフェース、インセンティブ）。
5. 1〜2レバーを選び、実験に変換（シグナル + エスケープハッチ）。

## Procedure (full, 12–20 min)
1. 反転モードを選ぶ。
   - Failure mode: 「失敗を確実化するには？」（リスク可視化）
   - Opposite outcome: 「逆成果を最大化するには？」（新規レバー探索）
   - Constraint flip: 「制約Cがなければ？ 代わりに何が制約化する？」
2. Anti-moveを生成する。
   - 技術・社会・プロセスの全側面を含める。
3. Mechanism extraction（重要）
   - 各anti-moveについて「何の機構で有害化するか？」を問う。
   - 機構名を付ける（handoff、欠落シグナル、結合、インセンティブ、遅延）。
4. レバーへ再反転する。
   - 例:
     - missing signal → 計測/警報を追加。
     - coupling → 境界分離/疎結合化。
     - incentive → 責任/評価軸を変更。
     - handoff → 手順削除/境界明確化。
5. 収束する。
   - 高シグナルで可逆なレバーを選ぶ。

## Prompt bank (copy/paste)
- 「これを静かに失敗させるには？」
- 「10倍悪化させるには？」
- 「妨害者なら何をする？」
- 「このanti-moveはどの前提を突いている？」
- 「その逆向きセーフガードは何？」

## Outputs (feed CPS portfolio)
- anti-move 10件。
- 反転レバー3〜5件。
- 明確なシグナル + エスケープハッチ付き実験1〜2件。

## Aha targets
- 欠けているのは努力ではなく検知である、と見抜ける。
- 聖域（所有、デフォルト、境界）を変数として扱える。

## Pitfalls & defusals
- Pitfall: 皮肉・悲観に流れる → Defusal: 時間制限し、「レバーへの再反転」を必須化する。
- Pitfall: anti-moveが雰囲気論 → Defusal: 機構名を必ず書く。
- Pitfall: テスト不能なレバー → Defusal: 最小可逆実験へ書き換える。

## Examples
### Engineering
Goal: デプロイリスク低減。
Inversion: 「悪いデプロイを確実に起こすには？」
- Anti-moves: staging非同等、rollback無し、エラー無視。
- Inverted levers: staging parity gate、rollback hook、error-budget alert。
Signal: rollback率低下。
Escape hatch: 緊急時のみparity gateを一時緩和。

### Mixed domain
Goal: 集中力向上。
Inversion: 「確実に気が散る状態を作るには？」
- Anti-moves: 通知ON、次タスク不明、スマホを手元に置く。
- Inverted levers: 通知ブロック、明示的next action、環境設計。
Signal: deep-work枠/週の増加。
Escape hatch: 協働低下時はブロックを緩和。
