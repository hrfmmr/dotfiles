#!/bin/bash
# Provision the python3 provider host for neovim.
#
# The host lives in a dedicated venv instead of whatever `python3` PATH happens
# to resolve to, because version managers (mise, brew) swap interpreters out
# from under it and the provider then dies with "Failed to load python3 host".
#
# Idempotent: exits early when the existing venv can still import pynvim,
# rebuilds it otherwise (e.g. after its base interpreter was pruned).
# Pass --force to rebuild unconditionally, e.g. to move an existing venv off a
# version-manager-owned base interpreter.

set -euo pipefail

# Resolve the data dir defensively: this script rm -rf's under it, so never let
# an unset HOME or a relative XDG_DATA_HOME aim that at an unintended path.
if [ -n "${XDG_DATA_HOME:-}" ]; then
  data_home="$XDG_DATA_HOME"
elif [ -n "${HOME:-}" ]; then
  data_home="$HOME/.local/share"
else
  echo "nvim python3 host: neither XDG_DATA_HOME nor HOME is set" >&2
  exit 1
fi

case "$data_home" in
  /*) ;;
  *)
    echo "nvim python3 host: data dir is not an absolute path: '$data_home'" >&2
    exit 1
    ;;
esac

VENV="$data_home/nvim/venv"
PY="$VENV/bin/python3"
force=false
[ "${1:-}" = "--force" ] && force=true

if [ "$force" = false ] && [ -x "$PY" ] && "$PY" -c 'import pynvim' >/dev/null 2>&1; then
  echo "nvim python3 host: ok ($PY)"
  exit 0
fi

echo "nvim python3 host: (re)creating venv at $VENV"

# A venv embeds its own absolute path (bin/activate, console-script shebangs),
# so it cannot be built elsewhere and moved into place. Build at the final path
# and keep the previous venv aside instead, restoring it if the build fails —
# uv offline, no managed interpreter, or a pip error must not leave the user
# without a working host.
BACKUP="$VENV.bak"

restore() {
  rm -rf "$VENV"
  if [ -d "$BACKUP" ]; then
    mv "$BACKUP" "$VENV"
    echo "nvim python3 host: build failed, restored the previous venv" >&2
  fi
}
# Armed before anything is moved, so a backup is never the only copy.
trap restore EXIT

# A leftover backup with no venv means a previous run was killed mid-swap; that
# backup is the only copy, so recover it rather than discarding it.
if [ -d "$BACKUP" ] && [ ! -d "$VENV" ]; then
  mv "$BACKUP" "$VENV"
fi
rm -rf "$BACKUP"

if [ -d "$VENV" ]; then
  mv "$VENV" "$BACKUP"
fi

mkdir -p "$(dirname "$VENV")"

# Prefer a uv-managed interpreter: it is owned by neither mise nor brew, so
# their upgrades cannot break this venv. Fall back to stock venv when uv is
# absent or cannot provide one.
if command -v uv >/dev/null 2>&1 && uv venv --managed-python "$VENV"; then
  VIRTUAL_ENV="$VENV" uv pip install --quiet pynvim
else
  echo "nvim python3 host: falling back to python3 -m venv"
  rm -rf "$VENV"
  python3 -m venv "$VENV"
  "$PY" -m pip install --quiet --upgrade pip
  "$PY" -m pip install --quiet pynvim
fi

"$PY" -c 'import pynvim'

trap - EXIT
rm -rf "$BACKUP"

"$PY" -c 'import pynvim; v = pynvim.VERSION; print(f"nvim python3 host: installed pynvim {v.major}.{v.minor}.{v.patch}")'
