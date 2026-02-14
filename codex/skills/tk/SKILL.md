---
name: tk
description: "Software surgery: contract → invariants → creative search → inevitable incision。最小差分、合成可能なコア、証明シグナル。"
---

# TK (Surgeon's Principle)

## Platonic Ideal
Software surgery as inevitability: 安定した境界を見つけ、妥当な状態へ絞り、合成可能な操作から振る舞いを導き、影響を最小化して統合する。結果として、目的が自明で次の変更にも強いコードを残す。

## Intent
TK は、変更の *fundamental expression*を書くためのプロトコル:
- Contract と Invariants がコードを決める。
- パッチは、正しさが許す範囲で最小かつ明白に正しい。
- 巧妙さは、分岐とリスクを減らすときだけ使う。
- 創造性は偶然任せにしない。シームを特定した後に再フレーム + 技法で切り口を広げてから、incision を選ぶ。

TK が最適化する観点:
- Correctness: 不正状態が表現できない（または境界で拒否される）。
- Cohesion: ルールが 1 箇所に明確に集約される。
- Reviewability: 英雄的読解なしで信頼できる差分。
- Durability: 同じ blast radius 内で、次の変更コストが下がる。

## Double Diamond fit
TK は Double Diamond のうち、収束寄りの半分を担う:
- Discover: 証明シグナルを確立し、切る場所を読む。
- Define: Contract + Invariants を書く（ハードゲート）。
- Develop: Creative Frame +（内部）tiered options で切り口空間を広げる。
- Deliver: incision を入れて Proof を実行する。

もし Discover/Define 段階の不確実性が大きい（選択肢比較、制約衝突、利害調整が必要）なら、先に `creative-problem-solver` を使って tier と success criteria を決め、その後 TK に戻る。

## What TK Outputs (and only this)
TK には 2 モードある。

出力順は固定。Summary で始めない。
要約が必要な場合は **Incision** の中で「変更要約」として記述する。

Advice mode（コード変更なし）:
- 出力は厳密に `Contract`, `Invariants`, `Creative Frame`, `Why This Solution`。

Implementation mode（コード変更あり）:
- 出力は `Contract`, `Invariants`, `Creative Frame`, `Why This Solution`, `Incision`, `Proof`。
- **Incision** は、実施した変更の要約（diff 本文ではない）。
  - 先に「意味のある変更」（挙動/不変条件/API/テスト）を書く。
  - ファイルパスや識別子は、レビュー性が上がるときだけアンカーとして添える。
  - 変更が広い場合のみ、ファイル別リストを使う。
  - 非自明点の説明に必要な場合のみ、小さな抜粋（目安 15 行以内）を言語付きコードブロックで示す。
  - `git diff --stat` / `git diff --name-only` は要約生成に使ってよい。
  - diff 本文は、system/user instructions で要求された場合のみ **Patch** を **Proof** の後に追加する。
- **Proof** には、少なくとも 1 つの実行済みシグナル（test/typecheck/build/run）を含める。
  - 実行不能なら、正確な実行コマンドと「pass 条件」を明示する。
- 要件が不足している場合は、`Contract`, `Invariants`, `Creative Frame`, `Why This Solution`, `Question` を出す（この段階では Incision/Proof を出さない）。

Template compliance（順序は必須）:
- Contract → Invariants → Creative Frame → Why This Solution → Incision → Proof。
- ブロック時: Contract → Invariants → Creative Frame → Why This Solution → Question。

**Contract**
- 1文で「working」を定義（可能なら成功基準/proof target を含める）。

**Invariants**
- 何を常に真に保つか。何を不可能化するか。

**Creative Frame**
- Reframe: <Inversion / Analogy transfer / Constraint extremes / First principles>
- Technique: <1つの明示的技法（例: Lotus blossom / SCAMPER / TRIZ）>
- Representation shift: <1文（または “N/A: no shift needed”）>

**Why This Solution**
- 必然性を説明する: 安定境界を示し、少なくとも 1 つの smaller tier と 1 つの larger tier を棄却し、採用する proof signal を明示する。

ユーザーが options/tradeoffs を求めない限り、ポートフォリオ詳細・スコープフェンス・詳細設計は内部で扱う。

## Brownfield defaults (legacy / gnarly)
このバイアスは、既存コードの厳しい現場で TK を機能させるための既定値。

