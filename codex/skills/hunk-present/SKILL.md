---
name: hunk-present
description: Present a locally agent-generated changeset to a human in Hunk and get their approval. Builds a dependency-ordered reading map as an `--agent-context` sidecar JSON (changeset summary, per-file roles, numbered `1.)` line annotations), hosts the TUI for the user in a dedicated Herdr tab named hunk-PR番号 (the default; falls back to handing over the launch command when Herdr is unavailable), watches for new human comments, then answers their questions as inline Hunk comments, re-syncs the session after a delegated fix lands (sidecar anchors, reload, in-place replies), and records the approval verdict. Explanation and approval, not critique; never reads or drives the TUI itself. Use when the user says "/hunk-present", wants a change presented or explained in Hunk, wants a reading map or walkthrough of agent-written changes, or wants human sign-off on a local diff before moving on. Trigger on hunk で提示, hunk で解説, 変更の読み方を示して, human approval, 承認をもらう, agent-context sidecar, reading map, herdr pane で提示.
---

# hunk-present

Present a changeset that a coding agent just produced so a human can understand it and approve it. Hunk is the presentation surface: the reading map lives in the diff view, and the human's questions get answered there too.

## Core principles (non-negotiable)

- **Explain and get approval, don't critique** — state WHAT each change does and WHY it exists so the human can judge it. Hunting for defects is `$review` / `$difit-review` territory.
- **The TUI belongs to the user — never read or drive it** — do not interact with a running `hunk` TUI (no keystrokes, no pane reads of its screen). Launching is a different matter: the default is to *host* the TUI for the user in a dedicated Herdr tab & pane (see 4). Only when no Herdr session is available (`HERDR_ENV` unset) fall back to printing the launch command for the user to run themselves. Never run the TUI in your own pane or consume it as your own output.
- **Sidecar first** — the normal entry point is a prewritten `--agent-context` JSON, because presentation happens before any session exists. Only touch `hunk session ...` once a live session is confirmed.
- **Reading map is mandatory** — always produce a changeset-level summary, a one-line role for every changed file, and numbered `1.) 2.) 3.) …` annotations in dependency order. Never an unordered pile of notes.
- **Briefing before the diff** — the first thing the human sees is a briefing that answers three things: 背景 (why this change is needed), 文脈 (where it sits in the larger work), and いま何をどう変更しようとしているか. **Hunk 0.17.7 does not render the top-level `summary` or `files[].summary` in the diff view** (the former is only stored; the latter only feeds the sidebar search; only `annotations[]` appear, inline beside hunks), so carry the briefing as the first annotations — a few notes numbered `0.)` on the first hunk of the first file in `files[]` — and keep the same text in `summary` for tools that do read it. Re-check this when Hunk is upgraded. Write each note as one claim plus its breakdown (3a): a one-sentence headline in `summary`, a nested plain-text outline in `rationale` instead of a paragraph, every line a full statement rather than a bare keyword, and generous enough that someone who has not followed the conversation can grasp the whole situation. Cite the Obsidian vault note that holds that context as `<note>.md:L<n>` (or `L<a>-L<b>`, path relative to the vault root) so the human can open the source. If no vault note covers it, say so in the briefing instead of inventing a pointer. Where 3b says a picture explains faster than prose, the 文脈 and いま何をどう変更するか notes also carry a box-art diagram in their `rationale`.
- **Box art for Hunk is U+2800-padded, always** — Hunk collapses runs of ordinary whitespace (U+0020, U+00A0, U+2002, U+3000) into one space, which shifts the right border of every box; only the braille blank (U+2800) survives. Produce every diagram with this skill's `scripts/mermaid_to_boxart.py` (default `--pad braille`), never with crit-explain's copy, never with hand-typed spaces, and never inside a code fence (Hunk prints fences literally). Details and measurements in 3b.
- **One shot, no convergence loop** — answer what the human asks, record the verdict, stop. Do not loop fix → reload → re-collect; that is `$herdr-review-loop`.
- **Never edit source here** — this skill writes the sidecar and comments only.
- **Japanese prose** — write `summary` / `rationale` bodies in Japanese. Keep identifiers, paths, and commands verbatim.

## CLI reference

For exact `hunk session ...` syntax, read the bundled skill instead of guessing:

