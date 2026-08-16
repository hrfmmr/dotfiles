---
name: hunk-present
description: Present a locally agent-generated changeset to a human in Hunk and get their approval. Builds a dependency-ordered reading map as an `--agent-context` sidecar JSON (changeset summary, per-file roles, numbered `1.)` line annotations), hosts the TUI for the user in a dedicated Herdr tab named hunk-PR番号 (the default; falls back to handing over the launch command when Herdr is unavailable), then answers their questions as inline Hunk comments, re-syncs the session after a delegated fix lands (sidecar anchors, reload, in-place replies), and records the approval verdict. Explanation and approval, not critique; never reads or drives the TUI itself. Use when the user says "/hunk-present", wants a change presented or explained in Hunk, wants a reading map or walkthrough of agent-written changes, or wants human sign-off on a local diff before moving on. Trigger on hunk で提示, hunk で解説, 変更の読み方を示して, human approval, 承認をもらう, agent-context sidecar, reading map, herdr pane で提示.
---

# hunk-present

Present a changeset that a coding agent just produced so a human can understand it and approve it. Hunk is the presentation surface: the reading map lives in the diff view, and the human's questions get answered there too.

## Core principles (non-negotiable)

- **Explain and get approval, don't critique** — state WHAT each change does and WHY it exists so the human can judge it. Hunting for defects is `$review` / `$difit-review` territory.
- **The TUI belongs to the user — never read or drive it** — do not interact with a running `hunk` TUI (no keystrokes, no pane reads of its screen). Launching is a different matter: the default is to *host* the TUI for the user in a dedicated Herdr tab & pane (see 4). Only when no Herdr session is available (`HERDR_ENV` unset) fall back to printing the launch command for the user to run themselves. Never run the TUI in your own pane or consume it as your own output.
- **Sidecar first** — the normal entry point is a prewritten `--agent-context` JSON, because presentation happens before any session exists. Only touch `hunk session ...` once a live session is confirmed.
- **Reading map is mandatory** — always produce a changeset-level summary, a one-line role for every changed file, and numbered `1.) 2.) 3.) …` annotations in dependency order. Never an unordered pile of notes.
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

### 3. Write the sidecar

Write to `<repo-root>/.local/hunk/agent-context.json` (create the directory; confirm `.local/` is ignored by git before writing).

**Sidecar order is display order.** Hunk reorders the diff files to match `files[]`, so listing files in dependency order makes the on-screen order the reading order. Number the annotation summaries `1.)`, `2.)`, `3.)` … in that same order — ASCII prefixes stay greppable and typable.

Schema:

| Field | Required | Meaning |
| --- | --- | --- |
| `version` | yes | `1` |
| `summary` | yes | changeset-level overview shown above the diff — background, shape of the change, key points, reading order |
| `files[].path` | yes | repo-relative path, matching the diff |
| `files[].summary` | yes | one-line role of this file in the change |
| `files[].annotations[]` | no | inline notes for this file |
| `annotations[].newRange` | one of | `[start, end]` 1-based inclusive lines on the new side |
| `annotations[].oldRange` | one of | `[start, end]` on the old side, for deleted lines |
| `annotations[].summary` | yes | the note body, prefixed `N.)` |
| `annotations[].rationale` | no | the WHY behind the note |
| `annotations[].author` | no | attribution label, e.g. `"Claude Code"` |

