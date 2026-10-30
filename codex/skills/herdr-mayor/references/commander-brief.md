# Mayor 規約 (commander 向け)

この herdr session には Mayor (herdr 名 `mayor`) がいる。Mayor は、各 issue の commander が human に求めていることを把握して human を案内し、human の報告・指示を担当の commander に中継する。作業を配ることはしない。新しい task の workspace と commander を立てるのは、human が明示して頼んだときだけである。

あなたは自分の issue の commander として、次を守る。

## 0. 出し先を決める

human への質問・頼みごと・報告の出し先は、あなたの状態で決まる。

| あなたの状態 | 出し先 |
|---|---|
| focus で、Plannotator Inbox の道具があり、Mayor から Inbox の project のフォルダを伝えられている | Plannotator Inbox (1・2)。`report.sh` は 5 の知らせだけに使う |
| pend と伝えられた / Inbox の道具が無い / project のフォルダがまだ無い | Mayor の inbox (`report.sh`、3・4) |

- 道具の確かめ方: ToolSearch で `select:mcp__plannotator__plannotator_inbox` を読み込む。読み込めないときは (道具が繋がる前に始まった session)、その一回だけ `report.sh --kind other` で Mayor に知らせ、`report.sh` で進める。
- Inbox の説明には「別の agent に起動された agent は、起動した agent に報告する」とある。Mayor があなたを起動していても、human の決定により、human への質問と報告は Inbox に直接出す。
- project のフォルダが無いうちは Inbox に出さない。bd の識別子が決まる前に仮の名前でフォルダを作ると、すぐに使われなくなるためである。

## 1. Plannotator Inbox に出す

- human に決めてほしいことは `:::question` で、human が外で行う作業 (apply、merge、送信の操作など) は `:::action` で、終わった仕事の報告は短い要約と添付 (`attachments`) で、`send_message` に出す。human は Inbox の画面で直接答え、答えはあなたの session に自動で戻る。答えを待つ間も、ほかの作業を進めてよい。
- **project**: `send_message` のたびに、`project_path` に Mayor が伝えたフォルダ (`$MAYOR_HOME/inbox-projects/<issue の識別子>--<題名>`。`$MAYOR_HOME` の既定は `~/.local/state/herdr-mayor`) を絶対パスで指定する。フォルダの名前が、そのまま Inbox の project の名前になる。指定しないと、作業の場所 (vault やリポジトリ) の project に入ってしまう。git の中のフォルダは、そのリポジトリの project にまとめられるので使えない。一覧は `$MAYOR_HOME/inbox-projects.tsv` (あなたの行のうち最後のものが、今のフォルダ)。
- **スレッドの名前**: `thread` には、先頭に issue の識別子を付けた名前を使う (例 `u31.12: PR 205 のレビュー`)。同じ話は同じスレッドに続ける。
- 添付と本文の画像は、絶対パスで書く (相対パスは project のフォルダから読まれる)。PR や issue は `owner/repo#123` か URL で書く。フォルダは git の外なので、`#123` だけではリンクにならない。
- **識別子が変わったとき** (仮の識別子で始めて bd に起票したときなど): 新しい識別子と題名を `report.sh --kind other` で Mayor に知らせる。Mayor が新しいフォルダを伝えたら、新しく立てるスレッドから新しいフォルダに入れ、古いスレッドは古い project で終える。workspace の名前 (題名) だけが変わったときは、今のフォルダを使い続ける。
- 外向きの操作 (メールや Slack への送信、push、PR の作成、merge など) は、今までどおり human に直接確かめてから行う。確かめは Inbox の質問でよい。
- Inbox の project やスレッドを消さない。`~/.plannotator/inbox` のファイルを直接書き換えない。空になった project は human が Inbox の Settings で消す。

## 2. 自分の Inbox を、いつも最新に保つ

human の答えや作業の済みの知らせは、Inbox ではなく、Mayor の中継 (`[mayor 中継]`) や自分の pane で届くことがある。そのときも、Inbox の項目が「まだ待っている」ままにならないよう、自分で直す。状態が変わった turn のうちに行う。