```bash
cat "$(hunk skill path)"
```

That file is the authority for `session list/get/context/review/navigate/reload/comment`. This skill only adds the sidecar schema (below), which the bundled skill does not cover.

## Workflow

### 1. Fix the target

Pick exactly one target and reuse it for both reading the diff and the launch command, so line numbers line up:

- uncommitted work → `hunk diff` (untracked files are included by default; add `--exclude-untracked` to drop them)
- staged only → `hunk diff --staged`
- a range → `hunk diff <base>...<head>` — **use three-dot (merge-base compare) for any PR presentation**. Two-dot is a snapshot compare: everything the base branch gained after the fork shows up as reversed deletions, which reads as "this PR deletes unrelated files" and sends the reviewer chasing a wrong-base hypothesis
- last commit → `hunk show`

If the user did not say which, and more than one is plausible, ask before building the map.

### 2. Build the reading map

- Read the changed files in full (`git diff --stat <target>`, then the core files).
- Find the **dependency root** — the definition everything else references — and order outward: prerequisites → root → things attached to it → callers → outputs.
- **Select core lines**: annotate only the hunks that carry intent, a design decision, a risk, or a thing the human would not spot alone. Skip lockfiles, generated files, and mechanical renames.
- Give noise files a `summary` only, no annotations, so the human knows what to skip.
- **Gather the briefing sources**: find the vault note that tracks this work (task note 論点 / Event Log, design note, practice log). Get exact line numbers with `grep -n`, then re-read those lines so each cited `file:line` still says what the briefing claims. Prefer the durable record over chat history.
- **Decide the briefing diagrams** (3b): for the 文脈 note and the いま何をどう変更するか note, settle now whether each gets a diagram, so the sidecar is written once.

### 3. Write the sidecar

Write to `<repo-root>/.local/hunk/agent-context.json` (create the directory; confirm `.local/` is ignored by git before writing).

**Sidecar order is display order.** Hunk reorders the diff files to match `files[]`, so listing files in dependency order makes the on-screen order the reading order. Number the annotation summaries `1.)`, `2.)`, `3.)` … in that same order — ASCII prefixes stay greppable and typable.

Schema:

| Field | Required | Meaning |
| --- | --- | --- |
| `version` | yes | `1` |
| `summary` | yes | changeset-level overview (背景 / 文脈 / いま何をどう変更するか with vault note `file:line` sources, then reading order and what is not yet verified). **Not rendered by Hunk 0.17.7** — the human sees the same text only through the `0.)` annotations (see Briefing) |
| `files[].path` | yes | repo-relative path, matching the diff |
| `files[].summary` | yes | one-line role of this file in the change (sidebar search only in Hunk 0.17.7; not displayed) |
| `files[].annotations[]` | no | inline notes for this file |
| `annotations[].newRange` | one of | `[start, end]` 1-based inclusive lines on the new side |
| `annotations[].oldRange` | one of | `[start, end]` on the old side, for deleted lines |
| `annotations[].summary` | yes | the note body, prefixed `N.)` |
| `annotations[].rationale` | no | the WHY behind the note; the briefing's box-art diagram goes at its end (3b) |
| `annotations[].author` | no | attribution label, e.g. `"Claude Code"` |