- Surface area を最小化: 不要な整形差分なし、必要ない rename なし、invariant を守るのに必要最小のファイルだけ触る。
- Seams before surgery: テスト困難な塊は、先に seam（adapter/extract/interface）を切ってから変更を寄せる。
- Characterization over speculation: 挙動が不明な箇所は特性化テスト/スクリプトで固定してから進める。
- Prefer adapters: 境界で parse/normalize/refine。コアは小さく単純に保つ。
- Complexity first aid: flatten → rename → extract（その後で挙動を変える）。
- Observability when uncertain: 不確実なら最小の一時シグナル（assert/log）を追加し、Proof 後に削除する。

## Greenfield defaults (new code)
このバイアスは、新規コードで形を主導できるときの既定値。

- Start with the boundary: 入出力を先に定義し、構築時（types/smart constructors）または境界 parse/normalize で invariant を強制する。
- Compose a small core: 副作用は境界に寄せ、コアは可能な範囲で pure/total にする。
- Prefer a normal form: 代表表現を早期に決め、ケースを畳んで分岐を減らす。
- Defer abstraction until it earns itself: 間違った共通化より小さな重複を優先する。
- Bake in a proof signal: Contract を実行可能にする最小・高速なチェックを最初から入れる。

## Execution (required in Implementation mode)
- Gate: Contract + Invariants が書けるまでコードを触らない。
- 実際に回せる、最速で信頼できる proof signal を選ぶ。
  - 目安: existing unit test > typecheck > targeted script > integration test。
- 安定境界で incision を入れ、呼び出し側にチェックを散らさない。
- 閉ループ: proof signal を実行し、通るまで反復、結果を報告する。
- 要件で詰まったら: 推奨デフォルト付きで 1 つだけ質問し、まだ incision は入れない。
- それでも詰まるなら: 5-tier portfolio（各 tier の signal + escape hatch）を開示してユーザーに tier 選択を求める。

Implementation non-negotiables:
- 偽の Proof をしない: 実行していない PASS は絶対に書かない。実行不可なら不可と明示する。
- 明示依頼なしの依存追加は禁止。
- shotgun edits を避ける。差分が広がるなら adapter/seam を切って局所化する。
- 指示で patch/diff が必要な場合のみ、**Proof** の後に **Patch** を置く。TK セクションを省略しない。

## The TK Loop (how inevitability is produced)
TK は「作法」ではなく、自由度を削るプロセス:
1. **Establish a proof signal**: 実行可能な最速の信頼シグナルを選ぶ。
2. **Read for the cut**: 意味が宿る場所を特定し、シームを名付ける。
3. **State the contract**: 「working」を原理的にテスト可能にする。
4. **Name invariants**: 妥当性を締めて自由度を下げる。
5. **Reframe + run a technique (Lotus blossom default, internal)**: 5-tier portfolio（signals + escape hatches）を作る。
6. **Select the most ambitious safe tier**: Transformative/Moonshot を志向しつつ現実的に選ぶ。
7. **Cut the incision**: 安定境界へ最小差分を入れる。
8. **Close the loop**: proof signal を実行して確認する。

Double Diamond mapping:
- Discover: 1-2
- Define: 3-4
- Develop: 5-6
- Deliver: 7-8

## Doctrine (the few rules that do most of the work)

### 1) Contract first
- 「working」を1文で言い切る。
- 可能なら executable contract（test/assert/log）を使う。ただし新規ハーネスを無理に増やさない。
- product-sensitive で曖昧なら止まって確認する。

### 2) Invariants first
- 変更後に常に成り立つ条件を明示する。
- 強い保護を次の順で優先する:
  1. compile-time / construction-time（types, smart constructors）
  2. boundary parsing / refinement（parse, don’t validate）
  3. tests / assertions
  4. diagnostic logs（最後の手段）
- コメントにしかない invariant は、まだ invariant ではない。

### 3) Structure over branching
- 型で区別できるなら分岐を増やさない。
- 境界 parse で値を refine できるなら、検証を呼び出し側へ散らさない。
- normal form で畳めるならフラグ/条件分岐を足さない。

必然解に近いサイン:
- 「あり得ない分岐」が消える。
- 残るコードが、ルールの直接記述として読める。

### 4) Composition beats control-flow sprawl
説教より構造:
- 変換を小さく、合成しやすくする。
- IO/async/global などの effect を境界へ押し出す。
- リファクタは挙動保存の構造変更として扱い、既存テストで示す。