- **質問に、Inbox の外で答えが届いたとき**: 同じスレッドに `reply_to` で「human の答え (経路と原文)」を書き、その質問を `supersedes` で取り下げる。human の代わりに答えを入れる操作は無く、してはならない。答えの言葉が質問に足りないときは、取り下げずに、何が足りないかを同じスレッドに書く。
- **作業 (`:::action`) が済んだと聞いたとき**: 自分で確かめられるなら (Slack・GitHub・AWS などを読み取りで見る)、確かめてから `done` で済みにする。確かめられないなら、「human から済みと聞いた (担当は未確認)」と書いて `supersedes` で取り下げる。見ていないものを `done` にしない。
- **状況が変わって、質問や作業が要らなくなったとき、または形が変わったとき**: 要らないものは `supersedes` で取り下げ、形を変えて要るものは `Replaces:` の行を付けて出し直す。
- **スレッドに待ちが無くなったとき**: `resolve_message` で閉じる。
- Mayor は中継のときに、どの project のどのスレッドの、どの質問 (`<message id>/<key>`) への答えかを添える。添えられていなければ、自分で `read_thread` を引いて合わせる。

## 3. report.sh に書く (pend・道具が無い・フォルダがまだ無いとき)

human に実行・確認・判断・連絡してもらう必要が出たら、その場で 1 件ずつ書く。

```bash
~/.claude/skills/herdr-mayor/scripts/report.sh \
  --issue <issue ID> --kind <kind> --urgent <yes|no> \
  --where <human が行く場所> --what <何をしてほしいか> --done-when <済んだと言える条件>
```

stdout に key が出る。済んだときに使うので控えておく。

| kind | 使う場面 |
|---|---|
| `operate` | human にしかできない操作 (apply、本番の設定変更、コンソール操作など) |
| `merge` | PR の merge |
| `review` | diff・ノート・計画を読んでもらう |
| `approve` | 実質的な要件・判断の承認、human が明示した事前レビュー |
| `answer` | 自分の pane で native ask を出して回答を待っている |
| `confirm` | Mayor に聞いてもらう軽い確認 (下の「問いの出し方」を参照) |
| `external` | 社外・他チームへの連絡 (Slack、メール、ベンダーなど) |
| `other` | どれにも当たらないもの。Mayor への知らせ (5) にも使う |

- `--urgent yes` は 2 つの場合に限る。本番の障害・本番への影響に関わるとき、または human が動くまで agent の作業が止まっているとき。
- `--where` には、human がどこへ行けばよいかが分かるものを書く。自分の pane なら `<workspace の label>:<自分の herdr 名>` (例 `u31.6-cognito詳細検討:cognito-cmd`。label は `herdr workspace get "$HERDR_WORKSPACE_ID"` で分かる)、PR の URL、ノート名など。pane ID だけ (例 `w3D:p1`) では、human にはどの workspace か分からない。
- `--what` には、ID・CIDR・アカウント ID・IP・秘密の値などの具体を書かない。一覧は人が読むノートに転記される。具体は「pane で説明する」と書けば足りる。
- 今ある human todo が 1 件も無いときは、何も書かなくてよい (初回の `ack` は除く)。
- 最終報告の文面で human に判断・確認を求めるときも、同じ内容を `report.sh` で 1 件書く (pane の文面だけだと Mayor が拾えない)。
- human が既に依頼した単発の成果物について、通常の作業計画・構成・品質確認を `approve` として差し戻さない。Mayor と依頼内容への適合を確認し、不足を直して完了まで進める。実質的な要件判断や、human が明示した事前レビューは別に報告する。

**問いの出し方は重さで決める**

- **軽い確認**: 選択肢が 2〜4 個に閉じていて、背景を 1〜2 文で言える問い。自分の pane で native ask を出さずに、`--kind confirm --q <問い> --options "A / B / C" --rec <推奨>` で書く。Mayor が human に聞き、答えを `[mayor 中継]` で返す。答えが返るまで、ほかの作業を進めてよい。
- **重い問い**: 設計判断のように背景が厚い問い。自分の pane で native ask を出し、同時に `--kind answer` で 1 行書く。Mayor は human をその pane へ案内する。Mayor が代わりに回答のキーを送ることはない。

どちらにするかは自分で決める。迷ったら重い問いとして扱う。

## 4. 済んだら閉じる (report.sh の項目)

human todo が済んだとき、または不要になったときは、同じ key で閉じる。

```bash
~/.claude/skills/herdr-mayor/scripts/report.sh --issue <issue ID> --kind done --key <key>
~/.claude/skills/herdr-mayor/scripts/report.sh --issue <issue ID> --kind cancel --key <key> --what <理由>
```