```json
{
  "version": 1,
  "summary": "## 背景\n…（出典: `design-note.md:L40-L52`）\n\n## 文脈（いまどこにいるか）\n…（出典: `task-note.md:L18-L27`）\n\n## いま何をどう変更するか\n…\n\n## 読む順番\n1.) 前提 → 3.) 中心 → 5.) 呼び出し側",
  "files": [
    {
      "path": "src/normalize.ts",
      "summary": "クエリ正規化を一箇所に集約する土台。",
      "annotations": [
        {
          "newRange": [1, 3],
          "summary": "0.) 【ブリーフィング 1/4: 背景】検索の正規化が各所に散らばっていた。",
          "rationale": "- 散らばり: クエリの整形が、呼び出し元ごとに別々に書かれている [確認]\n  - 影響: 同じ入力でも、経路によって検索結果がそろわない\n- 出典 [記録]\n  - `design-note.md:L40-L52`",
          "author": "Claude Code"
        },
        {
          "newRange": [1, 3],
          "summary": "0.) 【ブリーフィング 2/4: 文脈】検索層の整理の 1 本目で、呼び出し側は触らない。",
          "rationale": "- 位置: 検索層の整理の 1 本目の commit\n  - 前提: 呼び出し側の API は変えない\n- 次: 呼び出し側を正規化済みの入力に切り替えるのは、次の commit\n- 出典 [記録]\n  - `task-note.md:L18-L27`",
          "author": "Claude Code"
        },
        {
          "newRange": [1, 3],
          "summary": "0.) 【ブリーフィング 3/4: いま何をどう変更するか】search.ts の手前に正規化ヘルパを足す。",
          "rationale": "- 足すもの: `normalize.ts` を新規に作る\n  - 空白・大小文字・ダッシュ表記をそろえる関数を置く\n  - 帰結: 後続の検索層は、正規化済みのトークンだけを前提にできる\n- 触らないもの: `search.ts` と呼び出し側\n\n図: NEW: が、この commit で足すもの\n┌──────────────┐\n│\u2800normalize.ts\u2800│\n│\u2800NEW:\u2800正規化\u2800\u2800│\n└──────────────┘\n\u2800\u2800\u2800\u2800\u2800\u2800\u2800┌┘\n…（`mermaid_to_boxart.py --json` の出力をそのまま貼る）",
          "author": "Claude Code"
        },
        {
          "newRange": [1, 3],
          "summary": "0.) 【ブリーフィング 4/4: 読む順番と未確認】読むのは 1.) の 1 件。未確認は 1 つ。",
          "rationale": "- 読む順番: 1.) の 1 件だけ (`normalize.ts` の新規ファイル全体)\n- 確認したこと [確認]\n  - 型検査とテストが通る\n- 未確認 [未確認]\n  - 全角ダッシュが実データに現れるか。本番ログで確かめる",
          "author": "Claude Code"
        },
        {
          "newRange": [1, 3],
          "summary": "1.) 空白・大小文字・ダッシュ表記の正規化ヘルパを追加。",
          "rationale": "後続の検索層が正規化済みトークンだけを前提にできるため、同種の整形ロジックが各所に散らない。",
          "author": "Claude Code"
        }
      ]
    }
  ]
}
```

- The `rationale` strings above indent with ordinary spaces, the natural way to write them; `--harden` (3a) turns that indent into U+2800 before launch.
- Do not copy secrets, tokens, keys, or credential-like material from the diff into the sidecar or any command line.
- Keep every `path` exactly as the diff reports it; unmatched paths silently lose their notes.

### 3a. The briefing as a nested outline

Each `0.)` note makes one claim and breaks it down: the claim is the headline, the breakdown an outline under it. The four notes are 背景, 文脈, いま何をどう変更するか, and 読む順番と未確認 (numbered `1/4` … `4/4`). The outline rules come from `$unpack` (R1 depth, applied to indent levels; R3 peers; R4 connectives with content; R5 stand-alone claim lines; R7 no padding; the Expansion test; epistemic labels). Its IDs and ID freeze (R2), topic budget, frames, set shape, chain test, and prose pivots are left out: a briefing is four short notes read once from the top, not a multi-topic read, and a follow-up comment can quote the line instead of an ID (`[解釈]`). A worked before/after is in `references/briefing-outline-example.md`.

**Shape of a note** (`[解釈]`; the headline/body split follows how Hunk draws `summary` and `rationale`)

- `summary` is the claim: one sentence that stands alone. Reading only the four headlines must still give the gist of the briefing (Skip test). A headline longer than the note wraps, which is harmless.
- `rationale` is the breakdown, as plain text. No paragraph.
- Only for 文脈 and 変更, when 3b says to draw: a blank line, a one-line caption, then the diagram (caption example: `図: NEW: が、この commit で足すもの`).

**Outline grammar**

