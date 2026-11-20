---
name: pre-review
description: Before the team is asked to review an agent-made branch or PR, show the human the branch once per apply unit. Start a Plannotator review yourself with the gate on (its decision is the verdict), and attach in the Plannotator Inbox an explanation note cut along the commits (what changed, why, where the risk sits, what ran and what did not), saved as a derived note in the vault. Then handle the asynchronous outcome (approved, or annotated) by delegating fixes to the fix worker, re-presenting in a new review session, and recording the verdict in bd. The human-review step of AGENTS.md's Human Review Default and of herdr-impl. Explanation and a verdict, not critique; distinct from review (agent critical review gate). The slash command /plannotator-review is human-only; the agent opens the same screen with the CLI. Use hunk-present only when the human asks for Hunk. Trigger on pre-review, PR を human に見せる, 差分の解説, 解説 md, レビュー前の確認, 人間のレビュー, human review of the diff, Inbox で差分を見せる, plannotator review.
---

# pre-review

Show the human an agent-made change before the team sees it, once per apply unit. An apply unit is the run of commits that one human-gated apply covers (for example one `terraform apply`); with a single apply or none, it is the whole branch. Two surfaces carry it. A Plannotator review you start yourself, with the gate on, holds the diff, the line comments, and the `decision` that is the verdict. An explanation note in the Inbox, cut along the commits, gives the background the diff does not carry. Nothing waits in the chat: start the review, send the note, then keep working or end the turn.

## Core principles

- **Explain and ask for a verdict; do not critique.** Say what each chapter changes, why, and what it implies. Hunting for defects is `$review`. Mention a bug you happen to see, but do not go looking.
- **Start the review yourself, with the gate on.** The slash command `/plannotator-review` is human-only (model invocation is disabled), but the same screen opens from the CLI: `plannotator review --git --base <sha> --gate --json`. The `plannotator` tool (`action: review`, `gate: true`) sets the compare base only, so use the CLI when you need to choose the diff type.
- **The gate's `decision` is the verdict.** It is `approved`, `annotated`, or `dismissed`. Classify by `decision`, never by the `message` text. Notes on an approval are guidance, not a change request. The explanation carries no verdict question.
- **A session ends when the human submits.** After `annotated`, present again in a new session with a new URL. A running session can keep showing the old diff until it is reloaded, so do not re-stage, commit, or push the presented branch while the human reviews (other worktrees and later work go on); if you must, say exactly what changed and ask for a reload, and record that the viewed version is unconfirmed.
- **The explanation does not depend on the screen.** You cannot see the human's screen. The explanation is a markdown note and an HTML drill-down (step 3b), both attached in the Inbox and saved in the vault, because Inbox data is not versioned.
- **Guided review is not the default.** Use `get_guide_brief` and `submit_guide` only when the human asks for a guided review in the Inbox. Hunk is optional too: use `$hunk-present` only when the human asks for Hunk.
- **Never edit source here.** Fixes go to the fix worker (step 5). This skill writes the note, the message, and Inbox replies.
- **The presenter owns the Inbox thread and `bd`.** Workers never post to the Inbox or write `bd`; the presenter relays.
- **Japanese plain prose.** Write the note and the message in plain Japanese. Keep identifiers, paths, and commands verbatim. Short sentences, no em-dash or `--` standing in for one, no emoji, no selling words.
- **No secrets.** Do not copy tokens, keys, or credential-like strings into the note or message. If the diff itself contains one, stop and tell the human instead of presenting.

## Preconditions

1. The commit plan was agreed before coding (AGENTS.md, Human Review Default), and the branch is groomed per `$commit`'s pre-PR grooming contract (semantic-unit commits, English subjects). Groom before presenting, so the note never goes stale because of a history rewrite. The chapters follow these commits.
2. Everything in the presented range is committed, and HEAD is pushed when a PR exists. Unrelated uncommitted or untracked files may remain in the worktree; never stage them. Start the review with `--diff-type branch` so the screen shows only the committed range, not the uncommitted work.
3. A PR may or may not exist. When a draft PR exists (via `$join`), present it. When none exists yet, present the branch; the PR is created after the verdict, when the work calls for one.
4. The `plannotator` CLI is on `PATH`, and an Inbox route exists: the `plannotator_inbox` tool (in Claude Code `mcp__plannotator__plannotator_inbox`, possibly deferred behind tool search) or the CLI. Read `plannotator inbox --help` once before the first send of the session.

## Workflow

### 1. Fix the target

Run every git command against the worktree (`git -C <worktree>`): on the `$herdr-impl` path the presenter's cwd is not the worktree.

```bash
W=<worktree>
git -C "$W" status --short                              # precondition 2: every file of the range is committed; unrelated entries may remain
BASE=$(cd "$W" && gh pr view <N> --json baseRefName -q .baseRefName)
# no PR: BASE=$(cd "$W" && gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git -C "$W" fetch origin "$BASE"
MB=$(git -C "$W" merge-base "origin/$BASE" HEAD)
git -C "$W" rev-parse HEAD                                               # the head this review shows; keep it
git -C "$W" log --reverse --name-status --format='%n%h %s' "$MB"..HEAD   # which commit touches which file
git -C "$W" log --reverse --format='%h %s%n%b' "$MB"..HEAD               # the why, from the commit bodies
```

