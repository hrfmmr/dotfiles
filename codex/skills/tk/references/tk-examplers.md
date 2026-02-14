# TK Examples

## 代表例（リポジトリ方言に翻訳して使う）

### Example A: Parse, don’t validate
- Contract: 不正入力は境界で拒否し、コア側では再検証しない。
- Invariant: 下流コードには、精製済みの値だけが渡る。
- Incision: 精製値を返す parser / smart constructor（`()`ではなく値を返す）を追加し、コアはその精製型を受けるようにする。
- Why inevitable: 型で不正状態を表現できなくなると、「本来あり得ない経路」が消え、規則が1か所に集約される。

### Example C: Commuting migration diagram
- Contract: 旧挙動と新挙動は、サポート対象入力で一致する（差分があるなら明示的に定義される）。
- Invariant: adapter は意味を保存する。
- Incision: `toNew` / `fromNew` adapter を導入して、2つの経路を可換にする:
  - 代表入力に対して `old(x)` は `fromNew(new(toNew(x)))` と等しい。
- Why inevitable: 局所・実行可能・レビュー可能な証明シグナルを保ったまま、段階的な置換ができる。

## Exemplars（合成例）
形を真似し、リポジトリ方言（エラー、テスト、パス、命名）へ置き換えて使う。
以下は期待される Incision summary 形式（diffは含めない）。

### Exemplar 1 (Brownfield): 境界でparseし、散在するvalidationを止める（TypeScript）

````text
**Contract**
- `/signup` は不正メールを拒否し、正規化済みメールをサービスへ渡す。

**Invariants**
- `parseEmail` は、このフローでメール妥当性を判定する唯一の場所。
- 下流コードは、trim + lowercase 済みメールだけを扱う（再validationしない）。
- 不正メールは `userService.createUser` に到達しない。

**Creative Frame**
- Reframe: First principles
- Technique: Lotus blossom
- Representation shift: 境界でメールを `string` ではなく精製型 `Email` に置き換える。

**Why This Solution**
- Stable boundary: `src/routes/signup.ts` は信頼できない入力が入る場所。
- Not smaller: その場しのぎの `if (...)` 追加では検証が散らばり不整合が残る。
- Not larger: リポジトリ全体でメールを branded type 化するのは大改修。ここでは局所で切る。
- Proof signal: `parseEmail` のunit test + 既存signup handler test。

**Incision**
- 精製メール境界（`parseEmail`）を導入し、正規化（trim/lowercase）と不正形式拒否を行う。
- signup の検証を境界へ移し、下流は精製/正規化済みメールのみ扱う（インライン検証を削除）。
- 正規化と拒否のunit coverageを追加。

**Proof**
- Ran: `pnpm test src/domain/Email.test.ts` -> PASS
- Ran: `pnpm test` -> PASS
````

### Exemplar 2 (Brownfield): seam（Clock）を追加し、flakyなsleepを削除（Go）

````text
**Contract**
- 更新ロジックは注入された clock を使う。production挙動は不変で、テストは決定的になる。

**Invariants**
- すべての時刻比較は `Clock.Now()` を使う（コアで `time.Now()` を直接呼ばない）。
- productionのデフォルトは system time。
- テストでは sleep なしで時刻固定できる。

**Creative Frame**
- Reframe: Inversion
- Technique: SCAMPER
- Representation shift: 暗黙グローバル時刻を、明示的依存へ置き換える。

**Why This Solution**
- Stable boundary: 時刻は副作用であり、`Clock` seam で隔離できる。
- Not smaller: sleep/retry 追加は遅く、なお flaky。
- Not larger: scheduler/state-machine への全面改修は、決定性確保には過剰。
- Proof signal: `go test ./...`（sleepなし）。

**Incision**
- `Clock` seam と既定 `SystemClock` を追加し、production挙動を維持。
- 更新コアへ clock を注入し、`time.Now()` 直接呼び出しを削除して時刻依存を明示化。
- テストは `fakeClock` で決定的にする（sleep不要）。

**Proof**
- Ran: `go test ./...` -> PASS
````

