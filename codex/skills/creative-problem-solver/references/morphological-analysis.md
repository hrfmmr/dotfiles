# Technique: Morphological Analysis (explore combinations)

## One-liner
解空間を「軸 × 値」で定義し、見落としていたハイブリッドを体系的に列挙する。

## Use when
- 交換可能な部品を持つアーキテクチャ/製品/プロセスを設計している。
- 最適解が既知部品の組合せだと見込まれる。
- 単変数の議論ばかりで、全体空間を見れていない。

## Avoid when
- 問題が単一矛盾（TRIZ）。
- 設定探索より概念ジャンプが必要（Synectics / Provocation）。

## Inputs
- 設計対象のシステム境界。
- 独立性の高い軸4〜8個。

## Procedure (fast, 10–15 min)
1. 軸を4〜6個列挙する。
2. 各軸に妥当値を3〜6個列挙する。
3. 全列挙はせず、賢く10〜20組合せをサンプルする。
4. 制約で枝刈りし、3組を選んで実験へ書き換える。

## Procedure (full, 25–45 min)
1. 軸を定義する（直交性重視）。
   - 「この軸を変えると他軸を必ず変えるか？」を問う。必ず変わるなら独立軸ではない。
   - 例: interface, storage, coordination, rollout, ownership, incentives。
2. 値を埋める。
   - 無難な標準値 + 各軸1つの極端値を入れる。
3. 組合せを生成する。
   - まずベースライン。
   - 次に1軸ずつ変更、次に2軸同時変更。
   - さらに2〜3個の wild 組合せを追加。
4. 制約で枝刈り。
   - hard制約違反を除外する。
   - 残りを「実行可能フロンティア」として把握する。
5. 収束する。
   - 3組選ぶ: 最短出荷、最安全運用、最大レバレッジ。

## Prompt bank (copy/paste)
- 「ここで本当に独立して変えられる軸は何か？」
- 「この軸の極端な反対値は何か？」
- 「“無難 + 1軸だけ尖らせる”ならどの組合せか？」
- 「制約違反が最も早く分かる組合せはどれか？」

## Outputs (feed CPS portfolio)
- 設計空間マップ（軸 + 値）。
- ハイブリッド候補の短い一覧。

## Aha targets
- 見ていなかった軸（ownership、rollout、incentives など）に気づく。
- 「安全軸」と「速度軸」を混ぜた優位ハイブリッドを発見する。

## Pitfalls & defusals
- Pitfall: 軸が重複する → Defusal: 直交化できるまで統合/再定義する。
- Pitfall: 組合せ爆発 → Defusal: サンプル列挙 + 強い枝刈りを行う。
- Pitfall: 値が抽象的すぎる → Defusal: 具体選択へ落とす（SQL vs KV、手動 vs 自動）。

## Examples
### Engineering
Design: 社内feature-flag基盤。
Dimensions:
- Storage: SQL / KV / hosted。
- Evaluation: server-side / client-side。
- Rollout: canary / percentage / cohort。
- Control: UI / config-file / API。
- Safety: audit logs / approvals / none。
列挙後に MVP として「KV + server-side + percentage + API + audit logs」を選択。
Signal: 採用率 + 障害率。

### Mixed domain
Design: 個人学習ルーチン。
Dimensions:
- Time: 10m / 30m / 60m。
- Format: reading / exercises / teaching。
- Cadence: daily / 3×week / weekly。
- Accountability: solo / buddy / public。
可逆MVP: 「30m exercises を週3回、buddy check-in付き」。
Signal: 継続率。
Escape hatch: 継続低下時に時間短縮。