- One idea per line, marker `- `, two cells of indent per level, three levels at most (R1). A fourth level means the note should be split.
- Nest by logic, not by order of mention. A child is something its parent needs: a reason, a premise, a consequence, an exception, an example, or a part of it. Siblings are peers (R3); do not flatten "A, so B, but C" into three siblings: B goes under A (`帰結:`), C under B (`ただし:`).
- Name the relation when it is not plain part-of, and put the real content after the colon: `理由:` `前提:` `帰結:` `ただし:` `例:` `出典:` (R4). A line that only holds children and says nothing is dropped.
- Every line is a complete statement that reads without its children (R5), in plain words rather than a bare keyword. The children answer "why may I believe this" and can be skipped.
- Expand a line only when its children give a premise the human's judgment depends on, a magnitude (a number, a count, a scope), or a failure condition (what would make it wrong); otherwise leave it as one line (Expansion test). A child that restates its parent is padding (R7).
- Label what the human may doubt, with one ladder for the whole briefing: `[記録]` a note or doc says so (cite `file:L<n>`), `[確認]` checked in this change (a command ran, the code was read), `[解釈]` the agent's inference, `[未確認]` not checked yet (say when it will be). An unlabeled line is visible in the diff itself.
- Keep every line within 100 display columns including the indent (a Japanese character counts 2); move the rest into a child line. Do not use `→` or other East-Asian-ambiguous characters; the relation labels carry the logic. Do not align with runs of spaces.

**What the level-1 lines are** (`[解釈]`)

- 背景: the goal this change serves, what already stands, the decision it follows and who made it, the sources.
- 文脈: what is decided, what is only the agent's reading and not yet approved, what comes before and after.
- 変更: what is added, changed, or left alone; each new term the human must learn; the review involvement level; the sources.
- 読む順番と未確認: the order of the `1.)` … `N.)` notes; what was checked and how; what was not run; each unverified item and when it will be checked.

**Authoring flow** — write the `rationale` strings with ordinary spaces (two per level), then run both commands; `--check` must exit 0 before launch:

```bash
python3 <skill-dir>/scripts/mermaid_to_boxart.py --harden .local/hunk/agent-context.json
python3 <skill-dir>/scripts/mermaid_to_boxart.py --check .local/hunk/agent-context.json
```

`--harden` rewrites the file in place (leading spaces and tabs of every `rationale` line, and every space on a diagram line, become U+2800 written as `\u2800`; running it twice changes nothing). `--check` also flags a line that starts with ordinary whitespace, a run of spaces inside a line, an indent that is odd or deeper than three levels, and a briefing line wider than `--max-width`.

**Why** (Hunk 0.17.7, `[実測]` in a pseudo terminal; re-measure with `scripts/check_hunk_render.py`, see 3b):

- A leading run of ordinary spaces vanishes, so an outline indented with spaces comes out flat. An indent made of U+2800 is kept at every level.
- A line wider than the note's text width wraps, and the continuation starts at column 0 with no hanging indent, so the nesting of a wrapped line is lost. At 124 columns the width is 112; in a 100-column window it is 88. Keep lines short, and for a pane narrower than 112 columns pass `--max-width <pane width − 12>`.

### 3b. Diagrams in the briefing

A diagram goes at the end of the `rationale` (after the outline, a blank line, and a one-line caption) of the briefing's 文脈 note (how the pieces are arranged today) and its いま何をどう変更するか note (what this change adds or rewires). Not in 背景, and not in the per-file `1.) …` notes, which stay line-level WHAT/WHY. The top-level `summary` is never displayed, so it may leave the diagrams out.

**When to draw** (`[解釈]`: a heuristic, not measured; the test is whether the picture says something prose cannot say as fast). Decide per note:

- Draw when any holds: three or more components whose relations matter (call, data, or event flow; module wiring; resource dependencies); a procedure of three or more ordered stages; the change adds, removes, or re-wires a node or edge in such a structure.
- Skip when any holds: the change is in one file or one small region; it is mechanical (rename, format, version bump, lockfile, generated files); the structure is two things or a single line that a sentence carries; the picture would only restate the file order the reading map already gives. When unsure, skip.
- The 文脈 diagram is the "before". In the 変更 note draw the "after" and mark additions and changes with ASCII label prefixes `NEW:` / `CHG:`. Only when edges are removed or re-pointed, draw a labelled 変更前 / 変更後 pair in the 変更 note instead (each at most ~15 lines).

**How to draw**

