# Writing for recap

How to apply `$reader-first` to a desk task note so a cold reader — the human after days away, or a successor agent — can recap the 背景, the 現況, and the 判断ポイント from the note alone. The contract is in `SKILL.md` `### Writing for the cold reader`; this file holds the recipes and examples.

All example text below is constructed for illustration. Its numbers and names are invented; do not treat them as a real design or measurement. The Japanese examples are in ですます, as a new note would be; in an existing note written in 常体, write the same content in that note's register.

## What the cold reader must recover

| The reader asks | Where the answer lives |
|---|---|
| What is this task, and why does it exist? | 設計 > 背景 (the one-line 問題定義 sits under it) |
| How far along is it, and what waits on whom? | 現在地 状況, then 位置 / 残TODO |
| What do I have to do now? | 現在地 Next Action (human) |
| What is decided, and what is still open? | 論点 (`decided` / `open`), 現在地 未決の論点 |
| Why was it decided that way? | 論点 判断 and 根拠 |
| How sure are we? | 前提 (Facts) and 論点 根拠, with the certainty words |
| What happened to get here? | Event Log |

## Section recipes

**背景** (設計 > 背景). Three to six sentences: who is affected and what happens today, why it matters (what is at risk if nothing is done), what triggered the task, and where this task's boundary is. Explain each term at its first use. Leave design out; that is 設計方針・構成.

**状況** (the paragraph that opens 現在地). Two to five sentences, in this order: what the task is (one clause; 背景 holds the why, so point to it rather than retell it), what has been settled that matters for the next step, where it stands now and why (moving, waiting, or blocked — and on whom), and what happens next. Rewrite it in place each refresh; history goes to the Event Log.

**Index fields** (現在地 bullets).
- 位置: the milestone and what it is in words (`M3/5 本番への反映`).
- 未決の論点: the id with its topic (`D-2 上限を DB 側で上げるか、アプリ側で下げるか`).
- 残TODO: the count, then the next item as a sentence.
- Next Action (human): one nested bullet per action — what to do, where, why it is needed, and how to know it is done. A finished item leaves the list; its record is in a Turn. For a check, say which result is expected and what to do if it is not; for a decision, say what depends on it and what each choice leads to, so the human can decide without reopening the conversation.
- Next Action (agent): the same shape, plus what must not be done without approval.
- A small decision only the human can make (too small to be a 論点, such as whether to open a follow-up PR) is a Next Action (human) item, and counts in 残TODO if it blocks done. Make 残TODO and the Next Action lists agree.

**前提 (Facts)**. Group under short lead-ins such as 測って分かったこと / 資料に書かれていること / まだ確かめていないこと. Write each fact as a sentence saying what is known, how it was confirmed, and when. Move long evidence (listings, query output, per-check tables) to a derived note and keep the sentence that states the conclusion and where the evidence is. Expand every abbreviation or path the reader would not know.

**論点**. Use the template in `references/note-templates.md`. A worked `open` entry:

```markdown
#### D-2 接続数の上限を、DB 側で上げるか、アプリ側で下げるか
decision_status:: open
- 問い: ステージングの API は、負荷試験を始めると「接続数が多すぎる」というエラーで止まります。直すには、DB が受け付ける接続数の上限を上げるか、アプリが同時に開く接続の数を減らすかを決める必要があります。選び方で、DB の再起動が要るかと、同じ設定を本番へ持っていく手間が変わります。
- 選択肢:
  - A DB の上限を上げる: DB のパラメータを変えるだけで、アプリの設定は触りません。ただし反映に DB の再起動が要り、その間ステージングは使えません。DB のメモリ使用量も増えます。
  - B アプリの接続プールを小さくする: アプリ側の設定だけで済み、再起動も要りません。ただし同時に処理できる数が減るので、負荷試験の目標の同時接続数を満たせるかを確かめる必要があります。まだ確かめていません。
  - C 両方行う: 余裕は最も大きくなります。ただし変更が 2 か所に分かれ、どちらが効いたかを切り分けにくくなります。
- 判断: 未決。推奨は B です。再起動が要らず、すぐ試せて、戻すのも簡単だからです。分かっていないのは、プールを小さくしても負荷試験の目標を満たせるかです。B を試して届かなければ、A を足します。
- 根拠: 確認した範囲では、ステージングの DB の上限は 100 本です。アプリは 3 つのタスクがそれぞれ 50 本まで接続を持てる設定で、最大 150 本を要求できます (2026-10-27 に DB のパラメータとアプリの設定を読んで確認)。上限を超える設定になっていること自体が、有力な原因の候補です。実際に何本開かれているかは、負荷試験中の測定をまだ取っていないので未確認です。
- 影響先: 設計方針・構成の接続設計、Milestone M2 (設定変更と再試験)。
```