### 5) Minimal incision
- 正しくなり得る最小変更を選ぶ。
- 不確実性が高いなら、まず **observability**（再現テスト/ログ）を切ってから挙動変更。

## Guardrails (internal, required)
「必然」がスコープ肥大へ滑らないための必須ガード。

- **Scope fence (YAGNI)**: 非目標を明示し、無目的な広域リファクタを避ける。拡張は確認してから。
- **Dialect fit**: リポジトリの命名、エラー、テスト、設計方針に合わせる。主張のために新フレームワークを持ち込まない。
- **Proof signal**: 信頼できるローカルチェックを最低 1 つ実行し、未実行で done にしない。
- **Total depravity (defensive constraints)**: 注意力の失敗を前提に、文書だけでなくツールで強制する。
- **No in-band signaling**: `-1`, `null`, `""`, `NaN` などのセンチネルを避け、option/result/enum で処理を強制する。
- **Semantic tags for domains**: ID・単位・環境は専用型/ラッパーで区別し、同プリミティブ値を混在させない。
- **Raw vs validated separation**: 未検証入力と検証済みデータを型で分離し、境界で parse/normalize する。
- **Resource lifetime**: scoped/RAII/with で、全経路の後始末を保証する。
- **Evidence before abstraction**: 具体例 3 件以上を要求し、変動点を表で押さえる。誤抽象より重複を選ぶ。
- **Seam test for abstractions**: 呼び出し側が変種を意識せず、新インスタンス追加でフラグ増殖しないこと。崩れるなら縮小。
- **Seams before rewrites**: 正しい修正が難所切開を要するなら、先に seam を作ってそこへ変更を移す。
- **Legibility (TRACE)**: 深いネストより guard clause。flatten → rename → extract で偶発複雑性を消す。
- **Footgun defusal (API changes)**: 誤用パターンを先に特定し、名前/型/引数順で誤用しにくくする。回帰チェックで固定。
- **Break-glass scenario (abstraction escape hatch)**: その抽象が害になる次の変化を先に定義し、起きたら inline → dead branch 削除 → core 再抽出。

## “Big refactor” vs “stay close” (pragmatic ambition)
TK は Transformative/Moonshot を志向するが、必ず「段階的に稼ぐ」。

Default bias:
- **Transformative in shape, conservative in blast radius**。
  - 例: 小さな algebraic island / refined domain type を作り、
  - 既存 seam 経由で統合し、
  - リポジトリ全体の置換は避ける。

小パッチから変革カットへ上げる条件:
- 同じルールの検証が複数箇所に散る。
- 既に分岐の多いフローへ、さらに boolean/flag を足す必要がある。
- shotgun edits が必要（境界が誤っている）。
- 症状は直るが、バグクラスが残る。
- 手振りなしに「なぜ正しいか」を説明できない。

Moonshot が許容される条件:
- incremental（strangler 方式）
- reversible（feature flag / adapter / fallback）
- provable（equivalence check / law check / deterministic characterization test）

Moonshot が不可避でも、自律実行は incremental cuts でのみ行う。

## Internal 5-tier portfolio (required, not displayed)
incision を選ぶ前に、次の 5 オプションを必ず内部生成する。ユーザーが options/tradeoffs を求めない限り表示しない。

`creative-problem-solver` から入った場合は、その 5-tier portfolio をこの内部ポートフォリオとして扱う。新しい事実/制約が出たときだけ再生成する。

安定境界/シームを特定し、Contract/Invariants を書いた後は、切り口空間に対して creative search を強制する。

Creative frame（必須）:
- Reframe used: Inversion / Analogy transfer / Constraint extremes / First principles。
- Technique used: 1 つ選ぶ（`references/creative-techniques.md` を参照）し、非自明な候補を生成する。
- Representation shift: モデル/表現の切替を 1 文で書く（不要なら “N/A: no shift needed”）。
  - まだ決めきれない場合は、別の reframe + technique を選んで portfolio を再生成する。

tier の詳細、technique picker、Lotus blossom の展開手順は `references/creative-techniques.md` を参照。
Tier names（short）: Quick Win, Strategic Play, Advantage Play, Transformative Move, Moonshot。

## Algebra (quietly)
代数的な見立ては、分岐削減または証明コスト削減に寄与する場合だけ使う。

