#!/usr/bin/env bash
# Open one tmux window with three panes for reviewing a PR, WITHOUT switching
# branches or touching the working tree:
#   pane 0: codex or claude ($difit-review with an explanatory-comment prompt)
#   pane 1: nvim DiffviewOpen (diffview.nvim) over origin/<base>...<pr-head>
#   pane 2: nvim Octo pr edit (octo.nvim)
#
# The PR head is fetched read-only (no checkout), so this works on any working
# tree state (dirty, mid-feature, etc.); difit reviews via the PR URL and octo
# via the GitHub API, neither of which needs a local checkout.
#
# Each pane command runs under a login + interactive zsh (`zsh -l -i -c ...`)
# so ~/.zshenv and ~/.zshrc are loaded before the tool starts. (tmux otherwise
# runs a given command through plain `/bin/sh -c`, loading no zsh rc files.)
#
# Invoked from a gh-dash keybinding:
#   pr-review-panes.sh <RepoPath> <RepoName> <PrNumber> <HeadRefName> [agent]
#   agent: "codex" (default) or "claude"
set -euo pipefail

repo_path="${1/#\~/$HOME}"   # expand a leading ~ defensively
repo_name="$2"
pr_number="$3"
head_ref="$4"
agent="${5:-codex}"

window_name="${agent}:${repo_name}#${pr_number}"

# Fail clearly when the repo isn't available locally — e.g. RepoName isn't covered
# by any `repoPaths` entry, so gh-dash hands us an empty RepoPath. Otherwise the
# nvim panes launch in whatever directory happened to be current and diffview emits
# a cryptic "Not a repo (or any parent)" error.
if [ -z "$repo_path" ] || ! git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
  echo "pr-review-panes.sh: '${repo_path:-<empty>}' is not a git repo — is ${repo_name} mapped under repoPaths?" >&2
  exit 1
fi

cd "$repo_path"

# Resolve the PR base branch and head commit without checking anything out.
# Fetching only updates refs (FETCH_HEAD / origin tracking refs); the current
# branch and working tree are left untouched. Fall back to the head ref name
# if the fetch is unavailable (e.g. offline).
base_ref="$(gh pr view "$pr_number" -R "$repo_name" --json baseRefName -q '.baseRefName')"
git fetch -q origin "$base_ref" 2>/dev/null || true
git fetch -q origin "pull/${pr_number}/head" 2>/dev/null || true
head_rev="$(git rev-parse -q --verify FETCH_HEAD 2>/dev/null || printf '%s' "$head_ref")"

# sq: wrap a string as one safely-quoted shell word (escapes embedded quotes).
sq() { local s=${1//\'/\'\\\'\'}; printf "%s" "'$s'"; }
# zwrap: turn an inner command line into one that a tmux pane can run under a
# login + interactive zsh, so ~/.zshenv and ~/.zshrc are sourced first.
zwrap() { printf 'zsh -l -i -c %s' "$(sq "$1")"; }

# The literal `$difit-review` skill reference must survive intact, so it is
# single-quoted (no shell expansion). Comments posted in difit must be in Japanese.
prompt='$difit-review https://github.com/'"${repo_name}"'/pull/'"${pr_number}"'
Review this PR and post all results as comments in this difit session, in one storytelling voice.
Use the $review skill to find bugs and issues, but weave those findings into the same narrative — do not label or separate them as a distinct pass.

Write everything in Japanese. Use polite desu/masu style, avoid jargon, and aim for language a middle-schooler could follow — the tone of a Slack message to a colleague, not a technical document. When a technical term is unavoidable, define it in one phrase on the spot.

1. Lead with a single overview comment structured as a short story (aim for roughly one page):

   a) The situation before — In two or three sentences, describe the world before this PR: what was the system doing, and what problem or inconvenience existed? Paint it so someone who has never seen this codebase can picture the "before" state.

   b) The thinking — In one or two sentences, state the core idea of this PR: what approach did the author choose, and what was the thinking behind it? If there was an obvious simpler alternative, briefly note why the author did not take that path.

   c) What changed — Walk through each change the PR makes, in the order that makes the most sense to tell the story. To find every change worth discussing, examine every hunk and ask: "what question did the author face here, and what did they choose?" Include not just additions and deletions but also deliberate non-changes, parameter or config choices, and ordering decisions.
   Number each change sequentially. For each one, frame it as:
     Issue N: what problem or choice was the author facing?
     Answer: what did the diff choose, and why? If a more obvious alternative existed, note briefly why it was not taken.
   A reader should be able to scan this section and fully grasp the shape and intent of the entire change without opening a single file.

   d) Takeaway — Give your overall assessment (approve / request changes) with the key reasons, as a natural conclusion to the story above.