```json
{
  "version": 1,
  "summary": "## 背景\n…\n\n## 変更の全体像\n…\n\n## 読む順番\n1.) 前提 → 3.) 中心 → 5.) 呼び出し側",
  "files": [
    {
      "path": "src/normalize.ts",
      "summary": "クエリ正規化を一箇所に集約する土台。",
      "annotations": [
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

- Do not copy secrets, tokens, keys, or credential-like material from the diff into the sidecar or any command line.
- Keep every `path` exactly as the diff reports it; unmatched paths silently lose their notes.

### 4. Host the TUI in a dedicated Herdr tab (default)

When `HERDR_ENV=1`, host the presentation for the user instead of making them launch it:

1. Create a dedicated tab in the current workspace (`herdr tab create`) — the TUI wants the full pane.
2. Name **both** the tab and its pane `hunk-<PR番号|topic>` (`herdr tab rename` / `herdr pane rename`). The user finds it in the sidebar by that name; keep the convention stable across presentations.
3. Run the launch command there: `herdr pane run <pane> "cd <worktree> && EDITOR=nvim hunk diff <target> --agent-context .local/hunk/agent-context.json --agent-notes"`. Always launch `hunk` with `EDITOR=nvim` so in-TUI edit actions open nvim (the env is fixed at launch; it cannot be added later via `hunk session ...`). Do not steal focus — tell the user the tab name instead.
4. From here the session is live: interact only via `hunk session ...` (comments, reload). Never read or drive the TUI pane itself.

#### Fix worker spawn contract

When the presentation runs inside a `$herdr-impl` orchestration, **reuse its implementer worker as the fix worker** — no new spawn; the worker keeps its existing pane and receives the brief below. Split a new fix worker *inside the same tab* (below the TUI, e.g. `--ratio 0.7`) only when no implementer worker exists for this PR, so the review surface and its worker travel together. A pane-spawned worker inherits its own `HERDR_PANE_ID`, **not** the hunk pane — it cannot discover the session by itself. The spawn brief MUST therefore include:

- **hunk session selector**: the worktree path to use with `--repo <worktree>` (and the session id from `hunk session list` if several sessions share it)
- **pane topology**: the TUI pane id and tab id (`hunk-<PR番号>`), and that the TUI pane is read/drive-forbidden
- **the user comments** to address: either verbatim, or the instruction to run `hunk session comment list --repo <worktree> --type user` itself
- **who runs 5b**: default is the worker — after push it updates the sidecar anchors, reloads (`hunk session reload --repo <worktree> -- diff <same target> --agent-context .local/hunk/agent-context.json --agent-notes`), and replies on the original comment lines with the commit hash. If the commander keeps 5b, say so explicitly in the brief.

### 4b. Fallback: hand over the launch command (no Herdr)

When `HERDR_ENV` is unset (or the user asks to run it themselves), print the command and let them run it in their terminal:

```bash
EDITOR=nvim hunk diff --agent-context .local/hunk/agent-context.json
```

- Add `--agent-notes` when the notes must be visible on open.
- Say in one or two lines what the map covers and where to start reading.
- If a session is already live for this repo (`hunk session list`), do not ask for a relaunch: inject the same notes with one `hunk session comment apply --repo . --stdin` batch, or `hunk session reload --repo . -- diff` first when the loaded content is wrong.

### 5. Answer questions on Hunk

The main interaction is the human asking and this skill answering, and both sides stay in Hunk:

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
2. Update the sidecar annotations whose `newRange`/`oldRange` shifted — stale anchors silently misplace notes after reload.
3. `hunk session reload --repo <worktree> -- diff <same target> --agent-context .local/hunk/agent-context.json --agent-notes`.
4. Reply on each original comment line with the commit hash (「削除しました (abc1234)。…」) so the thread closes in place.

A second round of fixes belongs to `$herdr-review-loop`, not here.

### 6. Record the verdict and stop

Close out with one explicit line:

- **approved** — state that the human approved, and what they approved (target + scope). Stop; the next step is theirs to ask for.
- **changes requested** — list the requested changes verbatim, with file and line, as the handoff. Do not start fixing in this skill.
- **no response** — say the presentation is pending review. Do not re-present or poll.

## Common errors

`"No active Hunk sessions"`, `"No visible diff file matches …"`, `"Multiple active sessions match"`, and the `--`/target argument errors are all covered in `$(hunk skill path)`. Read it there rather than duplicating the fixes.