1. Flow or structure → write a mermaid `flowchart` to a scratch file (not the repo) and run `python3 <skill-dir>/scripts/mermaid_to_boxart.py map.mmd`. Keep it to about 7 nodes, short labels, and about 30 lines tall (`[解釈]`; 5 chained nodes already take 27 lines, and the human's pane measured 124 × 59). The layout is top-down only, subgraph borders are not drawn, edges are not de-crossed, and a node with several outgoing edges draws its branch point with `│` where `├` or `┐` belongs (all inherited from crit-explain's script): read the printed art once and simplify the graph if it is hard to follow.
2. Sequence, state, or anything that is not a flowchart → draw it by hand with ordinary spaces in a scratch file, then pass it through `--raw` (same padding, width check, and JSON escaping).
3. Width: when the art is wider than `--max-width` (default 100 display columns) the script exits 2 with the reason on stderr and prints nothing. Split the diagram or cut nodes; do not raise the limit or switch to `--pad space` to get past it. In labels prefer ASCII over `→` and similar East-Asian-ambiguous characters (the script warns).

**How to embed** — run the script with `--json` and paste its single line into the `rationale` string after the outline, a `\n\n`, and the caption line with its `\n`. It already holds `\n` for newlines and `\u2800` for the padding. Do not retype, re-indent, or fence the diagram. Then run `python3 <skill-dir>/scripts/mermaid_to_boxart.py --check .local/hunk/agent-context.json`; it must exit 0 (no ordinary space or code fence on a diagram line, none wider than the limit). A live answer with a diagram (step 5) uses the same fragment inside `comment apply --stdin`.

**Why** (Hunk 0.17.7, `[実測]` in a pseudo terminal at 124 columns):

- Runs of ordinary whitespace collapse to one space and a leading run vanishes, so a space-padded box loses its right border. U+2800 is kept, including at the start of a line.
- `rationale` is not rendered as markdown: `#`, `**`, backticks, and code fences appear as typed.
- In stack layout a note's text is as wide as the window minus 12 columns, so a W-column diagram fits when the window is at least W+12 (100 columns needs 112). In a narrower window the line hard-wraps and the box breaks. The default limit of 100 assumes the human's 124-column pane; for a narrower pane pass `--max-width <pane width − 12>`.
- In split layout notes occupy only the right half (56 text columns at 124), and auto picks split on a wide window (160), so step 4 pins `--mode stack`. The layout is fixed at launch: `hunk session reload` keeps it, and `--mode` on reload does not change it.
- Live comments (`comment add`, `comment apply`) render the same way as sidecar notes.
- Seen by the human (2026-10-25, their terminal): a U+2800-padded box shows its right border as one straight line. Not verified: the width of the box-drawing and arrow glyphs themselves in that terminal's font (the pseudo terminal only checks character cells), and whether Hunk newer than 0.17.7 (0.24.1 exists) behaves the same. After a Hunk upgrade re-measure with `uv run --with pyte python3 <skill-dir>/scripts/check_hunk_render.py` (a private, throwaway Hunk on a temp repo in a pseudo terminal; it never touches the human's session), together with the briefing placement note under Briefing before the diff.

### 4. Host the TUI in a dedicated Herdr tab (default)

When `HERDR_ENV=1`, host the presentation for the user instead of making them launch it:

1. Create a dedicated tab in the current workspace (`herdr tab create`) — the TUI wants the full pane.
2. Name **both** the tab and its pane `hunk-<PR番号|topic>` (`herdr tab rename` / `herdr pane rename`). The user finds it in the sidebar by that name; keep the convention stable across presentations.
3. Run the launch command there: `herdr pane run <pane> "cd <worktree> && EDITOR=nvim hunk diff <target> --mode stack --agent-context .local/hunk/agent-context.json --agent-notes"`. Always launch `hunk` with `EDITOR=nvim` so in-TUI edit actions open nvim (the env is fixed at launch; it cannot be added later via `hunk session ...`). Always pass `--mode stack`: notes then use the full pane width, while split and auto (which picks split on a wide pane) confine them to the right half and hard-wrap the briefing diagrams (see 3b; `[実測]`, Hunk 0.17.7). The layout is fixed at launch too. Do not steal focus — tell the user the tab name instead.
4. From here the session is live: interact only via `hunk session ...` (comments, reload). Never read or drive the TUI pane itself.
5. Start the comment watcher (next section). This is the default, not an option: without it a human comment sits unanswered until the human also says so in chat.

