# Legacy Command Phrases -> Codex Runtime Actions

This table maps legacy beads command phrases to Codex runtime actions.

| Legacy phrase | Codex runtime action |
|---|---|
| `ready` | `bd ready --json` |
| `blocked` | `bd blocked --json` |
| `create` | `bd create ... --json` |
| `show` | `bd show <id> --json` |
| `update` | `bd update <id> ... --json` |
| `dep` | `bd dep add/remove/tree ...` |
| `close` | `bd close <id> --reason ... --json` |
| `reopen` | `bd reopen <id> --reason ... --json` |
| `list` | `bd list ... --json` |
| `search` | `bd search ... --json` |
| `stats` | `bd status --json` |
| `workflow` | `bd prime` + `references/guides/WORKFLOWS.md` |
| `prime` | `bd prime` |
| `sync` | `bd dolt pull` (start) + `bd dolt push` (end) |
| `comments` | `bd comments ...` |
| `label` | `bd label ...` |
| `epic` | `bd epic ...` |
| `template` | `bd template ...` |
| `audit` | `bd audit ...` |
| `compact` | `bd admin compact ...` |
| `restore` | `bd restore <id>` |
| `rename-prefix` | `bd rename-prefix ...` |
| `import` | `bd import ...` |
| `export` | `bd export ...` |
| `init` | `bd init` |
| `version` | `bd version` |
| `delete` | `bd delete ... --force` |
| `decision` | `bd create --type decision ...` |

Notes:
- Codex does not provide direct parity for legacy plugin lifecycle hooks.
- Recreate startup behavior with `scripts/codex-beads-session-start.sh` and AGENTS.md instructions.