When one entry holds several decisions, state them as a numbered list in 問い and give each its own option bullets (nested one level deeper); if they can be decided independently, split them into separate entries instead. When there is a single proposal, write it as one option with its benefit and cost and say that no alternative was considered. When the note does not say why an option is better, why the question matters now, or what is still unknown, ask the human or mark it as not recorded; do not fill the gap by inference.

When the entry becomes `decided`, 判断 names the chosen option and who decided it (for example, 提案を human が承認した日付), and 根拠 keeps the reasoning plus anything learned since the recommendation.

**current_status_summary**. A headline a Dataview cell can carry.
- Before: `M6/6 完了。修正 PR (#101) は 10-26 13:45 に merge 済み。image は build して push。tag 更新 PR 3 本 (#102、#103、#104) は 16:50 に merge、5 env に deploy。monitor は OK に復帰。残りは画面の確認、#105 の merge、範囲外 3 件の判断…` (the run-on continues)
- After: `全マイルストーンの作業が完了し、修正は全環境に反映済みです。残りは、人による画面の確認と、範囲外の件の判断です。`

The per-PR times and monitor states move to the Turn that recorded them.

## Anti-patterns seen in real notes

- **A headline field that became a history.** `current_status_summary` grew past a thousand characters of PR numbers and times. Keep the headline; put the sequence in the Event Log.
- **Next Action as one numbered run-on.** Items `(1) (2) (3)…` inside one bullet, with finished items still listed. Use nested bullets, drop finished items, and give each remaining one its what / where / why / done-when.
- **Options as a slash string.** `A … / B … / C …` in one bullet leaves out each option's benefit and cost. Use one nested bullet per option.
- **A fact bullet chained with parentheses and bare ids.** Split into sentences, gloss each id, and say how each fact was confirmed.
- **根拠 as a single paragraph mixing source, number, and inference.** Separate what was confirmed, what a source states, and what is inferred, in that order, with the certainty words.
- **A plan written as chapters of ids.** Section numbers, round tags, and appendix letters that the reader has to look up before a sentence makes sense. Say what each one is where it first appears.

## Reflowing an existing section

1. Before rewriting, list what the section carries: numbers with units and dates, conditions and exceptions, certainty (確認済み / 推測 / 未確認 / 予定 / 実施済み), each id and what it refers to, and each source. Keep this list in your working notes, not in the note.
2. Rewrite using the recipes above.
3. Walk the list against the new text. Every item must appear in the head, or already be recorded in a Turn, bd, or a named derived note — search the Event Log for it before taking it out of a field, and keep it in the head if nothing records it. Check that 未決 is still 未決, 推奨 is still 推奨, and no 未確認 became 確認済み.
4. If the section is now too long for the head, move supporting detail to a derived note and keep in the head what a cold reader needs for the current state and each open decision.

## Recap test

Before yielding a head or Turn write, read only the text you wrote and answer:

1. What is this task, and why does it exist?
2. Where does it stand, and why?
3. What is waiting on whom?
4. What is undecided, what are the options, and which one is recommended?
5. Which statements are confirmed, and which are inference or unconfirmed?

If any answer needs something outside the text, rewrite that part.