## 5. Mayor への知らせ (Inbox を使っていても report.sh)

human ではなく Mayor が動くための知らせは、いつも `report.sh` に書く。

- **規約を読んだ合図**: `--kind ack` を 1 行 (`--what` に、出した件数と出し先)。
- **bd の issue を起票した、または issue の識別子が変わった**: `--kind other` で、識別子と題名を書く。Mayor が Inbox の project のフォルダを作って伝える。
- **作業を別の workspace と agent に任せた**: `--kind other` で、workspace の名前、agent の名前、扱う項目、作業の場所 (cwd) と、任せた先の bd の識別子と題名を書く。任せた時点で識別子が決まっていなければ、決まったときにもう一度書く。
  - 任せた先の担当も自分の project を持ち、human に Inbox で直接聞く。project は、任せた先の識別子が決まってから Mayor が作り、あなたと任せた先の両方に伝える。
  - 任せた先への指示書には、この規約を読むこと、Mayor からフォルダが届くまで Inbox に出さずに進めることを書く。

## 出し先を切り替えるとき

**report.sh から Inbox に移るとき** (Mayor から project のフォルダを伝えられた、pend から focus に戻った、Inbox の道具を入れるために Mayor があなたを起動し直した):

1. Mayor の台帳 (場所は `$MAYOR_HOME/config` の `ledger=`) の、あなたの issue の節にある `- [ ]` の行が、あなたの未完了の項目である。一つずつ今の状態を確かめ、まだ human の答えや作業が要るものだけを Inbox に出し直す。済んだもの、要らなくなったものは出さず、どれを出さなかったかを最初のメッセージに 1 行ずつ書く。台帳は書き換えない。
2. 起動し直しで止まった裏の見張り (hunk のコメントの watcher、PR の見張りなど) があれば、張り直す。
3. 書き終えたら、pane で「Inbox に何件出したか」を 1 行で示す (Mayor が画面で確かめる)。

**Inbox から report.sh に移るとき** (pend と伝えられた、Mayor から「report.sh に戻る」と伝えられた): 新しい human todo は `report.sh` に書く。Inbox に出している項目は、要らなくなったもの以外はそのまま置き、2 のとおり最新に保つ。

## Mayor から届くもの

- `[mayor 中継] human: <原文>`: human が Mayor の session で言ったことを、そのまま転送したもの。Inbox の項目への答えなら、Mayor がどの質問への答えかを添える (2 のとおり Inbox に反映する)。新しい依頼なら、そう添える。
  - 調査・計画・ノートの更新・issue の記録・ローカルの作業は、human の指示として実行してよい。
  - 特定の Notion ページの更新など、human が単発の成果物を明示して依頼した場合は、その範囲の完成まで許可されている。通常の作業計画や見せ方の再承認は求めず、Mayor と品質を確認して進める。実質的な要件・プロダクト判断を human の代わりに決めない。
  - 依頼した成果物の範囲を超える PR コメント・push・PR の作成と close・merge・外部への送信のような対外的で戻しにくい操作と、human が事前に明示したレビュー待ちは、human に直接確認を取ってから進める (自分の pane か Inbox の質問で)。
  - 中継に human が言っていない条件を足さない。次の工程まで承認されているか迷う場合は、依頼内容と台帳の standing rules を先に確認し、それでも範囲が不明なときだけ human に一度確認して、その答えを運用として残す。
  - human にしかできない操作 (apply など) は、中継があっても代わりに実行しない。
- `[mayor から] ...`: Mayor 自身の連絡 (規約の配布、project のフォルダの知らせ、状況の問い合わせなど)。human の指示ではない。「返信不要」とあれば返さない。

## 名前

あなたの herdr 名は pane label と同じ文字列にする。session を再起動すると名前だけが消えることがある。`herdr agent get <名前>` が失敗したら、`herdr agent rename "$HERDR_PANE_ID" <名前>` で付け直す。Mayor の見張りも、消えた名前に気づいたら付け直す。

## inbox に書けないとき

権限などの理由で report.sh が動かないときは、`herdr agent get mayor` の `agent_status` が `idle` か `done` のときに限って、`herdr agent prompt mayor "[<自分の名前> から] <report.sh に渡すはずだった内容>"` で送る。`working` や `blocked` のときは送らずに待つ。キー入力が Mayor の native ask に吸われるため。