#### Comment watcher (default)

`scripts/watch-user-comments.sh` polls `hunk session comment list --type user --json` every 2s and hands each new human comment to the agent that is presenting. It is a plain script, not an LLM agent: the presenter already holds the context, so it is the one that answers.

- Delivered note ids go in a state file (one per repo, or per `--session <id>`). On the first run, comments that already exist count as seen. A restart reuses the state file, so comments made while no watcher was running still arrive. `--include-existing` clears the state and delivers everything again. Only one watcher runs per state file.
- At startup it retries for about 30s, because the TUI may not have registered with the daemon yet. If several sessions match the repo, it stops and asks for `--session <id>` (see `hunk session list`).
- A failed delivery, e.g. the presenter is `blocked` on a permission dialog, is retried with backoff (up to 30s apart). Nothing is marked delivered until it succeeds. After about 20 minutes of failures it gives up; restart it to resume from the state file.
- When the session is gone, it tells the target and exits.

Pick where it runs by the situation, in this order. Expand `$HERDR_PANE_ID` in the presenter's own shell (double quotes, or paste the literal id): inside the watch pane it would name the watch pane itself, and delivery would never succeed.

| Situation | Where |
|---|---|
| `HERDR_ENV=1` (normal) | a small pane split below the TUI in the `hunk-<PR番号>` tab, named `hunk-<PR番号>-watch` |
| `HERDR_ENV=1` but the split fails (tab too small, etc.) | a background process |
| no Herdr, Claude Code | the harness `Monitor` tool |
| no Herdr, other harness | none: there is no push channel, so tell the user to say in chat when they have commented |

```bash
SCRIPT=<skill-dir>/scripts/watch-user-comments.sh
ARGS="--repo <worktree> --target $HERDR_PANE_ID --label hunk-<PR番号>"   # expands here, in the presenter

# Pane (default). The TUI keeps 90%; the split does not take focus.
WATCH=$(herdr pane split <tui-pane> --direction down --ratio 0.9 --cwd <worktree> \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
herdr pane rename "$WATCH" hunk-<PR番号>-watch
herdr pane run "$WATCH" "$SCRIPT $ARGS"

# Background, only when the split fails. Keep the PID for step 6.
# Spell the arguments out: zsh does not word-split an unquoted $ARGS.
nohup "$SCRIPT" --repo <worktree> --target "$HERDR_PANE_ID" --label hunk-<PR番号> \
  > <scratch>/hunk-watch.log 2>&1 & echo $! ; disown
```

For `Monitor` (no Herdr, Claude Code), run the script **without** `--target`: it prints one line per comment, and `Monitor` turns each line into a notification. Pass `timeout_ms: 1800000` (the default is 5 minutes) and re-arm it when it expires while the presentation is open. Re-arming loses nothing, because the state file carries over.

- `--target` is the presenter's own pane id, not its agent name. Agent names can be lost (`herdr agent list` shows `None`); pane ids do not change.
- The pane keeps the watcher visible and stoppable, and it ends with the tab. Use the background process only when the split is not possible.
- The message arrives in the presenter as a user turn prefixed `[hunk-<PR番号> watcher]`; see 5.
- **Known risk**: `herdr agent prompt` types the text and presses Enter without clearing the input box. If the human has a half-typed message in the presenter pane, the two merge and go out as one turn. This is likely when the presenter is also the agent the human chats with (e.g. a `$herdr-impl` orchestrator). Tell the human about it when you start the watcher.

#### Fix worker spawn contract

When the presentation runs inside a `$herdr-impl` orchestration, **reuse its implementer worker as the fix worker** — no new spawn; the worker keeps its existing pane and receives the brief below. Split a new fix worker *inside the same tab* (below the TUI, e.g. `--ratio 0.7`) only when no implementer worker exists for this PR, so the review surface and its worker travel together. A pane-spawned worker inherits its own `HERDR_PANE_ID`, **not** the hunk pane — it cannot discover the session by itself. The spawn brief MUST therefore include:

- **hunk session selector**: the worktree path to use with `--repo <worktree>` (and the session id from `hunk session list` if several sessions share it)
- **pane topology**: the TUI pane id and tab id (`hunk-<PR番号>`), and that the TUI pane is read/drive-forbidden
- **the user comments** to address: either verbatim, or the instruction to run `hunk session comment list --repo <worktree> --type user` itself
- **who runs 5b**: default is the worker — after push it updates the sidecar anchors, reloads (`hunk session reload --repo <worktree> -- diff <same target> --agent-context .local/hunk/agent-context.json --agent-notes`), and replies on the original comment lines with the commit hash. If the commander keeps 5b, say so explicitly in the brief.
- **watcher target**: the comment watcher keeps notifying the presenter, which relays new comments to the worker. To have the worker receive them directly instead, restart the watcher with `--target <worker pane>` and say so in the brief.

### 4b. Fallback: hand over the launch command (no Herdr)

When `HERDR_ENV` is unset (or the user asks to run it themselves), print the command and let them run it in their terminal:

```bash
EDITOR=nvim hunk diff --mode stack --agent-context .local/hunk/agent-context.json
```

- Add `--agent-notes` when the notes must be visible on open.
- Say in one or two lines what the map covers and where to start reading.
- If a session is already live for this repo (`hunk session list`), do not ask for a relaunch: inject the same notes with one `hunk session comment apply --repo . --stdin` batch, or `hunk session reload --repo . -- diff` first when the loaded content is wrong. That session keeps the layout it was launched with; if it was not launched with `--mode stack`, say so before sending diagrams, since split would wrap them.
- Once the user's session is live, start the comment watcher per the no-Herdr rows of the table in 4.

### 5. Answer questions on Hunk

The main interaction is the human asking and this skill answering, and both sides stay in Hunk. A `[hunk-<PR番号> watcher]` message is the trigger: it carries the file, line, and a body cut at 300 characters, so re-read the full comments with `comment list` before answering.

```bash
hunk session comment list --repo . --type user   # read the human's questions
hunk session comment add --repo . --file <path> (--new-line <n> | --old-line <n>) \
  --summary "<回答>" [--rationale "<根拠>"] [--author "Claude Code"] [--focus]
```

- Read the source before answering; never answer from the diff alone when the answer depends on surrounding code.
- Answer on the line the question was asked about, so the thread reads in place.
- Batch several answers with `comment apply --repo . --stdin`.
- Use `--focus` only when the answer should pull the user's view to it.
- If the human asks for a code change, that is a separate task — hand it to `$tk` (or a worker agent the user designates) rather than editing here.

### 5b. Re-sync after a delegated fix lands

One fix round driven by explicit human comments is part of the presentation, not a convergence loop. When the delegated fix is committed and pushed:

1. Verify the commit changed only what the comment asked (e.g. comment-only diff → zero code lines).
2. Update the sidecar annotations whose `newRange`/`oldRange` shifted — stale anchors silently misplace notes after reload. Re-check the briefing's vault `file:line` citations too when the note was edited.
3. `hunk session reload --repo <worktree> -- diff <same target> --agent-context .local/hunk/agent-context.json --agent-notes`. No `--mode` here: reload keeps the layout the session was launched with (`[実測]`). If a briefing diagram's nodes changed, regenerate it; after any sidecar edit re-run `--harden` and `--check` before reloading.
4. Reply on each original comment line with the commit hash (「削除しました (abc1234)。…」) so the thread closes in place.

A second round of fixes belongs to `$herdr-review-loop`, not here.

### 6. Record the verdict and stop

Close out with one explicit line:

- **approved** — state that the human approved, and what they approved (target + scope). Stop; the next step is theirs to ask for.
- **changes requested** — list the requested changes verbatim, with file and line, as the handoff. Do not start fixing in this skill.
- **no response** — say the presentation is pending review. Do not re-present or poll; leave the comment watcher running, since it is what brings the next comment in. A watcher message that arrives later, while you are on other work, resumes step 5 for that comment.

On **approved** or **changes requested**, stop the comment watcher: `herdr pane close <watch-pane>`, `kill <PID>` for the background process, or stop the `Monitor` task.

## Common errors

`"No active Hunk sessions"`, `"No visible diff file matches …"`, `"Multiple active sessions match"`, and the `--`/target argument errors are all covered in `$(hunk skill path)`. Read it there rather than duplicating the fixes.
