---
name: beads
description: bd（beads）の課題管理ワークフロー。`.beads/` がある場合や `bd` コマンド実行時に使用。
---

# Beads

## When to use
- `BEADS_DIR` 環境変数が存在する
  - 不明な場合: `echo $BEADS_DIR` 結果が`/path/to/.beads`ディレクトリを示すpathを出力する
- ユーザーが `bd` コマンド（`bd ready`, `bd create`, `bd close`, `bd sync`, …）を求めている。
- ユーザーが beads を **作業台帳**（計画/進捗/判断を実装中に記録）として使いたい。

## Principle: bead as work ledger
- アクティブな bead が **計画**, **進捗**, **判断**, **検証** の正本。
- 長いチャット説明より bead への記録を優先する。セッションがリセットされても残る必要がある。

## Molecules (workflow steps as beads)
Molecule は beads が「この作業をやる」を durable で段階的なワークフローに落とし込む方法。

- **Formula**: ワークフローのソースファイル（`bd formula list` で探索）。
- **Proto**: 調理済みテンプレート epic（固相）。
- **Mol**: `bd mol pour` で作る proto の永続インスタンス（液相）。
- **Wisp**: `bd mol wisp` で作る一時インスタンス（気相）。

Mol では各ステップが実体の bead なので、「ステップごとにログを残す」が自然にできる。

## Per-step ledger contract (mol step beads)
各ステップ bead を完了するたびに:
1. `notes` に Now/Next/Blockers/Verify を最新化。
2. Markdown **ChangeLog** コメントをちょうど 1 件追加（テンプレは下記）。
3. 結果重視の理由でステップを close する。

推奨クローズ理由:
- `bd close <step-id> --reason "Implemented: <一行の振る舞いアウトカム>"`

## Workflow loop (implementation-aware)
1. コンテキスト準備: `bd prime`。
2. 作業を選ぶ:
   - `bd ready`（一般）
   - `bd ready --mol <mol-id>`（molecule 内）
   - `bd mol current <mol-id>`（この molecule の現在位置は？）
   その後 `bd show <id>`。
3. 開始/claim: `bd update <id> --claim`（または `bd update <id> --status in_progress`）。
4. ミニ計画をseedとして入れる（ローリング）:
    - `bd update <id> --notes "$(cat <<'EOF'
 ## Status
 - Stage: Discover | Define | Develop | Deliver
 - Now: …
 - Next: …
 - Blockers: …

## Verification
- [ ] <exact command>  # expected: <signal>
EOF
)"`
5. 小さく実装し、各スライス後に durable なログを追加:
   - `bd comments add <id> "…"`
   - 実際の判断をしたら `--design` を更新。
   - 検証条件の理解が進んだら `--acceptance` を更新。
6. 結果重視の理由で close: `bd close <id> --reason "…"`。
7. 必要に応じて sync: `bd sync`。

## What to record during implementation

### `notes` (rolling status board)
- **短く**、**最新**に。上書きは自由。
- 向いているもの: Now/Next/Done、ブロッカー、現在の検証コマンド。

### Comments (append-only timeline)
- コメントは段階的な計画や「何が変わったか」のスナップショットに使う。
- 推奨コメント種別:
  - **Checkpoint**: 直近でやったこと + 次。
  - **Decision**: 判断 + 根拠 + 代替案。
  - **Patch summary**: 変更パス + 振る舞いの差分。
  - **Verification**: 実行したコマンド + 成否のシグナル。
  - **Handoff**: 現状 + 次にやること。

例:
```bash
bd comments add bd-123 "$(cat <<'EOF'
Checkpoint: tighten parser guardrails
- Changed: src/foo.rs (parse), src/foo_test.rs (cases)
- Decision: reject empty input early
- Verify: cargo test -p foo  # pass
EOF
)"
```

### `design` (durable decisions)
- 長期的なアーキ判断はここに書き、スクロールで埋もれないようにする。
- 判断をしたら更新:
  - `bd update <id> --design "$(cat <<'EOF'
## Decisions
- …

## Alternatives
- …

## Invariants / gotchas
- …
EOF
)"`

