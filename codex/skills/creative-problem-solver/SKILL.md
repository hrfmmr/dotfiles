---
name: creative-problem-solver
description: 横断的な発想で選択肢とトレードオフを提示するプレイブック。常に 5 段階の戦略ポートフォリオを出す。
---

# Creative Problem Solver

## Contract (one assistant turn)
- 現在の Double Diamond ステージ（Discover / Define / Develop / Deliver）を明示。
- Define が弱い場合: 1 行の仮定義 + 成功基準を出し、ポートフォリオは学習ムーブとして扱う。
- 選択肢を提示して停止し、実行前に人の判断を求める。
- 5 段階ポートフォリオを必ず含める: Quick Win, Strategic Play, Advantage Play, Transformative Move, Moonshot。
- 各案に Expected signal と Escape hatch を付ける。
- Reframe 後に Aha Check を実行。
- 技法の出所を追跡（technique → Aha Y/N）。同じ技法が連続で Aha を生んだら次は別技法に切替。
- Knowledge Snapshot + Decision Log を短く残す。

## When to use
- 進捗が詰まっている/ブロックされている。
- 同じ失敗を繰り返している。
- 選択肢/代案/トレードオフの提示を求められた。
- 複数制約・複数領域・高不確実性の問題（設計/移行/統合/調停）。

## Quick start
1. Double Diamond ステージを選ぶ: Discover / Define / Develop / Deliver。
2. レーンを選ぶ: Fast Spark or Full Session。
3. 1 回リフレーム（ツールを 1 つ選ぶか Oblique Draw）。
4. Aha Check。なければもう 1 回リフレーム。
5. 5 段階ポートフォリオ生成（Discover/Define は学習ムーブ）。
6. ゲート定義: 問題文 + 成功基準（不明なら明示）。
7. 1–5 で採点: Signal, Ease, Reversibility, Speed。
8. ユーザーにティア選択 or 制約更新を求める。
9. Insights Summary で閉じる。

## Double Diamond alignment
- Discover（発散）: 文脈拡張、学習に焦点。
- Define（収束）: 問題定義 + 成功基準を固め、未知を表に出す。
- Develop（発散）: 解決案の広げ。
- Deliver（収束）: 実行ティアを選び、`tk` に引き渡す。

## Mode check
- Pragmatic（既定）: 今週出せる範囲。
- Visionary: 長期戦略/制度変更が求められた場合のみ。

## Lane selector
- Fast Spark: 発想ステップを省略し、直接ポートフォリオを出す。
- Full Session: 10–30 のアイデアを出し、クラスタ/スコアリングしてティア別に選ぶ。

## Reframing toolkit
以下から 1 つ:
- Inversion: 現在のアプローチを反転。`references/inversion.md`。
- Analogy transfer: 解決済み領域のパターンを借りる。`.../analogy-transfer.md`。
- Constraint extremes: 変数を 0/∞ にする。`.../constraint-extremes.md`。
- First principles: 基本事実から再構築。`.../first-principles.md`。

## Oblique draw (optional)
フレーミングが硬いときに使用。`.../oblique-draw.md`。
1. 4 つ引いて 1 つ選ぶ。
2. それを具体的なレバー/制約に翻訳。

Mini-deck（デッキ無しの場合）:
- 当たり前の逆をやる。
- 手順を 1 つ消す。
- まず可逆にする。
- 計画を変えうる最小のテスト。
- ボトルネックを変える（スループットではなく）。
- 作業単位を変える。
- 制約を入れ替える。
- 別領域のパターンを借りる。

## Aha Check (required)
- 定義: 体型が変わる洞察（新しい表現/モデル）。
- 出力: 1 行の洞察。なければ再フレームをもう 1 回。

## Portfolio rule
- 5 段階すべてを必ず出す。
- Discover/Define の場合は学習ムーブとして提示。
- Develop/Deliver の場合は解決ムーブとして提示。

## Option template
```
Quick Win:
- Expected signal:
- Escape hatch:

Strategic Play:
- Expected signal:
- Escape hatch:

Advantage Play:
- Expected signal:
- Escape hatch:

Transformative Move:
- Expected signal:
- Escape hatch:

Moonshot:
- Expected signal:
- Escape hatch:
```

## Scoring rubric (1–5, no weights)
- Signal: 新しい情報をどれだけ得られるか。
- Ease: 試す労力/複雑さ。
- Reversibility: 戻しやすさ。
- Speed: 学びまでの速さ。

優先: 高 Signal + 高 Reversibility、その次に Ease + Speed。

## Technique rules (progressive disclosure)
- 既定で 1 つ選ぶ（詰まったら 2–3）。
- 技法選択後、`references/` の参照ファイルを読む。
- チャットでは `Reframe used: <technique>` + 1 行理由だけ。スクリプト全文は不要。

## Technique picker (choose 1; rarely 2)
- Aha なし → Provocation (PO) / Forced Connections / Synectics / TRIZ。
- 速い着火 → Oblique Draw / Random Stimulus。
- 既存のものを変形 → SCAMPER。
- アイデア大量 → Brainwriting 6-3-5。
- 組み合わせ構造 → Morphological Analysis。
- 矛盾解消 → TRIZ。
- 視点整理 → Six Thinking Hats。
- 失敗要因前倒し → Pre-mortem / Reverse Brainstorming。
- 不確実性の低減 → Assumption Mapping。
- 進捗 + 可視性 → CPS Cycle。

## Technique library (index; use 1–3)
- Inversion — `references/inversion.md`
- Analogy Transfer — `references/analogy-transfer.md`
- Constraint Extremes — `references/constraint-extremes.md`
- First Principles — `references/first-principles.md`
- CPS Cycle (Clarify → Ideate → Develop → Implement) — `references/cps-cycle.md`
- Brainstorming — `references/brainstorming.md`
- Brainwriting 6-3-5 — `references/brainwriting-6-3-5.md`
- SCAMPER — `references/scamper.md`
- Six Thinking Hats — `references/six-thinking-hats.md`
- TRIZ — `references/triz.md`
- Morphological Analysis — `references/morphological-analysis.md`
- Synectics — `references/synectics.md`
- Provocation (PO) — `references/provocation-po.md`
- Random Stimulus — `references/random-stimulus.md`
- Forced Connections — `references/forced-connections.md`
- Reverse Brainstorming — `references/reverse-brainstorming.md`
- Pre-mortem — `references/pre-mortem.md`
- Mind Mapping — `references/mind-mapping.md`
- Affinity Diagramming — `references/affinity-diagramming.md`
- How Might We — `references/how-might-we.md`
- Crazy 8s — `references/crazy-8s.md`
- Storyboarding — `references/storyboarding.md`
- Lotus Blossom — `references/lotus-blossom.md`
- Assumption Mapping — `references/assumption-mapping.md`
- Oblique Draw — `references/oblique-draw.md`

## Templates
Decision Log:
- Stage:
- Decision:
- Rationale:
- Alternatives considered:

