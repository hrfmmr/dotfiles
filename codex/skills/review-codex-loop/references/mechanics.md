# Mechanics: gh / GraphQL commands for review-codex-loop

`CODEX_BOT = chatgpt-codex-connector[bot]`. Resolve `OWNER/REPO` and `PR` once.

> **Bot login differs by API surface — a poll footgun.** REST (`gh api …/pulls/{pr}/reviews`,
> `…/issues/{pr}/comments`) reports `.user.login == "chatgpt-codex-connector[bot]"` (WITH `[bot]`).
> GraphQL (`gh pr view --json reviews`) reports `.author.login == "chatgpt-codex-connector"` (NO
> `[bot]`). All snippets here use **REST with the `[bot]` form** — keep it that way. If you ever
> filter via GraphQL, drop `[bot]`. Two mistakes silently miss the approval (which arrives as an
> **issue comment**, not a review): (1) polling `reviews` only, and (2) using the wrong login form.
> Always query `issues/{pr}/comments` too, with the exact `[bot]` login.

```sh
# From inside the repo/worktree:
PR=$(gh pr view --json number --jq .number)            # or take from arg
read -r OWNER REPO < <(gh repo view --json owner,name --jq '.owner.login+" "+.name')
ME=$(gh api user --jq .login)                          # to exclude self-authored replies
```

## 0. Cycle-0 sweep (loop entry, every (re)start)

Before posting any trigger, sweep existing bot activity — marking a PR ready-for-review may itself
auto-trigger a Codex review, so findings/verdicts can predate the loop:

```sh
BOT='chatgpt-codex-connector[bot]'
# Latest bot verdict comment (may already be an approval for the current head):
gh api "repos/$OWNER/$REPO/issues/$PR/comments" \
  --jq "[.[]|select(.user.login==\"$BOT\")]|max_by(.id)|{id,created_at,body}"
# All unresolved bot threads (same GraphQL as §6) → triage them as cycle-0 findings.
```

If either surface has unhandled bot output, handle it (steps 3/4) WITHOUT posting a new trigger.

## 1. Request review

Capture baselines **BEFORE** posting the trigger — capturing after is a race: a fast bot response
lands at/below the baseline and is silently skipped by §2's `>` filters (false timeout).

```sh
BASE_REVIEW_ID=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" --jq '[.[].id]|max // 0')
BASE_ISSUE_ID=$(gh api "repos/$OWNER/$REPO/issues/$PR/comments" --jq '[.[].id]|max // 0')
TRIGGER_URL=$(gh pr comment "$PR" --body "@codex review")   # returns the comment URL
TRIGGER_TS=$(date +%s)
```

## 2. Wait for the Codex response (canonical bounded poll script)

Codex answers in one of two shapes: a **review** with inline comments (findings), or an **issue
comment** verdict (`Codex Review: Didn't find any major issues.`). Watch both. The waiter is ONE
canonical script, bounded to well under 10 minutes per run, that always exits with an explicit
terminal status line — `RESPONSE`, `TIMEOUT`, or `PENDING` (budget not yet elapsed; re-arm):

```sh
BOT='chatgpt-codex-connector[bot]'
DEADLINE=$((TRIGGER_TS + 1200))     # 20-min wall-clock budget, anchored to the trigger
for _ in $(seq 1 8); do             # ~60s * 8 ≈ 8 min per arm (stays under fg/bg caps)
  NEW_REVIEWS=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" \
        --jq "[.[]|select(.id>$BASE_REVIEW_ID and .user.login==\"$BOT\")]")
  NEW_ISSUES=$(gh api "repos/$OWNER/$REPO/issues/$PR/comments" \
        --jq "[.[]|select(.id>$BASE_ISSUE_ID and .user.login==\"$BOT\")]")
  if [ "$NEW_REVIEWS" != "[]" ] || [ "$NEW_ISSUES" != "[]" ]; then echo RESPONSE; exit 0; fi
  if [ "$(date +%s)" -ge "$DEADLINE" ]; then echo TIMEOUT; exit 0; fi
  sleep 60
done
echo PENDING
```

Keep ALL new bot reviews as an array — do not `max_by(.id)`: an auto-triggered review and the
cycle's response can land in the same window, and taking only the max silently drops threads.

**How to run the waiter (harness-dependent):**

- **Claude Code (agent/subagent)**: launch the script with Bash `run_in_background: true`. The tool
  result returns a task ID — that is your launch receipt (quote it when yielding; see the SKILL.md
  launch-receipt rule). **Do not rely on being auto-re-invoked when the script exits** — that is
  unreliable (a script can exit with RESPONSE while you go idle with `no active task`, no progress,
  no notification). Instead, yield a *waiting checkpoint* (the task ID + the run-state path) so the
  **main agent** drives re-entry (SKILL.md Execution model: it schedules a `ScheduleWakeup` and
  resumes you on the wake or the completion notification, whichever comes first). On every (re)entry,
  re-run §0 and reload run-state (§7) BEFORE acting — state comes from the PR + run-state, not memory.
  On `PENDING`, re-check ground truth, then re-arm the same script (fresh call) while
  `date +%s < DEADLINE`. Do NOT run the script in the foreground (foreground Bash caps at 10 min
  and long sleeps may be blocked), and do NOT stop your turn claiming to poll without the receipt.
- **Other harnesses (e.g. Codex CLI)**: run the script in the foreground as-is (it is bounded to
  ~8 min); on `PENDING`, rerun it until `RESPONSE`/`TIMEOUT`.

Non-Codex reviews (`.user.login != $BOT`) are out of scope — list them for the human, do not act.

## 3. Detect approval

**Important: Codex posts its approval as an ISSUE comment, not a review object.** When it finds
nothing, it adds a PR issue comment whose body starts with
`Codex Review: Didn't find any major issues.` (with a `Reviewed commit:` line). This will NOT appear
under `pulls/{pr}/reviews` — poll `issues/{pr}/comments` for it too (step 2). Check it every cycle:

```sh
APPROVED=$(gh api "repos/$OWNER/$REPO/issues/$PR/comments" \
  --jq "[.[]|select(.user.login==\"$BOT\" and (.body|startswith(\"Codex Review: Didn't find any major issues\")))]|max_by(.created_at)")
# Confirm it reviewed the current head (avoid a stale approval from an earlier commit):
echo "$APPROVED" | jq -r '.body' | grep -oE 'Reviewed commit:[^ ]* `[0-9a-f]+`'
```

If `APPROVED` is non-empty AND its `Reviewed commit` matches the pushed head → **approved, done**.

Otherwise, when Codex DID post one or more reviews, a review set that adds **no new actionable
inline comments** also counts as approval:

```sh
NCOMMENTS=$(echo "$NEW_REVIEWS" | jq -r '.[].id' | while read -r RID; do
  gh api "repos/$OWNER/$REPO/pulls/$PR/comments" \
    --jq "[.[]|select(.pull_request_review_id==$RID)]|length"; done | paste -sd+ - | bc)
```

(👍 reactions on the trigger comment are NOT part of the approval definition — the waiter does not
watch reactions, so treating them as approval would just convert them into false timeouts.)

## 4. Enumerate the threads to triage

Triage is scoped to **all unresolved bot threads**, not just this cycle's review — the cycle-0
sweep (§0) and overlapping auto-reviews surface older ones, and duplicates across reviews are
common. Use the §6 GraphQL listing filtered to `resolved == false` and a bot-authored first
comment; fingerprint by (path, line, gist of the claim) and dedup: one canonical triage per
fingerprint, non-canonical threads get a short reply referencing the canonical thread, then
resolve. Per-review enumeration (when you need to attribute comments to a specific review):

```sh
gh api "repos/$OWNER/$REPO/pulls/$PR/comments" \
  --jq ".[]|select(.pull_request_review_id==$REVIEW_ID)|{id,path,line:(.line//.original_line),body}"
```

Each such comment id anchors one review thread.

## 5. Reply to a thread

Reply under the specific inline comment (REST, threaded):

```sh
gh api "repos/$OWNER/$REPO/pulls/$PR/comments" \
  -F in_reply_to=<comment_id> -F body=@/abs/path/to/reply.txt --jq '.html_url'
```

Use an **absolute** path for the body file (e.g. under the session scratchpad) — the shell cwd
resets between tool calls, so a relative `reply.txt` may not resolve.

Note: replies post as the authenticated `gh` user (`$ME`), so exclude `$ME`-authored comments when
detecting *new* reviewer activity.

## 6. Resolve a thread (GraphQL only — no REST equivalent)

Map a REST inline comment to its GraphQL review-thread node id, then resolve it.

```sh
# List review threads with their first comment's databaseId + resolved state:
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{ id isResolved comments(first:1){ nodes{ databaseId path } } }
      }
    }
  }
}' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | {threadId:.id, resolved:.isResolved, commentId:.comments.nodes[0].databaseId, path:.comments.nodes[0].path}'
```

Find the `threadId` whose `commentId` equals the Codex comment id you handled, then:

```sh
gh api graphql -f query='
mutation($threadId:ID!){
  resolveReviewThread(input:{threadId:$threadId}){ thread{ isResolved } }
}' -F threadId="<threadId>" --jq '.data.resolveReviewThread.thread.isResolved'   # => true
```

## 7. Resume & liveness (defeat the silent-idle stall)

Re-entry does not depend on auto-re-invoke. It depends on (a) a durable run-state file the subagent
refreshes each arm, and (b) the main agent's scheduled re-drive. Any (re)entry reconstructs state
from the PR (§0) + this file — never from memory.

```sh
# Durable run-state (heartbeat). Path lives under the session scratchpad; pass it across respawns.
RUN_STATE="$SCRATCH/review-codex-loop.$OWNER-$REPO.pr$PR.json"
# Write/refresh on every waiter arm:
cat > "$RUN_STATE" <<JSON
{"run_start_iso":"$RUN_START_ISO","cycle":$CYCLE,"trigger_ts":$TRIGGER_TS,
 "phase":"waiting","last_arm_ts":$(date +%s),"waiter_task_id":"$WAITER_ID","head":"$(git rev-parse HEAD)"}
JSON
```

**Main-agent stall check (run on every wake / interim notification).** Compute `now - last_arm_ts`.
If it exceeds ~2× the arm interval (i.e. no fresh heartbeat) AND ground truth (§0/§3) is not a stop,
the subagent has stalled — resume it (`SendMessage`) or respawn a fresh owner, passing `$RUN_STATE`
so cycle/budget survive. Because re-entry re-sweeps ground truth first, resuming a stalled or idle
owner is idempotent — it never double-posts `@codex review` and never re-triages a resolved thread.

**Guaranteed re-drive.** When the subagent yields a waiting checkpoint, the main agent schedules a
`ScheduleWakeup` (interval ≈ one arm) as the floor: even if the waiter's completion notification is
lost, the wake fires, the main agent re-sweeps ground truth, and resumes the owner. The wake is the
liveness guarantee; the completion notification is only an optimization that lets it re-drive sooner.

## Cycle bookkeeping

- Derive `cycle` from PR ground truth — it must survive subagent respawn. Count `$ME`-authored
  `@codex review` comments created since the run's start timestamp (carry the start ts and prior
  counts in the escalation payload across respawns):
  ```sh
  gh api "repos/$OWNER/$REPO/issues/$PR/comments" \
    --jq "[.[]|select(.user.login==\"$ME\" and .body==\"@codex review\" and .created_at>=\"$RUN_START_ISO\")]|length"
  ```
  Stop at 5 without approval.
- Keep a `held` list of thread urls + the human decision each needs.
- The 20-min per-cycle budget is wall-clock anchored to `TRIGGER_TS`. Re-arming the waiter (on
  `PENDING`) or being re-invoked early does NOT restart the budget.
- After the fixes of a cycle are pushed, the next `@codex review` reviews the new head; verify the
  reported `reviewed commit` in the Codex review body matches the pushed head to avoid acting on a
  stale snapshot.
