# Technique: Crazy 8s (rapid variation)

## One-liner
8分で8案を強制的に作ることで、最初の案から離れてレンジを確保する。UI設計にもテキスト設計にも使える。

## Use when
- 1つの無難な解をこね続けてしまう。
- 選ぶ前に「違いのある案」を揃えたい。
- 「より良い」より先に「別物」が必要。

## Avoid when
- 構造化された矛盾解消が必要（TRIZ）。
- 軸を網羅して体系的に組み合わせたい（Morphological Analysis）。

## Inputs
- ターゲット（「〜のバリエーションを8個作る」）。
- 厳密なタイマー。

## Procedure (fast, 8–12 min)
1. 対象成果物を定義する（CLI, API, プロセス, ページ, ポリシーなど）。
2. 8分タイマーをセット。
3. 8案出す。磨き込みは禁止。
4. 上位2案を選び、ハイブリッド1案に統合する。

## Procedure (full, 15–20 min)
1. Variant forcing functions (rotate per slot)
   - Slot 1: baseline.
   - Slot 2: minimal.
   - Slot 3: expert mode.
   - Slot 4: guided wizard.
   - Slot 5: defaults-first.
   - Slot 6: batch mode.
   - Slot 7: safety-first.
   - Slot 8: wild card.
2. Converge
   - シグナル + 可逆性で評価する。
   - 最良案を実験へ変換する。

## Prompt bank (copy/paste)
- 「1ステップ削るバリアント。」
- 「安全側をデフォルトにするバリアント。」
- 「複雑さをツール/自動化側へ移すバリアント。」
- 「初回ユーザー最適化のバリアント。」

## Outputs (feed CPS portfolio)
- 明確に異なる8パターン。
- 良い要素を取り込んだハイブリッド候補。

## Aha targets
- 新しいデフォルト。
- 新しい作業単位。

## Pitfalls & defusals
- Pitfall: 小改良8個になる → Defusal: スロットごとに強制関数を固定する。
- Pitfall: 収束しない → Defusal: 上位2つを選んで必ず統合する。

## Examples
### Engineering
ターゲット: 「同一タスク向けCLI設計を8案」。
バリアント: flags-only、対話式、config-first、wizard、presets、subcommands、安全ゲート、dry-run default。
選定: dry-run default + presets。
シグナル: 操作ミス減少。
エスケープハッチ: `--force` を用意。

### Mixed domain
ターゲット: 「フィードバック依頼方法を8通り」。
バリアント: 匿名フォーム、1:1、グループレトロ、記述式、オフィスアワー、ローテーションバディ、簡易投票、start/stop/continue。
選定: 簡易投票 + 月1の1:1。
シグナル: 回答率。
エスケープハッチ: 疲労感が出たら頻度調整。