Use the merge-base, never a two-dot snapshot against the moving base: a snapshot shows the base's later commits as reversed deletions. For the first unit, `$MB` is the base. For a later unit, use in its place the head that the previous unit's review ended at (the verdict's `bd` note records it), and put the unit in the review title and in the note's `<topic>`. The commit plan names which rows belong to which unit; the unit ends at the HEAD you present.

### 2. Start the review

```bash
cd "$W" && plannotator review --git --base "$MB" --diff-type branch --title "<bd id> <topic>" --gate --json > <scratch>/review.out 2>&1
```

- Run it in the background with the longest timeout. In Claude Code, pass `run_in_background` with `timeout: 7200000`; a background command is stopped after 30 minutes otherwise. Do not kill it to "finish" a review: a session that ends without a decision reads as no feedback.
- Read the session URL from the first output line (or `plannotator sessions`) and put it in the note and the message.
- The decision arrives when the process exits, as `{ "decision": ..., "message": ... }`. Where the harness does not wake you on process exit, read `<scratch>/review.out` when the human replies in the Inbox.
- Before opening, check that the diff is the one you mean: `git -C "$W" diff --stat "$MB"` against the commit plan. The human can widen the scope on the screen, so a comment may concern a file outside the branch.

### 3. Write the explanation note

Save it as a derived note in the vault root, named `<bd id>--<topic> diff解説.md`, with `bd_issue_id` in its frontmatter. The vault root is the cwd when it contains `.obsidian/`, else `DESK_VAULT` (a legacy name) when set, else ask the human once. Layout:

1. **位置と目的.** The review session URL at the top. Which commits, in what order, and which chapter is the heart or carries the risk. A reader who stops here has not been misled.
2. **背景.** Why the change exists. Cite the vault note that holds the context (the plan note `<bd id>--<topic> plan.md` first) as `<note>.md:L<n>` (path relative to the vault root), or say no note covers it.
3. **章.** One chapter per commit, or per run of commits with one reason; never put two purposes in one chapter. Each chapter gives:
   - the commit (`abc1234`) and its place in the sequence (6 件中 3 件目), so the human can open that commit alone;
   - what changed, why (the non-obvious decision and its alternative), and what it implies for behavior, contracts, or operations. **Say plainly where the risk concentrates.** Use `> [!WARNING]` or `> [!IMPORTANT]` only for a real behavior or contract shift;
   - the one to three concepts a reader meets for the first time here, with the reader as the subject;
   - what the chapter leaves out and which chapter carries it;
   - a `mermaid` diagram where the structure, flow, or order is easier to see than to read.
   Never cut or merge chapters by how many new concepts they hold: a chapter heavy with them gets a thicker explanation. Order the chapters by importance (the heart first, then consequences, glue last); when that differs from the commit order, name each chapter's commit so the commit order can still be followed.
4. **検証の状況.** Which commands ran and passed, what was not run, and when each unverified item will be checked.
5. **仮値・[解釈]・未確認.** Do not fill a gap by guess. Take the "why" from the commit bodies and the PR body; when none records it, say the why is not recorded. Mark your own inference `[解釈]`, write 未確認 for what the diff and commits cannot confirm, and flag a value with no precedent in the repo (a retention period, a timeout) as 仮値 so the human can overturn it.

Disclose in layers, each complete alone: the message gives the order and where the heart and the risk sit; the note's top gives the position and purpose; each chapter gives what, why, and implications for one unit; the diff on the review screen gives the detail. A deeper layer adds detail instead of repeating the one above.

### 3b. Write the drill-down HTML

For now the explanation is both files: the markdown note and this HTML (the human's default of 2026-11-21; they will decide later whether to keep one). The HTML carries the same facts, so the reader can go from the idea to the code to what the code means, opening each step as needed. A reference example is `aws-iac-ir.9.3--S6-H2 diff ドリルダウン.html` in the vault, with its generator in `.local/review-gate/html-drilldown/` (not versioned). Save yours in the vault root as `<bd id>--<topic> diff ドリルダウン.html`, with the same `bd_issue_id` in a comment at its top.

- One self-contained file: CSS and JS inline, no external request.
- Open with an overview a cold reader can stand on (`$reader-first`): what the change is for, the question it answers, one worked example marked as an illustration, a table of what is added, how the chapters map to the overview, what the change does not do, how to read the page. A one-paragraph opening is too thin.
- One chapter per commit, as in the note. Mark the chapters that fix permissions or contracts.
- Each step has three layers, opened on demand: the idea (why this is written), the code excerpt (lines added by the commit marked; a line with an annotation opens its meaning on click), and what the code means (key points, terms met for the first time, what was checked).
- Take excerpts from git (`git show <sha>:<file>`, added lines from `git diff -U0`). Find each annotated line by a substring match in the excerpt and stop generating when it is not found, so annotation and code do not drift. The annotation text is written by hand; do not automate it.
- Say what each "checked" line covers: a local check must not read as a real run. End with what is not verified.
- Controls: reading depth (idea only, idea and code, all), open or close all, a "read" mark (localStorage), `j` and `k`, chapter navigation.
- Before attaching: open it in headless Chrome and check for JS errors and that every chapter link works; scan for 12-digit numbers (account IDs) and secrets; look at it in the dark theme. The light theme and how the Inbox shows an attached HTML (sandbox, localStorage) are unconfirmed: say so in the message.

### 4. Send

- **Thread**: one thread per work stream. If this work already has a thread (the task's thread, or the one the human or the Mayor routed it through), call `read_thread` first and `reply_to` its latest message. Otherwise start one with `subject` and a short `thread` name. If an older guided review (`submit_guide`) question is still open in that thread, send the new message with `supersedes` (`<message id>/<question id>`) so it closes.
- `send_message` with the note and the HTML in `attachments` (absolute paths). The body is short Japanese, and its first line is the next step for the human (「次の一手: review の画面で Approve するか、コメントを付けて送信してください: <URL>」), because the human may read only that line:
  1. Which branch or PR, the review session URL, and the chapter order with the commits each chapter comes from, saying which chapter is the heart or carries the risk.
  2. Where the verdict goes: 「review の画面で Approve するか、コメントを付けて送信してください。解説は添付のノートです」. Name the real next step an approval triggers (for example: draft を外す; with no PR: PR を作る, or ブランチを引き渡す on the `$herdr-impl` path, where the human opens the PR). Merge always stays with the human.
  3. Context the human may lack, and where the note's 仮値 and 未確認 items are.
  Do not put a verdict `:::question` in the message: the gate's `decision` is the one entrance.
- **Add the PR to the thread** (skip with no PR): `thread_pulls` with `thread_id` and `add: ["owner/repo#N"]`, once, when the PR is first presented.
- Keep the message id and thread id. Then end the turn or go on with other work. Do not poll, and send no timed reminder: a gate can stay open for hours. When the human writes meanwhile, in the chat or in the Inbox thread, end your answer with one line that the review waits and its session URL; do not ask the verdict again in the chat.

### 5. Handle the outcome

The outcome arrives as the process exit (`decision`) and as an Inbox reply (`Plannotator Inbox: <title> (<reply id>)`; questions and annotations on the attached note come back there). Read the whole thread with `read_thread` before acting.

- **`approved`**: confirm that every comment is answered and that HEAD is the head you presented (if it moved after the human opened the session, record that the viewed version is unconfirmed). Record the verdict (step 6) and do only the next step the message named.
- **`annotated`**: the message lists the comments. When the human asked for verdicts before any change, give them first: for each comment, Confirmed / Partly / Not a bug / Intended, with short evidence, and whether this change introduced it, it was already there, or it is deliberate scope. A comment can concern a file outside the branch: answer with the fact and change nothing unless asked. Change code only when the human agrees or the comment is an explicit change request: then delegate the fix (contract below) and present again.
- **A question about the note**: read the source, then answer with `reply_to` the reply id in the same thread.
- **`dismissed`, or no response**: the review is pending. Do not re-send or poll. After a resume or a compaction call `read_thread` with no id and check the thread's unread state before reporting "pending".

#### Fix worker spawn contract

- **Who**: on the `$herdr-impl` path, reuse its implementer `<PFX>-worker` in its existing pane; do not spawn a new fixer. Otherwise use a sub-agent or codex; never open a new Claude pane for it.
- **The brief must include**: the worktree path and branch; each comment verbatim with its file and line; the scope (only what the comments ask); `$commit` discipline (fold each fix into the semantic commit it belongs to with fixup and autosquash, English subjects, a validation signal before committing); an explicit push authorization for this step only (`git push --force-with-lease`); the bans (no PR creation, no merge, no `bd` writes, no Inbox posts, no bd id in code or commits); and the report wanted (commit hashes, validation commands and results).
- **After the push** (the presenter does this): record the old head (from step 1) and the new head. Verify that the fix changed only what the comments asked with `git -C <worktree> diff <old-head> <new-head>` and `git -C <worktree> range-diff <MB>..<old-head> <MB>..<new-head>`. Start a new review session on the same base (the old one ended on submit), update the note (every chapter the fix touched, and the session URL), and send it with `reply_to` the human's reply id. The message lists each comment with what changed and the semantic commit it landed in, the old head and the new head, and the new URL.
- Each fix round follows a human reply. Do not loop on your own; agent-found defects belong to `$review` or `$herdr-review-loop`.

### 6. Record the verdict

Record one explicit entry in the `bd` issue with `bd update <id> --append-notes` (AGENTS.md, Task State), or in the chat when nothing tracks the work.

- **approved**: who approved, what (the unit, the PR ref, and the head commit, which is the next unit's base), and the next step taken.
- **changes requested**: each request verbatim with file and line, and the fix round it went into.
- **pending**: the review was started; the thread (project / thread name / message id); the head commit it shows.
