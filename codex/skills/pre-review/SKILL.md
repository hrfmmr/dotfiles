---
name: pre-review
description: Before the team is asked to review an agent-made PR or branch, send the human a Plannotator Inbox guided review (get_guide_brief then submit_guide) - the exact merge-base patch plus importance-ordered chapters that explain what changed, why, and where the risk sits - then handle their asynchronous reply (approve, or comments on chapters and lines) by delegating fixes to the fix worker, re-sending a fresh guide in the same thread, and recording the verdict. The default human-review step of desk and herdr-impl. Explanation and a verdict, not critique - distinct from review (agent critical review gate) and from plannotator-review (a command only the human runs; never invoke it). Use hunk-present instead only when the human asks for Hunk. Trigger on pre-review, PR を human に見せる, 差分の解説, guided review, レビュー前の確認, 人間のレビュー, human review of the diff, Inbox で差分を見せる, ガイド付きレビュー, submit_guide.
---

# pre-review

Show the human an agent-made change before the team sees it. The surface is a guided review in the Plannotator Inbox: the diff, cut into chapters, each with a short explanation. The human reads it when they can and answers in the Inbox. Nothing blocks: send, then keep working or end the turn. The Inbox help discourages blocking sign-offs on a diff; this one is a non-blocking verdict the human asked for (2026-11-13), which is why `submit_guide` is the right tool here.

## Core principles

- **Explain and ask for a verdict; do not critique.** Say what each chapter changes, why, and what it implies. Hunting for defects is `$review`. Mention a bug you happen to see, but do not go looking.
- **Never run `/plannotator-review`.** It is a command the human invokes (model invocation is disabled, and it blocks on a browser UI). The agent path is `submit_guide` only.
- **Hunk is optional, not the default.** Use `$hunk-present` only when the human asks for Hunk.
- **Never edit source here.** Fixes go to the fix worker (step 6). This skill writes the guide, the body, and Inbox replies.
- **The presenter owns the Inbox thread.** Workers never post to the Inbox, bd, or task notes; the presenter relays.
- **Japanese plain prose.** Write `title`, `intent`, overviews, file summaries, and `body` in plain Japanese. Keep identifiers, paths, and commands verbatim. The brief's voice rules still apply to the guide: short sentences, no em-dash or `--` standing in for one, no emoji, no selling words.
- **No secrets.** Do not copy tokens, keys, or credential-like strings into the guide or body. If the patch itself contains one, stop and tell the human instead of sending.

## Preconditions

1. The branch is groomed per `$commit`'s pre-PR grooming contract (semantic-unit commits, English subjects). Groom before sending, so the guide never goes stale because of a history rewrite.
2. The worktree is clean (`git status --porcelain` is empty) and HEAD is pushed when a PR exists. `git diff <merge-base>` includes uncommitted edits, so a dirty tree sends a patch that differs from the PR.
3. A PR may or may not exist. When a draft PR exists (via `$join`), present it. When none exists yet (the `$herdr-impl` path leaves PR creation to the human; desk creates it with `$join` only after the verdict), present the pushed branch and follow the no-PR notes in steps 1, 3, 4, and 5.
4. An Inbox route exists: the `plannotator_inbox` tool (in Claude Code `mcp__plannotator__plannotator_inbox`, possibly deferred behind tool search) or the `plannotator` CLI. Read `plannotator inbox --help` once before the first send of the session.

## Workflow

### 1. Fix the target and make the patch

Run every git command against the worktree (`git -C <worktree>`): on the `$herdr-impl` path the presenter's cwd is not the worktree.

```bash
W=<worktree>
test -z "$(git -C "$W" status --porcelain)"              # precondition 2
BASE=$(cd "$W" && gh pr view <N> --json baseRefName -q .baseRefName)
# no PR: BASE=$(cd "$W" && gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git -C "$W" fetch origin "$BASE"
MB=$(git -C "$W" merge-base "origin/$BASE" HEAD)
git -C "$W" rev-parse HEAD                                # the head this guide shows; keep it
git -C "$W" diff "$MB" > <scratch>/pr-<N>.patch           # send exactly this as `patch`
git -C "$W" diff --name-only "$MB"                        # the coverage set
```

