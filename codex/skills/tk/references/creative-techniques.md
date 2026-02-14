# Creative Techniques (TK)

## テクニック選択ガイド（デフォルト: Lotus blossom）
- 境界面をまたいで幅広く案を出したい（サブ問題 → 選択肢）: Lotus blossom。
- 既存アプローチを変形したい: SCAMPER。
- とにかく短時間で大量の案がほしい: Brainwriting 6-3-5（1人でも可）。
- 組み合わせを構造的に探索したい: Morphological analysis。
- 矛盾を解消したい: TRIZ。
- 視点を並行的に切り替えたい: Six Thinking Hats。
- 失敗に強い案へ鍛えたい: Reverse brainstorming。
- 行き詰まりを崩す刺激がほしい: Random stimulus または provocation。

## テクニック一覧（短縮版）
- Lotus blossom: コア課題から外側へ展開し、TK向けの8つの「花びら」を作ってさらに展開。探索の幅を強制し、ポートフォリオを埋める。
- SCAMPER: Substitute / Combine / Adapt / Modify / Put to use / Eliminate / Reverse。
- Brainwriting 6-3-5: 時間区切りのラウンドで、静かに生成と改良を進める。
- Morphological analysis: 複数軸の組み合わせを列挙する。
- TRIZ: 矛盾を明文化し、分離原理で抜け道を作る。
- Six Thinking Hats: 事実 → 感情 → リスク → 利点 → アイデア → 進行、の順で考える。
- Reverse brainstorming: 「どう悪化させるか？」を先に出し、そこから反転する。
- Random stimulus / provocation: 無関係な刺激から具体レバーを引き出す。

## Lotus blossom（TKでの使い方）
- Center: 安定した境界 + 契約を1行で定義。
- Petals: TKで効く8つのレバー/サブ問題を置く。
  - 安定境界 / seam（副作用と強制を境界へ押し出す）
  - 不変条件の強化（型/parse/テスト）
  - 表現 / 正規形（ケースを畳み、分岐を削る）
  - 証明シグナル（高速チェック: テスト/型検査/ログ、法則チェック、可換図式）
  - 可逆性レバー（rollback、flag、adapter、fallback）
  - 主要失敗モード（クラッシュ / 破損 / ロジック不整合）
  - 呼び出し側の使いやすさ / footgun（誤用しにくくする）
  - 影響半径 / 統合面（変更がどれだけ広がるか）
- Expansion: 各花びらを具体的な incision 候補に展開。候補を5 tierへ配置し、もっとも「証明しやすい」tierを選ぶ。

## Tierと選定
各tierには次を付ける:
- 期待する証明シグナル: 何を実行/観測して学ぶか。
- エスケープハッチ: 間違っていた場合にどう戻すか/範囲を狭めるか。

Tiers:
- Quick Win: 最小の局所パッチ。動きが最も小さい。
- Strategic Play: 境界を明確化し、seamを足し、テスト可能性を上げる。
- Advantage Play: 局所的な型/正規形の改善で分岐を減らす。
- Transformative Move: 小さな代数的アイランド、合成中心のコア、境界側にadapter。
- Moonshot: アーキテクチャ境界の変更。ただし段階的かつ可逆で行う。

Selection rule:
- レビュー可能・段階的・証明可能を保てる範囲で、最も高いtierを選ぶ。
- 迷ったら、Learning value と Reversibility を最大化し、blast radius を最小化する。

