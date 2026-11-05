# human todo 台帳

> [!info] この台帳
> Mayor (herdr 名 `mayor`) が、Inbox に残らないものだけを書くノート。human が今の状態を見る場所は Plannotator Inbox の Board と、issue ごとの「<issue>: 現況」のスレッドで、このノートは読まなくてよい。Mayor が要約やハンドオフのあとに、git の履歴と grep で取り戻すための記録。
> 書くのは 4 種類: Inbox の外で届いた human の決定と恒久の決まり、Mayor が herdr で送った中継とそれが届いたか、`report.sh` で届いた項目 (pend の担当、Inbox の道具の無い担当。これはこのノートが正本)、commander の一覧と agent のいない workspace。Inbox の質問・答え・issue ごとの出来事は写さない (担当ごとの Inbox の project は `$MAYOR_HOME/inbox-projects.tsv`)。
> commander からの受け口は `$MAYOR_HOME/inbox.md`。具体的な値 (ID・CIDR・秘密) は書かない。vault の git に残るので、弱点の中身は一般的な言い方にとどめる。詳しくは「どこで」の pane で commander に聞く。場所は `<workspace の label>:<agent 名>` で書く (pane ID だけでは workspace が分からない)。
> 更新: <YYYY-MM-DD HH:MM> (inbox <n> 行目まで反映)

> [!important] 優先
> human に上げるのは focus の issue だけ: <issue の一覧>。それ以外は pend として「保留」に置く。例外は本番の障害・影響に関わる急ぎ。
> 優先度の正本は `$MAYOR_HOME/roster.tsv` の priority 列。

## 決定と決まり

Inbox の外 (Mayor のチャット、担当の pane) で届いた human の決定と、一度決めた恒久の運用。

- <MM-DD HH:MM> (<経路: Mayor / pane>) <issue または「全体」>: <human の言葉 (原文)、または決定>。Inbox の項目への答えなら `<project> › <スレッド>` の `<message id>/<key>`
- <human が一度決めた運用。例: 『approve』は commit まで含む> (<日付>)

## 中継の記録

1 回の中継に 1 行。

- <MM-DD HH:MM> → `<commander>` (<issue>): <中継した human の言葉 (Inbox の `<message id>`、または「新しい依頼」)、または `[mayor から]` の知らせの要旨>。届いたか: <画面で確かめた時刻 / 未着で再送 / 確かめ待ち>

## file inbox の項目

`report.sh` で届いた focus の項目と、Mayor が pane から転記した項目。急ぎを先に書く。

- [ ] `<key>` <issue> <kind>: <何を> — どこで: <where> — 完了: <done_when>
- [ ] `<commander>:pane-<短い名前>` <issue> <kind> (Mayor が pane から転記): <何を> — どこで: <workspace の label>:<commander>
- [ ] `<key>` <issue> confirm (Mayor が聞く): <問い> — <A> (推奨) / <B> / <C>

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
