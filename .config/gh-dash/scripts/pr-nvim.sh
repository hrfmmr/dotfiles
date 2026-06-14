#!/usr/bin/env bash
# Open a tmux window running nvim against a PR, WITHOUT switching branches or
# touching the working tree:
#   diffview: fetch the PR head read-only and diff origin/<base>...<pr-head>.
#   octo:     octo.nvim works via the GitHub API, so no checkout is needed.
#
# nvim runs under a login + interactive zsh (`zsh -l -i -c ...`) so ~/.zshenv
# and ~/.zshrc are loaded first. (tmux otherwise runs a given command through
# plain `/bin/sh -c`, loading no zsh rc files.)
#
# Invoked from gh-dash keybindings:
#   pr-nvim.sh diffview <RepoPath> <RepoName> <PrNumber> <HeadRefName>
#   pr-nvim.sh octo     <RepoPath> <RepoName> <PrNumber> <HeadRefName>
set -euo pipefail

mode="$1"
repo_path="${2/#\~/$HOME}"   # expand a leading ~ defensively
repo_name="$3"
pr_number="$4"
head_ref="$5"

window_name="${repo_name}#${pr_number}"

cd "$repo_path"

# sq: wrap a string as one safely-quoted shell word (escapes embedded quotes).
sq() { local s=${1//\'/\'\\\'\'}; printf "%s" "'$s'"; }

case "$mode" in
  diffview)
    # Resolve base branch + head commit without checking anything out; fetching
    # only updates refs, leaving the current branch and working tree untouched.
    base_ref="$(gh pr view "$pr_number" --json baseRefName -q '.baseRefName')"
    git fetch -q origin "$base_ref" 2>/dev/null || true
    git fetch -q origin "pull/${pr_number}/head" 2>/dev/null || true
    head_rev="$(git rev-parse -q --verify FETCH_HEAD 2>/dev/null || printf '%s' "$head_ref")"
    inner="nvim -c $(sq 'lua require([[lazy]]).load({plugins={[[diffview.nvim]]}})') -c $(sq "DiffviewOpen origin/${base_ref}...${head_rev}")"
    ;;
  octo)
    inner="nvim -c $(sq 'lua require([[lazy]]).load({plugins={[[octo.nvim]]}})') -c $(sq "Octo pr edit ${pr_number}")"
    ;;
  *)
    echo "pr-nvim.sh: unknown mode '$mode' (expected diffview|octo)" >&2
    exit 2
    ;;
esac

# Run nvim under a login + interactive zsh inside the new tmux window.
tmux new-window -c "$repo_path" -n "$window_name" "zsh -l -i -c $(sq "$inner")"