Use the merge-base, never a two-dot snapshot against the moving base: a snapshot shows the base's later commits as reversed deletions. Keep the patch file; step 6 makes a new one per round.

### 2. Read the brief

Call `get_guide_brief` (no arguments). Its `methodology`, `output_schema`, `diff_steps`, and `rules` are the authority on the guide's shape and coverage. This skill adds the ordering emphasis, the Japanese prose, the body, and the reply handling.

### 3. Build the guide

- Read the patch once, `gh pr view <N>` (title and body), and `git log --oneline "$MB"..HEAD`. Look up a definition or a call site only when a chapter's "why" needs it.
- **Order chapters by importance.** This is the reading map of `$hunk-present`, recast as chapters:
  1. The heart first: the dependency root or the place where behavior changes, the part that unlocks the rest.
  2. Then consequences in decreasing signal: callers, downstream logic. Tests go in the chapter of the code they exercise.
  3. Glue last, in one plainly titled chapter (配線と設定, 細かな整理): wiring, imports, renames, config, lockfiles, generated files.
- A chapter is a logical unit, not a file. Several files with one reason form one chapter; one file with two unrelated changes is split.
- Each overview says what changed, why (the non-obvious decision and its alternative), and what it implies for behavior, contracts, or operations. **Say plainly where the risk concentrates** (本番の応答が変わるのはこの章です). Use `> [!WARNING]` or `> [!IMPORTANT]` only for a real behavior or contract shift.
- Carry the verification status: in the tests chapter (or the last chapter when there are no tests), say which commands ran and passed, what was not run, and when each unverified item will be checked.
- Coverage is a hard rule: every changed file appears exactly once, in one chapter's `diffs[].file` (copied exactly from the patch) or in `unplacedFiles`. Prefer the glue chapter over `unplacedFiles`.
- `title`: the PR title with its ref (`owner/repo#N`); with no PR, a title from the commits plus the branch name. `intent`: one or two sentences on why the change exists.
- Add `review` (`{"gitRef": "origin/<base>...HEAD", "base": "origin/<base>"}`) and `generator` (`{"engine": "<harness>", "model": "<model id>"}`) as in the brief's example.

### 4. Write the body

The body is the note above the card, in Japanese, kept short:

1. One or two lines: which PR, the chapter order, and which chapter is the heart or carries the risk.
2. Context the human may lack: where this sits in the larger work. Cite the vault note that holds it as `<note>.md:L<n>` (path relative to the vault root), or say no note covers it.
3. The verdict request as one `:::question` block (choices in natural order; a `Recommended:` line only if you have one, never first):

```markdown
:::question
この PR を、このままチームのレビューに出してよいですか。

章や行へのコメントは、どちらを選んでも返事に載ります。

- [ ] このままでよい — draft を外し、レビューの依頼に進みます
- [ ] 直す点がある — 章や行へのコメントで知らせてください。直して、もう一度解説を送ります
:::
```

Name the real next step in the first choice (for example: draft を外す, Mayor にレビュー依頼の文面を頼む; with no PR: PR を作る on the desk path, or ブランチを引き渡す on the `$herdr-impl` path, where the human opens the PR). Merge always stays with the human.

When the 文脈 is a structure of three or more parts whose relations matter, a small fenced `mermaid` diagram may go in the body; skip it otherwise.

### 5. Send

