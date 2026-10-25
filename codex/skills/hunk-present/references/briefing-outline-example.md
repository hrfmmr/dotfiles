# Briefing outline — worked example

One real briefing note rewritten from a paragraph into a claim plus a nested outline (rules: `SKILL.md` 3a). Identifiers are generic; the content is from an EventBridge → CloudWatch Logs change. The outlines below are the author's view, indented with ordinary spaces; `--harden` turns that indent into U+2800 before launch.

## 1. Before: a paragraph

`summary`: 【ブリーフィング 3/4: いま何をどう変えるか】ロググループ・resource policy・Rule・target の 4 つを足す。

`rationale`:

> `aws/event_capture.tf` を新しく作り、(1) ロググループ、(2) そのロググループへの書き込みを EventBridge に許す resource policy、(3) partner bus 上の全イベントを受ける Rule、(4) その宛先をロググループにする target、を置きます。`aws/variables.tf` は、変数の説明文の 1 行を、S3 以降の実態に直すだけです。この commit で新しく出てくる言葉は 2 つです。① EventBridge の Logs target（IAM role ではなく、ロググループ側の resource policy で書き込みを許す。イベントの本文がそのままログメッセージになる）。② 全イベントを受けるパターン（`source` フィールドがあるものすべて）。関与度は L1（承認）です。（出典: AWS 公式 …「CloudWatch Logs groups as targets」）

Hard to read because one paragraph carries facts of five kinds (added, fixed, new terms, review level, source), an inline `(1)`–`(4)` list, and explanations hidden in parentheses. Hunk wraps it into eight rows of unbroken text `[実測]`, with nothing to scan.

## 2. After: claim plus outline

`summary` (the claim, one sentence):

```
0.) 【ブリーフィング 3/4: いま何をどう変えるか】`aws/event_capture.tf` を新規に作り、4 つの resource を足す。他は変数の説明文 1 行だけ。
```

`rationale`:

```
- 足すもの (`aws/event_capture.tf`、新規)
  - (1) ロググループ
  - (2) resource policy: EventBridge からロググループへの書き込みを許す
  - (3) Rule: partner bus 上の全イベントを受ける
  - (4) target: Rule の宛先をロググループにする
- 直すもの (`aws/variables.tf`): 変数の説明文 1 行を、S3 以降の実態に合わせる
- この commit で新しく出てくる言葉は 2 つ
  - EventBridge の Logs target
    - IAM role ではなく、ロググループ側の resource policy で書き込みを許す
    - イベントの本文が、そのままログメッセージになる
  - 全イベントを受けるパターン: `source` フィールドがあるものすべて
- 関与度: L1 (承認)
- 出典 [記録]
  - AWS 公式「CloudWatch Logs groups as targets」

図: NEW: が、この commit で足すもの
<--json で貼った図>
```

### How the paragraph was broken down

- Claim first: what the human must take away is "four new resources, one description line, nothing else". That became the headline, so the four headlines alone still tell the story (Skip test).
- Sort the sentence's parts by kind, one level-1 line each: added, fixed, new terms, review level, source.
- Move what was in parentheses into children. The two properties of the Logs target are what the human has to learn, so they sit under the term, not inside brackets (R3, R5).
- Expansion test: `(1)`–`(4)` stay as children because each is what the human will find in the diff; `(1)` stays a one-line item. The variable description gets no children, because nothing about it is a premise, a magnitude, or a failure condition.
- The source is labelled `[記録]` and sits under its own line, so the claim lines stay readable.

## 3. A second note: 読む順番と未確認

Before (a paragraph ending in an inline list):

> 読む順番は、1.) bus 名 → 2.) ロググループ → 3.) resource policy → 4.) Rule → 5.) target → 6.) 変数の説明文、です。確認したのは `terraform fmt -check` と `terraform validate`（通過）です。`plan` と `apply` は実行していません。未確認のことは 4 つです。(1) パターン `source exists` が Datadog の partner event に当たるか。(2) …

After:

```
- 読む順番
  - 1.) bus 名、2.) ロググループ、3.) resource policy
  - 4.) Rule、5.) target、6.) 変数の説明文
- 確認したこと [確認]
  - staged の内容に対する `terraform fmt -check` と `terraform validate`: 通過
- 実行していないこと: `plan` と `apply`
- 未確認 (4 つ。いずれも apply のあとに実測する) [未確認]
  - (1) パターン `source exists` が Datadog の partner event に当たるか
  - (2) Datadog が作る bus が、この Rule の作成時点で存在するか
```

The count in the parent line ("4 つ") tells the human how many children to expect, and each child is a failure condition the human can accept or reject on its own.

## 4. Mistakes this prevents

- A chain flattened into siblings: `- 保存先は A` / `- だから Rule を置く` / `- ただし policy は未確認`. Nest instead: the Rule is a child of the decision (`帰結:`), the unverified policy a child of the Rule (`ただし:`).
- A connective with no content: `- 理由` followed only by children. Write `- 理由: <the reason>` or drop the line.
- A paragraph inside a bullet, wider than 100 columns. Hunk wraps it and the continuation starts at column 0, so the nesting is lost. Move the second half into a child line.
- An outline indented with ordinary spaces and never hardened: Hunk drops the indent and the outline comes out flat. `--check` catches it.
- Arrows (`→`) standing in for logic: use `帰結:` / `理由:` instead.
