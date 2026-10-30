# Human-facing report format

How the Mayor writes every reply to the human. `todo` and `status` use the full layout
with one box diagram per focus issue; every other reply (a relay report, a background
event, an answer) uses the same prose rules and the same closing block, without
diagrams. The human reads these replies instead of the ledger, so each one must let
them act without rereading another conversation.

## Prose: reader-first by default

Load the `reader-first` skill before writing a `todo` or `status` reply, and follow its
rules in every reply. The points that matter most here:

- Open with the answer in one to three sentences: what changed, and what the human
  should do first.
- Write sentences with a subject and a verb. Expand every issue ID, key, PR number and
  abbreviation into what it is at its first use; the key may follow in backticks.
- For each item, say what it is, why it matters (what it unblocks), what is confirmed
  and from which source, what is unconfirmed, the exact action, and where.
- Where an item waits in the Plannotator Inbox, the place is the Inbox, written as
  `Inbox「<project folder name>」›「<thread name>」` (for example
  `Inbox「u31.12--予備試験環境の構築」›「u31.12: PR 205 のレビュー」`). The human answers
  there and the answer goes straight to the commander, so do not send them to the pane.
- Never leave a bare label such as `あなたの判断` or `<issue>: 待ち`. Name the decision
  and its options, or the action and its place.
- Keep facts, numbers, conditions and uncertainty from the commander's report; mark the
  Mayor's own interpretation as such.

## `todo` and `status` layout

1. **結論**: how many items are the human's turn, and which one to do first.
2. **急ぎ**: urgent items, if any, in the item form below.
3. **One section per presented issue** (focus only; pend too with `--all`), ordered by
   whose turn it is (the human's turn first). An issue with no open items, or whose
   open items block no agent and no next step (reads only, a push, a commander that is
   gone), gets one line in a list after the sections and no diagram; that line still
   names the actions. Each full section has:
   - heading: `**<issue> <short title in words>** — <workspace label>:<agent name>`;
   - the box diagram (below) in a `text` code fence;
   - prose: whose turn it is now, what to do, why, and where; then the issue's other
     open items (reviews that block nothing) as a short list;
   - `status` only: one line on the commander's state (working, idle since HH:MM,
     question open on screen) and anything stale.
4. **issue をまたぐ依存**: one line per focus step that waits on another issue.
5. **保留**: one line with the pend count.
6. **status only**: how notices reach the Mayor (Protocol 3, both the file inbox and the
   Plannotator Inbox), in plain words.
7. The closing block.

## Box diagram (`todo` and `status` only)

The diagram shows where the issue stands and who holds the next step. It supplements
the prose; every fact in it also appears in the text.

- Shape: a single top-down chain of three to five boxes:
  `済: <last finished step>` → `いま <誰>の番` → `次 <誰>: <step>` → optional `その次`.
  In the `いま` box, write each action as a numbered line and a short place on the next
  line (`Inbox: <thread name>`, `<agent name> の pane`, a page title, or a PR number).
  Workspace labels are often too long for the 100-column limit and may hold parentheses,
  so the full `<workspace label>:<agent name>` goes in the prose under the diagram, not
  in the box.
- Ball holders: `あなた`, `担当` (the commander), or `外の人` (named, e.g. a reviewer).
- Several actions in the same step, even with different owners: put them as numbered
  lines inside one box, prefixing the owner when it differs. Do not draw two parents
  into one box or an edge that skips a level: the layout does not de-cross edges, and
  even a minimal merge renders with stray jogs.
- Write a mermaid `flowchart TD` to the scratchpad and render it with the hunk-present
  script, plain spaces for a terminal code fence:

  ```bash
  python3 ~/.claude/skills/hunk-present/scripts/mermaid_to_boxart.py --pad space map.mmd
  ```

  Stdout is the art only (the width line goes to stderr). Quote every label, use `<br>`
  for line breaks, and keep parentheses and `→` out of labels. Paste the output into a
  ```` ```text ```` fence unchanged; do not retype or realign it.
- Read the printed art once. If lines cross or an arrow points at nothing, fold the
  branches into numbered lines and render again.

Example (rendered by the script):

```text
    ┌───────────────────┐
    │ 済: 段階 1 の観察 │
    └───────────────────┘
              │
              ▼
┌──────────────────────────┐
│     いま あなたの番      │
│     1. 質問に答える      │
│   flowlog-cmd の pane    │
│ 2. 読み取り 6 項目を行う │
│     sec-cmd の pane      │
└──────────────────────────┘
              │
              ▼
┌───────────────────────────┐
│ 次 担当: 段階 2a を始める │
└───────────────────────────┘
```

## Closing block (every reply)

End every reply with this block, after the main content and before the user's response
appendix. Group the waiting items by whose turn it is, the human's turn first.

```
**現在位置と次の動き**
- 現在位置: <今回読んだ担当の報告と、台帳で変えたこと。例: 報告 3 件を読み、0hd の merge を済みに移した>
- Mayor の次の動き: <裏で見張っているものと期限。無ければ「次に呼ばれたときに担当の報告を読む」>

**待っていること**
■ あなたの番 (<n> 件)
  1. <issue の名前>: <操作、または判断の内容と選択肢 (推奨)>
     なぜ: <目的、または何が止まっているか>
     確かさ: <確認済み (出典) / 未確認 (理由)>
     解けると: <誰が何を進められるか>
     どこで: Inbox「<project>」›「<スレッド>」、<workspace label>:<agent name>、ページ、または絶対パス
■ 担当の番 (<n> 件)
  - <issue の名前>: <agent> が <作業中の作業、または頼まれた報告のし直し>。終わると <次に起きること>
■ 外の人の返事待ち (<n> 件)
  - <issue の名前>: <誰> の <何>
```

- Describe the current position by what the Mayor read and changed, not by internal
  cursors or line numbers of the inbox.
- In `todo` and `status`, the issue sections carry the detail, so the closing block
  lists every presented item as one line (the action and the place), grouped by whose
  turn it is, without repeating the なぜ / 確かさ / 解けると lines.
- In other replies, write in full only the items that are new or changed this turn.
  Give each other issue one concrete line that still names its actions (for example
  `0hd: hunk のレビュー 2 件と、次の作業 (閾値の較正など) の指示。todo で詳しく出します`),
  never a bare `あなたの判断`.
- Omit a group that has no items. Pend items stay out unless `--all` was asked.