### Exemplar 3 (Greenfield): 正規形を選び、冪等性を証明する（TypeScript）

````text
**Contract**
- `normalizeTags` はタグを正規形（trim、lowercase、重複排除、ソート）で返す。

**Invariants**
- 出力に空文字は含まれない。
- 出力はソート済み・一意・lowercase。
- 冪等性: `normalizeTags(normalizeTags(x))` は `normalizeTags(x)` と等しい。

**Creative Frame**
- Reframe: Constraint extremes
- Technique: Morphological analysis
- Representation shift: タグを「呼び出し側任せの列」ではなく、正規化済みcanonical listとして扱う。

**Why This Solution**
- Stable boundary: 境界は constructor / normalizer。下流は不変条件を前提にできる。
- Not smaller: 呼び出し側へ `trim()/toLowerCase()` を散布すると必ずドリフトする。
- Not larger: 3種類以上の操作が必要になるまでは、専用class + fluent API は儀式過多。
- Proof signal: 冪等性unit test + 代表例テスト。

**Incision**
- `normalizeTags` を唯一の正規化器として追加（trim/lowercase、空削除、重複排除、ソート）。
- 絞ったunit testで冪等性を証明。

**Proof**
- Ran: `pnpm test src/domain/TagSet.test.ts` -> PASS
````

### Exemplar 4 (Blocked): 質問は1つだけ。推奨デフォルトを添える

````text
**Contract**
- 請求書合計は、顧客の期待に合う形でセント単位に丸める。

**Invariants**
- 丸めは1か所で行う（呼び出し側ごとの丸めは禁止）。
- 合計値はサービス間・プラットフォーム間で決定的。

**Creative Frame**
- Reframe: First principles
- Technique: TRIZ
- Representation shift: 金額を端から端まで整数セントで扱い、丸めは parse/境界だけで決める。

**Why This Solution**
- Stable boundary: 丸め規則は money parser/constructor に置くべき。
- Not smaller: 1つの呼び出し側だけ修正しても、バグの種類は温存される。
- Not larger: 丸め仕様の合意前に、全面的なmoneyライブラリ移行は過剰。
- Proof signal: 実請求書を使った特性テスト（0.5セント境界を含む）。

**Question**
- ちょうど中間値（例: 1.005）は、half-up（推奨デフォルト）と half-even（banker's rounding）のどちらにするか？
````

### Exemplar 5 (Migration): 同一APIの裏で可換置換を進める（TypeScript）

````text
**Contract**
- `normalizePhone` は、精製 `PhoneNumber` コアを導入しつつ、legacy挙動を維持する。

**Invariants**
- 呼び出し側は引き続き `normalizePhone(raw: string): string` を呼ぶ。
- 新コアは、妥当性 + 正規化を1つの parser（`parsePhoneNumber`）で担う。
- 移行の係留条件: 代表入力で `normalizePhone(raw)` は `legacyNormalizePhone(raw)` と等しい。

**Creative Frame**
- Reframe: Analogy transfer
- Technique: TRIZ
- Representation shift: 旧APIは安定維持し、adapter可換で移行する。

**Why This Solution**
- Stable boundary: `normalizePhone` は既存呼び出し側がすでに共有する境界。
- Not smaller: 一部呼び出し側の修正ではドリフトが止まらない。規則を境界へ集約すべき。
- Not larger: 全呼び出し側を新型へ置換するのはリポジトリ規模の改修。
- Proof signal: 移行同値テスト + 既存unit test。

**Incision**
- 精製 `PhoneNumber` コアを導入し、妥当性 + 正規化を1 parser（`parsePhoneNumber`）へ集約。
- 公開APIは維持しつつ、`normalizePhone(raw)` を新コア経由で再実装。legacy挙動は `legacyNormalizePhone` として保持。
- 移行係留の同値テストを追加（`normalizePhone(raw) === legacyNormalizePhone(raw)`）。

**Proof**
- Ran: `pnpm test src/legacy/normalizePhone.migration.test.ts` -> PASS
````

