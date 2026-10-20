# Mayor 規約 (commander 向け)

この herdr session には Mayor (herdr 名 `mayor`) がいる。Mayor は各 issue の commander から「human にしてもらうこと」を集めて human に示し、human の報告・指示を担当の commander に中継する。作業を配ったり、agent を起動したりはしない。

あなたは自分の issue の commander として、次の 3 つを守る。

## 1. human todo は inbox に書く

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
| `approve` | 計画・判断・成果物の承認 |
| `answer` | 自分の pane で native ask を出して回答を待っている |
| `confirm` | Mayor に聞いてもらう軽い確認 (下の 2 を参照) |
| `external` | 社外・他チームへの連絡 (Slack、メール、ベンダーなど) |
| `other` | どれにも当たらないもの |

- `--urgent yes` は 2 つの場合に限る。本番の障害・本番への影響に関わるとき、または human が動くまで agent の作業が止まっているとき。
- `--where` には、human がどこへ行けばよいかが分かるものを書く。pane ID (例 `w3D:p1`)、PR の URL、ノート名など。
- `--what` には、ID・CIDR・アカウント ID・IP・秘密の値などの具体を書かない。一覧は人が読むノートに転記される。具体は「pane で説明する」と書けば足りる。
- 今ある human todo が 1 件も無いときは、何も書かなくてよい (初回の `ack` は除く)。

## 2. 問いの出し方は重さで決める

- **軽い確認**: 選択肢が 2〜4 個に閉じていて、背景を 1〜2 文で言える問い。自分の pane で native ask を出さずに、`--kind confirm --q <問い> --options "A / B / C" --rec <推奨>` で書く。Mayor が human に聞き、答えを `[mayor 中継]` で返す。答えが返るまで、ほかの作業を進めてよい。
- **重い問い**: 設計判断のように背景が厚い問い。これまでどおり自分の pane で native ask を出し、同時に `--kind answer` で 1 行書く。Mayor は human をその pane へ案内する。Mayor が代わりに回答のキーを送ることはない。

どちらにするかは自分で決める。迷ったら重い問いとして扱う。

## 3. 済んだら閉じる

human todo が済んだとき、または不要になったときは、同じ key で閉じる。

```bash
~/.claude/skills/herdr-mayor/scripts/report.sh --issue <issue ID> --kind done --key <key>
~/.claude/skills/herdr-mayor/scripts/report.sh --issue <issue ID> --kind cancel --key <key> --what <理由>
```

## Mayor から届くもの

- `[mayor 中継] human: <原文>`: human が Mayor の session で言ったことを、そのまま転送したもの。
  - 調査・計画・ノートの更新・issue の記録・ローカルの作業は、human の指示として実行してよい。
  - PR コメント・push・PR の作成と close・merge・外部への送信のように、対外的で戻しにくい操作は、中継だけでは実行しない。自分の pane で human に native ask で確認を取ってから行う。中継は伝聞であって、あなたの会話の human が直接言ったことではないため。
  - human にしかできない操作 (apply など) は、中継があっても代わりに実行しない。
- `[mayor から] ...`: Mayor 自身の連絡 (規約の配布、状況の問い合わせなど)。human の指示ではない。

## 名前

あなたの herdr 名は pane label と同じ文字列にする。session を再起動すると名前だけが消えることがある。`herdr agent get <名前>` が失敗したら、`herdr agent rename "$HERDR_PANE_ID" <名前>` で付け直す。Mayor の見張りも、消えた名前に気づいたら付け直す。

## inbox に書けないとき

権限などの理由で report.sh が動かないときは、`herdr agent get mayor` の `agent_status` が `idle` か `done` のときに限って、`herdr agent prompt mayor "[<自分の名前> から] <report.sh に渡すはずだった内容>"` で送る。`working` や `blocked` のときは送らずに待つ。キー入力が Mayor の native ask に吸われるため。