- **Thread**: one thread per work stream. If this work already has a thread (the task's thread, or the one the human or the Mayor routed it through), call `read_thread` first and `reply_to` its latest message. Otherwise start one with `subject` and a short `thread` name.
- **Build the call with `jq`, never by hand.** Pasting or hand-escaping a diff corrupts it. Write the guide to `<scratch>/guide.json` and the body to `<scratch>/body.md`, then:

```bash
jq -n --slurpfile guide <scratch>/guide.json --rawfile patch <scratch>/pr-<N>.patch \
      --rawfile body <scratch>/body.md --arg reply_to <msg id> --arg project_path <abs path> \
      '{guide: $guide[0], patch: $patch, body: $body, reply_to: $reply_to, project_path: $project_path}' \
  > <scratch>/pr-<N>-guide-call.json
plannotator inbox call submit_guide - < <scratch>/pr-<N>-guide-call.json   # check the exit code
```

  For a new thread use `subject` and `thread` instead of `reply_to`. The CLI keeps the reply routed to the calling session. If it fails with `session_ambiguous` (a shell started inside another agent), pass `--session` as the help's Scripting section says; never drop it. The `plannotator_inbox` tool (`action: "submit_guide"`) takes the same fields and is fine only when the patch is small enough to pass through intact.
- `invalid_guide: …` names the file that does not match: fix that path or its placement and send again. A refused send posts nothing.
- **Add the PR to the thread** (skip with no PR): `thread_pulls` with `thread_id` and `add: ["owner/repo#N"]` (or `plannotator inbox pulls add <thread> <ref>`), once, when the PR is first presented.
- Keep the result's message id and thread id; step 6 needs them. Then end the turn or go on with other work. Do not poll. When the human writes in the chat meanwhile, say the guide waits in the Inbox (one line and the thread link); do not ask the verdict in the chat.

### 6. Handle the reply

The reply arrives as `Plannotator Inbox: <title> (<reply id>)`. Read the whole thread with `read_thread` before acting; the reply carries the human's words, the answer to the verdict question, and any comments on chapters and lines (they appear as feedback or annotations in the reply; read them from `read_thread`, since their exact format is not documented).

- **このままでよい**: record the verdict (step 7) and do only the next step the chosen option named.
- **A question, not a change request**: read the source, then answer with `reply_to` the reply id in the same thread.
- **直す点がある**: delegate the fix (contract below), then re-present.
- **No reply**: the review is pending. Do not re-send or poll. Some clients get one wake or none, so after a resume or a compaction call `read_thread` with no id and check the thread's unread state before reporting "pending".

#### Fix worker spawn contract

- **Who**: on the `$herdr-impl` path, reuse its implementer `<PFX>-worker` in its existing pane; do not spawn a new fixer. Otherwise use a sub-agent or codex; never open a new Claude pane for it.
- **The brief must include**: the worktree path and branch; each comment verbatim with its chapter, file, and line; the scope (only what the comments ask); `$commit` discipline (fold each fix into the semantic commit it belongs to with fixup and autosquash, English subjects, a validation signal before committing); an explicit push authorization for this step only (`git push --force-with-lease`); the bans (no PR creation, no merge, no bd or task-note writes, no Inbox posts, no bd id in code or commits); and the report wanted (commit hashes, validation commands and results).
- **After the push** (the presenter does this): record the old head (from step 1) and the new head. Verify that the fix changed only what the comments asked with `git -C <worktree> diff <old-head> <new-head>` and `git -C <worktree> range-diff <MB>..<old-head> <MB>..<new-head>` (after autosquash no commit stands for one comment). If a vault note cited in the body changed, re-check those `file:line` citations. Repeat step 1 for a fresh patch; rebuild the guide, updating every overview the fix touched; send it with `submit_guide`, `reply_to` the human's reply id, and a body that lists each comment with what changed and the semantic commit it landed in, the old head and the new head, plus a fresh verdict question. Put your own questions in that thread that are still open (read_thread state `open` or `picked`) in `supersedes`; an answered question is refused there, so leave it out.
- Each fix round follows a human reply. Do not loop on your own; agent-found defects belong to `$review` or `$herdr-review-loop`.

### 7. Record the verdict

Record one explicit line wherever the work is tracked: the desk note through its Event Gate (Turn plus bd sync), or a bd comment on the `$herdr-impl` path, or the chat when nothing tracks it.

- **approved**: who approved, what (PR ref and head commit), and the next step taken.
- **changes requested**: each request verbatim with file and line, and the fix round it went into.
- **pending**: the guide was sent; the thread link; the head commit it shows.
