# Socket Mode

Use Unix socket mode as the default pattern when sandboxed Codex sessions need
stable concurrent access to one authoritative beads Dolt server without
relying on localhost TCP.

## Preconditions

- Start one externally managed Dolt server for the authoritative `.beads/dolt`
  data dir.
- Load repo-level env first so `BEADS_DOLT_SERVER_SOCKET` and
  `BEADS_DOLT_AUTO_START=0` are already set when `bd` starts.
- Do not rely on `bd dolt start` in socket mode; auto-start is unsupported.
- Do not depend on repo-local helper scripts for the normal path.

## Setup

If the socket file does not exist yet, create the server first:

```sh
mkdir -p .beads
dolt sql-server \
  --socket "$PWD/.beads/dolt-server.sock" \
  --data-dir "$PWD/.beads/dolt"
```

Keep that process running and reuse the same socket path for later sessions.
Use the socket path defined by `.envrc` as the source of truth.

## Server Pattern

```sh
dolt sql-server --socket /abs/path/to/.beads/dolt-server.sock --data-dir /abs/path/to/.beads/dolt
```

## Client Pattern

```sh
BEADS_DOLT_SERVER_SOCKET=/abs/path/to/.beads/dolt-server.sock \
BEADS_DOLT_AUTO_START=0 \
bd ...
```

Prefer a repo-scoped socket path such as `.beads/dolt-server.sock`. Avoid
shared paths like `/tmp/mysql.sock`, which can collide with unrelated services
or fail under sandbox file-access rules.

Add `--readonly --sandbox` for read-mostly worker sessions.

## Preferred Validation

Validate store-backed commands first:

- `bd show <id>`
- `bd ready --json`
- one safe write such as `bd update <id> --notes ...`
- when remotes matter: `bd dolt remote list`, `bd dolt pull`, `bd dolt push`

For a quick end-to-end check of the minimal read path, use the bundled smoke
script (optional shortcut — not required for normal operation):

```sh
scripts/codex-beads-socket-smoke.sh <socket-path> <issue-id>
```

The script sets `BEADS_DOLT_SERVER_SOCKET` and `BEADS_DOLT_AUTO_START=0`, then
runs `bd show` and `bd ready --json` against the supplied socket.

## Diagnostic Caveat

In `v1.0.3`, some diagnostics remain host/port-oriented even when the socket
path is working:

- `bd dolt test`
- `bd dolt show`
- `bd context`

Do not treat those commands as the primary health signal for socket mode.
Prefer actual store-backed reads/writes and, when relevant, remote operations.

If a socket connection fails with `operation not permitted`, treat that as a
socket path or permission problem first, not as proof that the Dolt server is
down. Check whether the socket path is repo-scoped, whether the file exists,
and whether the current session is allowed to open it.

If a socket connection fails with `no such file or directory`, treat that as a
server setup problem first. Confirm the socket path matches `.envrc` or session
env, then start or restart the external `dolt sql-server --socket <path>`.

## Credential Guidance

- Read-mostly validation: prefer a dedicated read-only SQL user.
- Write and push/pull: use scoped credentials only after ownership, auth, and
  rollback are explicitly decided in the active issue.
