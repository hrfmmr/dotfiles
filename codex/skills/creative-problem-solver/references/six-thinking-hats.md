# Technique: Six Thinking Hats (parallel perspectives)

## One-liner
グループ全体（または自分の思考）を同じ順序で視点切替させ、立場のぶつかり合いを避けてトレードオフを整理する。

## Hats (mnemonic)
- White: 事実、データ、未知。
- Red: 感情、直感、士気、不安。
- Black: リスク、失敗モード、下振れ。
- Yellow: 利点、上振れ、機会。
- Green: 新案、代替、ハイブリッド。
- Blue: 進行、意思決定、次アクション。

## Use when
- アラインメントが難しく、議論がすれ違う。
- 分析と主張が混ざって進まない。
- 重要案件で、判断根拠を残したい。

## Avoid when
- まず大量発散が必要（Brainwriting / Brainstorming）。
- 核が鋭い矛盾で、発明的解決が必要（TRIZ）。

## Inputs
- 検討する意思決定または提案。
- 各hatの時間枠（2〜5分）。

## Procedure (fast, 10–15 min)
1. Blue（開始）: 判断対象 + 制約 + 時間枠を定義。
2. White: 事実と未知を列挙（解釈禁止）。
3. Black + Yellow: リスクと利点を分離して列挙。
4. Green: 代替/ハイブリッドを5〜10件生成。
5. Blue（終了）: 最小可逆ステップ、または決めるための追加情報を定義。

## Procedure (full, 20–30 min)
1. Blue (setup)
   - 「私たちは〜の間で意思決定する」と明示。
   - 良い意思決定の条件（成功基準）を定義。
2. White
   - 事実、制約、ベースライン、指標。
   - 決定を反転させる未知を列挙。
3. Red
   - 人間側の現実（不安、期待、信頼、疲労）を言語化。
   - 感情は証拠ではなくシグナルとして扱う。
4. Black
   - 失敗モード、隠れコスト、二次影響。
5. Yellow
   - 利得、レバレッジ、将来容易化される点。
6. Green
   - 「リスク20%で上振れ80%を得るには？」のハイブリッドを作る。
   - staged rollout などの both/and 案を作る。
7. Blue (close)
   - 上位1〜2候補を実験（シグナル + エスケープハッチ）にする。

## Prompt bank (copy/paste)
- White: 「分かっていることと仮定を分けると？」
- Red: 「何を恐れ、何を期待しているか？」
- Black: 「どう失敗するか？ 鋭いエッジは何か？」
- Yellow: 「どの上振れがリスクに見合うか？」
- Green: 「最悪下振れを避けつつ利得を取るハイブリッドは？」
- Blue: 「シグナルが取れる最小可逆ステップは？」

## Outputs (feed CPS portfolio)
- 構造化されたトレードオフ棚卸し。
- 対立案を超えるハイブリッド1〜3件。

## Aha targets
- 議論を動かしている隠れ制約（White）や隠れ不安（Red）の発見。
- 「主張対立」を「実験比較」へ変換。

## Pitfalls & defusals
- Pitfall: hat混在（Green中にBlack批評） → Defusal: hat純度を厳守する。
- Pitfall: Redが感情操作化 → Defusal: 感情は結論ではなくシグナル扱い。
- Pitfall: 決まらない → Defusal: Blueの終了条件を「次ステップ or 情報収集計画」に固定。

## Examples
### Engineering
Decision: 「managed DBへ移行するか」。
- White: 現在コスト、障害履歴、レイテンシSLO。
- Black: lock-in、移行リスク、egressコスト。
- Yellow: 運用時間削減、信頼性、スケール。
- Green: まずmanaged read replicaだけ導入する段階移行。
- Blue: 非クリティカル1サービスを移行し、障害率 + レイテンシを観測。

### Mixed domain
Decision: 「役割を変えるか、現状維持か」。
- White: 報酬、成長路線、負荷。
- Red: 退屈、不安、自己像。
- Black: 後悔リスク、専門性喪失。
- Yellow: スキル複利、動機回復。
- Green: 先に社内ローテーション/副プロジェクト。
- Blue: 2週間のシャドーイング + 情報面談で検証。
Signal: エネルギー感 + 判断明瞭度。
