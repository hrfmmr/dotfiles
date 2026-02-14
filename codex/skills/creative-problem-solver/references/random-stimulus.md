# Technique: Random Stimulus (property transfer)

## One-liner
無関係な対象を選び、その「性質」を列挙して問題に強制マッピングする。表層の連想遊びを避けるため、抽象性質で扱う。

## Use when
- フレーミングが古くなり、新しい火花が欲しい。
- 既存解に過適合している。

## Avoid when
- 厳密な矛盾解消が必要（TRIZ）。
- 既に案が多く、収束だけが必要。

## Inputs
- ランダムな語/画像/物体（またはランダム見出し）。
- 先に「ダメ案」を出してもよい姿勢。

## Procedure (fast, 3–6 min)
1. 刺激語を引く。
2. 性質を8〜12個列挙する（動詞/形容詞）。
3. 強制マップする: 「この性質をシステムに持たせるなら？」
4. 1〜2案を選び、実験へ書き換える。

## Procedure (full, 10–15 min)
1. Stimulus selection
   - 真にランダムなソース（単語リスト）か、周囲の物を使う。
2. Property inventory
   - 物理特性、時間変化、故障モードを含める。
3. Mapping
   - 性質を architecture / process / incentives / UX に写像する。
4. Converge
   - 表現転換（Aha）が大きく、かつテスト可能な案を選ぶ。

## Prompt bank (copy/paste)
- 「<stimulus>の“用途”ではなく“性質”を列挙して。」
- 「“吸収してゆっくり放出する”をこの問題で実装すると？」
- 「この性質をプロセスに入れるなら何が変わる？」

## Outputs (feed CPS portfolio)
- 局所最適外に出る5〜10方向。

## Aha targets
- 見慣れないプリミティブ（バッファ、ゲート、負荷シェディング、自己修復）の導入。

## Pitfalls & defusals
- Pitfall: 文字通りのギミック化 → Defusal: 表層特徴ではなく性質を写像する。
- Pitfall: 1マッピングで終了 → Defusal: 少なくとも8性質を強制する。

## Examples
### Engineering
Stimulus: 「スポンジ」→ 吸収、ゆっくり放出、絞れる。
- Map: スパイク吸収用キュー/バッファを入れ、徐々に捌く。
Signal: スパイク時のtail latency低下。
Escape hatch: 遅延増ならバッファを無効化。

### Mixed domain
Stimulus: 「庭」→ 育成、季節性、剪定。
- Map: オンボーディング儀式 + 低シグナルチャネルの定期剪定。
Signal: エンゲージ品質向上。
Escape hatch: 参加率低下時は剪定を戻す。
