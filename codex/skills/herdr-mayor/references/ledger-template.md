# human todo 台帳

> [!info] この台帳
> Mayor (herdr 名 `mayor`) が、中継した human の言葉、human の決定、standing rules と、`report.sh` で届いた「human がすること」を残すノート。
> Plannotator Inbox を使う focus の担当の「いま誰の番か」は Inbox が正本で、このノートには写さない (担当ごとの Inbox の project は `$MAYOR_HOME/inbox-projects.tsv`)。`report.sh` で届く項目 (pend の担当、Inbox の道具の無い担当) は、このノートが正本。
> commander からの受け口は `$MAYOR_HOME/inbox.md`。具体的な値 (ID・CIDR・秘密) は書かない。詳しくは「どこで」の pane で commander に聞く。場所は `<workspace の label>:<agent 名>` で書く (pane ID だけでは workspace が分からない)。
> 更新: <YYYY-MM-DD HH:MM> (inbox <n> 行目まで反映)

> [!important] 優先
> human に上げるのは focus の issue だけ: <issue の一覧>。それ以外は pend として「保留」に置く。例外は本番の障害・影響に関わる急ぎ。
> 優先度の正本は `$MAYOR_HOME/roster.tsv` の priority 列。

## 急ぎ

| key | issue | commander | 何を | どこで | 完了の条件 |
|---|---|---|---|---|---|

## focus の issue

### <issue ID> <issue の短い名前> — `<workspace の label>:<commander>` (Inbox の project `<issue>--<題名>`)

- <MM-DD HH:MM> (<経路: Mayor / Inbox / pane>): <中継した human の言葉 (原文)、または human の決定>。Inbox の項目への答えなら `<project> › <スレッド>` の `<message id>/<key>`
- [ ] `<key>` <kind>: <何を> — どこで: <where> — 完了: <done_when> (`report.sh` で届いた項目)
- [ ] `<commander>:pane-<短い名前>` <kind> (Mayor が pane から転記): <何を> — どこで: <workspace の label>:<commander>

## Mayor が聞く確認 (focus)

- [ ] `<key>` <issue>: <問い> — <A> (推奨) / <B> / <C>

## 中継済みで進行中の依頼

- <human の依頼の要約> — 中継: <日時>、宛先 `<commander>`。答える Inbox の項目: <`<message id>/<key>`、または「新しい依頼」>。完了報告は未受領

## standing rules

- <human が一度決めた運用。例: 『approve』は commit まで含む> (<日付>)

## 保留 (pend)

human には上げない。focus に移ったら、ここから戻す。

### <issue ID> <issue の短い名前> — `<workspace の label>:<commander>`

- [ ] `<key>` <kind>: <何を>

## commander 一覧

| issue | commander | 場所 (workspace の label:agent 名) | 優先 | 出し先 (Inbox の project / report.sh) | 規約 |
|---|---|---|---|---|---|

## agent のいない workspace

- <workspace label> (<workspace id>)

## 済んだもの

- [x] `<key>` <issue>: <何を / 問い> → <答え・結果> (<時刻>)