### Discoveries (scope control)
- 新たに見つけた作業は新規 bead として起票し、黙ってスコープ拡大しない。
  - `bd create "..." --type=task --priority=2`
- 追跡できるようリンクする:
  - `bd dep add <new-issue> <current-issue> -t discovered-from`

## Alternate uses (beyond tickets)

### Encode “what changed” without pasting diffs
- 意味のあるスライスごと（または引き継ぎ/close 前）に **ChangeLog** コメントを追加。
- 目的: 新しいセッションでも 30 秒で「何が変わったか」「何が残っているか」を把握できる。

テンプレ（Markdown のみ、ハイシグナル、diff は貼らない）:
```bash
bd comments add <id> "$(cat <<'EOF'
ChangeLog
- Stage: Discover | Define | Develop | Deliver
- Intent: <このステップで達成したかったこと>
- Files: <パス、短い一覧>
- Behavior: <いま真になったこと / ユーザーに見える変更>
- Risk: <注意すべきリグレッション>
- Verify: <exact command>  # <pass/fail>
- Next: <次の具体的な行動>
EOF
)"
```

存在する場合の任意追記:
- `Commit: <sha>`
- `PR: <url>`

### Beads as agents (first-class workers)
Gas Town ではエージェントを bead として扱い、稼働/状態をクエリ可能かつ durable にする。このパターンは beads を使う任意のリポジトリで採用できる。

**横断的に見つけられるようにする約束事:**
- 永続的な ID ごとに 1 つの agent bead を作る。
- 検索しやすいラベルを必ず付ける:
  - `agent`（大枠）
  - `agent:<name>`（安定した検索キー）
  - `role:<role>`（polecat/crew/witness/refinery/mayor/deacon）

作成:
```bash
bd create --type=agent --role-type=polecat --agent-rig <rig> \
  --labels agent,agent:<name>,role:polecat \
  --title "<name>"
```

後で見つける:
- `bd list --label agent:<name> --all`
- `bd search "agent:<name>"`

作業中は状態を最新化:
- `bd agent state <agent-id> working|stuck|done`
- `bd agent heartbeat <agent-id>`

運用上の直交的な状態を追跡（イベント作成 + ラベルキャッシュ）:
- `bd set-state <agent-id> health=healthy|failing --reason "..."`
- `bd set-state <agent-id> mode=normal|degraded --reason "..."`

複数エージェント/課題の進行をリアルタイム監視:
- `bd activity --follow`（ルーティングを使うなら `--town` を追加）

## Command quick reference
- `bd prime` — AI 最適化ワークフローのコンテキスト読み込み。
- `bd ready` — ブロックされていない作業一覧。
- `bd show <id>` — issue 詳細の確認。
- `bd create "Title" --type=task --priority=2` — 新規 issue 作成。
- `bd update <id> --claim` — 取得して作業開始。
- `bd update <id> --notes ...` — ローリングな状態/計画を更新。
- `bd comments add <id> ...` — 進捗ログを追記。
- `bd update <id> --design ...` — 永続的な判断を更新。
- `bd update <id> --acceptance ...` — 検証条件を正しく保つ。
- `bd dep add <id> <depends-on> -t discovered-from|blocks|tracks|related|...` — issue をリンク。
- `bd lint [id...]` — テンプレ不足のチェック。
- `bd set-state <id> <dimension>=<value> --reason "..."` — イベント + キャッシュ済みラベル状態。
- `bd agent state <agent-id> <state>` — agent 状態 + last_activity を更新。
- `bd agent heartbeat <agent-id>` — last_activity のみ更新。
- `bd activity --follow` — ライブ進捗を監視。
- `bd close <id> --reason "..."` — 結果 + シグナル付きで close。
- `bd sync` — beads を git remote と同期（通常セッション終わり）。

## Safety notes
- `bd hooks install`, `bd init`, `bd config set ...`, `bd sync` はリポジトリ（および/または git 履歴）を変更する。明示依頼がない限り事前確認する。