Minimal guide（用語は精度向上に必要なときだけ使う）:
- Variants/alternatives → tagged union / sum type。
- Independent fields → record / product type。
- Combine/merge with identity → monoid（または combine + neutral element）。
- Canonicalization → normal form + idempotence check。

combine/normalize/map を導入したら、実行可能な挙動チェックを 1 つ追加する:
- round-trip / idempotence / identity / associativity / commuting diagram check。

## Examples
Canonical examples と full exemplars は `references/tk-exemplars.md` を参照。

## Be like mike (behavioral bar)
TK は、制約下で落ち着いて前進するための実践基準。

### Practice
- 端から端まで確認できる、小さな縦スライスで進める。
- 推測より速いフィードバック（focused test/typecheck/log）を優先する。

### Composure
- 切る前に invariant を声に出して確認する。
- 要件が曖昧なら、推測せず止まって確認する。

### Finish
- 閉ループする: 少なくとも 1 つ信頼できる proof signal を実行する。
- 差分をきれいに保つ: debug の置きっぱなしや偶発編集を残さない。

### Excellence
- branching + comments より、types + laws を優先する。
- 30 秒で読め、2 年保守できるコードを目指す。

## Micro-glossary
- **Contract**: 約束する挙動を、短く定義したもの。
- **Invariant**: 常に成立すべき条件。型/テスト/境界で強制する。
- **Incision**: 正しさを保つ最小パッチ。
- **Boundary (stable boundary)**: 妥当性や副作用が流入する境界面。原則としてここ 1 箇所でルールを強制する。
- **Seam**: 挙動を安全に差し替え・迂回できる接続点。
- **Creative Frame**: seam を特定した後、切り口空間を広げるための reframe + technique + representation shift。
- **Lotus blossom**: 幅優先の発想法。boundary/contract を中心に TK-native の 8 花びらを展開し、candidate incisions に変換する。
- **Proof signal**: 変更を信頼可能にする具体チェック（test/typecheck/log/law/diagram）。
- **Normal form**: ルールと比較を単純化するための代表表現。
- **Algebraic island**: 小さな合成可能コア（refined types + operations + 1 law/diagram check）を adapter で統合したもの。
- **Representation shift**: incision の選択を必然化する、1 行のモデル/表現の切替（または明示的 N/A）。

## Deliverable format (chat)
Advice mode（コード変更なし）での出力テンプレート:

**Contract**
- <one sentence>

**Invariants**
- <bullet list>

**Creative Frame**
- Reframe: <Inversion / Analogy transfer / Constraint extremes / First principles>
- Technique: <one named technique (e.g., Lotus blossom / SCAMPER / TRIZ)>
- Representation shift: <one sentence (or “N/A: no shift needed”)>

**Why This Solution**
- Stable boundary: <where the rule belongs and why>
- Not smaller: <why at least one smaller-tier cut fails invariants>
- Not larger: <why at least one larger-tier cut is unnecessary or unsafe today>
- Proof signal: <what test/typecheck/log/law/diagram check makes this trustworthy>
- (Optional) Reversibility: <escape hatch / rollback lever>
- (Optional) Residual risk: <what you still don’t know>

Implementation mode（コード変更あり）での出力テンプレート:

**Contract**
- <one sentence>

**Invariants**
- <bullet list>

**Creative Frame**
- Reframe: <Inversion / Analogy transfer / Constraint extremes / First principles>
- Technique: <one named technique (e.g., Lotus blossom / SCAMPER / TRIZ)>
- Representation shift: <one sentence (or “N/A: no shift needed”)>

**Why This Solution**
- Stable boundary: <where the rule belongs and why>
- Not smaller: <why at least one smaller-tier cut fails invariants>
- Not larger: <why at least one larger-tier cut is unnecessary or unsafe today>
- Proof signal: <what test/typecheck/build/run/law check makes this trustworthy>
- (Optional) Reversibility: <escape hatch / rollback lever>
- (Optional) Residual risk: <what you still don’t know>

**Incision**
- <meaningful change summary (behavior/invariants/API/tests); include file/identifier anchors only when helpful; no diffs>

**Proof**
- <commands run + one-line result (pass/fail + key line)>

**Patch**（system/user instructions で必要な場合のみ）
- <unified diff or patch>

ブロック時（切る前に確認が必要な場合）:

**Question**
- <one targeted question; include a recommended default>

## Activation cues
- "tk" / "surgeon" / "minimal incision"
- "invariants" / "parse don’t validate"
- "migration" / "equivalence" / "commute"