2. Then attach line-level comments on every substantial diff point across all changed files — do not skip a file or hunk just because it seems minor. A diff point is substantial if it changes behavior, configuration, control flow, or a public interface; skip only purely mechanical changes (whitespace, auto-formatting, import reordering).
   Each comment should be 2-5 sentences, reading like a paragraph from a well-written guide:
   - Start by briefly connecting the comment back to the relevant Issue in the overview (e.g., "This is the change behind Issue 2").
   - Structure the explanation in three beats — Before (what the old code did or what was missing), After (what the new code does), Why (why this solves the problem). Write as if explaining to a smart colleague who is a designer or PM — they understand cause and effect but not code constructs.
   - For every concrete finding from the $review code review (bugs, risks, design or style concerns): state the problem as a simple cause-and-effect sentence ("When X happens, Y will go wrong because Z"), then give a concrete suggested fix.'

# The prompt is written to a temp file and read via `cat`, so its newlines and
# the literal `$difit-review` never have to survive shell quoting layers.
slug="$(printf '%s' "${repo_name}-${pr_number}" | tr -cs 'A-Za-z0-9._-' '_')"
prompt_file="${TMPDIR:-/tmp}/gh-dash-${agent}-${slug}.txt"
printf '%s' "$prompt" >"$prompt_file"

# Build the pane-0 command based on the chosen agent.
#   codex: runs inside an nvim :terminal (codex needs the nvim TUI wrapper).
#   claude: runs directly in the terminal (claude has its own TUI).
if [ "$agent" = "claude" ]; then
  agent_cmd="direnv allow . 2>/dev/null; claude \"\$(cat ${prompt_file})\""
  inner_agent="$agent_cmd"
else
  agent_cmd="direnv allow . 2>/dev/null; codex \"\$(cat ${prompt_file})\""
  inner_agent="nvim -c $(sq "terminal zsh -lic $(sq "$agent_cmd")") -c startinsert"
fi

# diffview/octo: like codex above, drive nvim from a temp Lua file via
# `-c 'luafile <path>'` instead of an inline `-c 'lua ...'`. Pushing the Lua
# through tmux -> sh -> zsh -> nvim's Ex layer is what mis-parsed the nested
# brackets (E5107 ')' expected near ...); a file sidesteps every quoting layer.
# Each chunk chdir's into the repo first so diffview/octo resolve the right git
# tree even if the pane cwd didn't survive the wrapping ("Not a repo!").
diffview_lua="${TMPDIR:-/tmp}/gh-dash-diffview-${slug}.lua"
printf '%s' "vim.fn.chdir([[${repo_path}]])
require([[lazy]]).load({ plugins = { [[diffview.nvim]] } })
vim.cmd([[DiffviewOpen origin/${base_ref}...${head_rev}]])" >"$diffview_lua"
octo_lua="${TMPDIR:-/tmp}/gh-dash-octo-${slug}.lua"
printf '%s' "vim.fn.chdir([[${repo_path}]])
require([[lazy]]).load({ plugins = { [[octo.nvim]] } })
vim.cmd([[Octo pr edit ${pr_number}]])" >"$octo_lua"
inner_diffview="nvim -c $(sq "luafile ${diffview_lua}")"
inner_octo="nvim -c $(sq "luafile ${octo_lua}")"

# Create the window (pane 0 = agent), then split off the two nvim panes.
pane0="$(tmux new-window -P -F '#{pane_id}' -c "$repo_path" -n "$window_name" "$(zwrap "$inner_agent")")"
tmux split-window -h -t "$pane0" -c "$repo_path" "$(zwrap "$inner_diffview")"
tmux split-window -v -t "$pane0" -c "$repo_path" "$(zwrap "$inner_octo")"
tmux select-layout -t "$pane0" tiled
tmux select-pane -t "$pane0"
