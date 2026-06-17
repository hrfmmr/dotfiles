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

# Fail clearly when the repo isn't available locally — e.g. RepoName isn't covered
# by any `repoPaths` entry, so gh-dash hands us an empty RepoPath. Otherwise nvim
# launches in the wrong directory and diffview emits a cryptic "Not a repo" error.
if [ -z "$repo_path" ] || ! git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1; then
  echo "pr-nvim.sh: '${repo_path:-<empty>}' is not a git repo — is ${repo_name} mapped under repoPaths?" >&2
  exit 1
fi

cd "$repo_path"

# sq: wrap a string as one safely-quoted shell word (escapes embedded quotes).
sq() { local s=${1//\'/\'\\\'\'}; printf "%s" "'$s'"; }

# write_lua: persist a Lua chunk to a temp file and echo its path. nvim runs it
# via `-c 'luafile <path>'`, so the Lua body never traverses the shell/Ex quoting
# layers (tmux -> sh -> zsh -> nvim). That removes the nested-quote fragility that
# made an inline `-c 'lua ...'` mis-parse (E5107 ')' expected near ...). The body
# also chdir's into the repo first, so diffview/octo resolve the right git tree
# regardless of whether the pane cwd survived the shell wrapping ("Not a repo!").
slug="$(printf '%s' "${repo_name}-${pr_number}" | tr -cs 'A-Za-z0-9._-' '_')"
write_lua() {
  local f="${TMPDIR:-/tmp}/gh-dash-${1}-${slug}.lua"
  printf '%s' "$2" >"$f"
  printf '%s' "$f"
}

case "$mode" in
  diffview)
    # Resolve base branch + head commit without checking anything out; fetching
    # only updates refs, leaving the current branch and working tree untouched.
    base_ref="$(gh pr view "$pr_number" -R "$repo_name" --json baseRefName -q '.baseRefName')"
    git fetch -q origin "$base_ref" 2>/dev/null || true
    git fetch -q origin "pull/${pr_number}/head" 2>/dev/null || true
    head_rev="$(git rev-parse -q --verify FETCH_HEAD 2>/dev/null || printf '%s' "$head_ref")"
    lua_file="$(write_lua diffview "vim.fn.chdir([[${repo_path}]])
require([[lazy]]).load({ plugins = { [[diffview.nvim]] } })
vim.cmd([[DiffviewOpen origin/${base_ref}...${head_rev}]])")"
    inner="nvim -c $(sq "luafile ${lua_file}")"
    ;;
  octo)
    lua_file="$(write_lua octo "vim.fn.chdir([[${repo_path}]])
require([[lazy]]).load({ plugins = { [[octo.nvim]] } })
vim.cmd([[Octo pr edit ${pr_number}]])")"
    inner="nvim -c $(sq "luafile ${lua_file}")"
    ;;
  *)
    echo "pr-nvim.sh: unknown mode '$mode' (expected diffview|octo)" >&2
    exit 2
    ;;
esac

# Run nvim under a login + interactive zsh inside the new tmux window.
tmux new-window -c "$repo_path" -n "$window_name" "zsh -l -i -c $(sq "$inner")"
