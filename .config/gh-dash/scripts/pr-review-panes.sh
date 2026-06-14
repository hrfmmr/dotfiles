#!/usr/bin/env bash
# Open one tmux window with three panes for reviewing a PR, WITHOUT switching
# branches or touching the working tree:
#   pane 0: codex ($difit-review with an explanatory-comment prompt)
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
#   pr-review-panes.sh <RepoPath> <RepoName> <PrNumber> <HeadRefName>
set -euo pipefail

repo_path="${1/#\~/$HOME}"   # expand a leading ~ defensively
repo_name="$2"
pr_number="$3"
head_ref="$4"

window_name="${repo_name}#${pr_number}"

cd "$repo_path"

# Resolve the PR base branch and head commit without checking anything out.
# Fetching only updates refs (FETCH_HEAD / origin tracking refs); the current
# branch and working tree are left untouched. Fall back to the head ref name
# if the fetch is unavailable (e.g. offline).
base_ref="$(gh pr view "$pr_number" --json baseRefName -q '.baseRefName')"
git fetch -q origin "$base_ref" 2>/dev/null || true
git fetch -q origin "pull/${pr_number}/head" 2>/dev/null || true
head_rev="$(git rev-parse -q --verify FETCH_HEAD 2>/dev/null || printf '%s' "$head_ref")"

# sq: wrap a string as one safely-quoted shell word (escapes embedded quotes).
sq() { local s=${1//\'/\'\\\'\'}; printf "%s" "'$s'"; }
# zwrap: turn an inner command line into one that a tmux pane can run under a
# login + interactive zsh, so ~/.zshenv and ~/.zshrc are sourced first.
zwrap() { printf 'zsh -l -i -c %s' "$(sq "$1")"; }

# codex prompt. The literal `$difit-review` skill reference must survive intact,
# so it is single-quoted (no shell expansion). Keep the explanatory intent;
# comments posted in difit must be written in Japanese.
prompt='$difit-review https://github.com/'"${repo_name}"'/pull/'"${pr_number}"'
Run two passes over this PR and post all results as comments in this difit session, written in Japanese: (a) an explanatory review of the change, and (b) a pure code review using the $review skill.

1. Lead with a single overview comment that combines two things. First, an overall assessment of the PR (your summary judgment plus the $review decision such as approve or request changes, with the main reasons). Second, an at-a-glance map of the whole review: enumerate the decision points this change touches and where each one lives in the diff, and for each point state concisely what issue it addresses and what choice this diff makes, with the reasoning. A reader should be able to grasp the verdict, the shape, and the intent of the entire change from this one comment before reading any code.

2. Then attach line-level comments on the relevant diffs:
   - On the core diffs behind those decision points, add plain, easy-to-follow explanations that fill in the background and assumptions a reader needs and walk through the technical details, so that even someone unfamiliar with this area can understand what the change does and why.
   - For every concrete finding from the $review code review (bugs, risks, design or style concerns), attach a comment at its exact location stating the problem and a concrete suggested fix.'

# codex runs inside an nvim :terminal, mirroring ~/.tmux.conf: a login+interactive
# zsh loads ~/.zshenv + ~/.zshrc and direnv, then launches codex; startinsert drops
# the user straight into the codex TUI. The prompt is written to a temp file and
# read via `cat`, so its newlines and the literal `$difit-review` never have to
# survive the nvim Ex-command / shell quoting layers.
slug="$(printf '%s' "${repo_name}-${pr_number}" | tr -cs 'A-Za-z0-9._-' '_')"
prompt_file="${TMPDIR:-/tmp}/gh-dash-codex-${slug}.txt"
printf '%s' "$prompt" >"$prompt_file"
term_cmd="direnv allow . 2>/dev/null; codex \"\$(cat ${prompt_file})\""
inner_codex="nvim -c $(sq "terminal zsh -lic $(sq "$term_cmd")") -c startinsert"

inner_diffview="nvim -c $(sq 'lua require([[lazy]]).load({plugins={[[diffview.nvim]]}})') -c $(sq "DiffviewOpen origin/${base_ref}...${head_rev}")"
inner_octo="nvim -c $(sq 'lua require([[lazy]]).load({plugins={[[octo.nvim]]}})') -c $(sq "Octo pr edit ${pr_number}")"

# Create the window (pane 0 = codex), then split off the two nvim panes.
pane0="$(tmux new-window -P -F '#{pane_id}' -c "$repo_path" -n "$window_name" "$(zwrap "$inner_codex")")"
tmux split-window -h -t "$pane0" -c "$repo_path" "$(zwrap "$inner_diffview")"
tmux split-window -v -t "$pane0" -c "$repo_path" "$(zwrap "$inner_octo")"
tmux select-layout -t "$pane0" tiled
tmux select-pane -t "$pane0"
