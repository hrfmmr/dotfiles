---
name: clip
description: Dump one or more web article URLs as Markdown notes into the Obsidian vault's Clippings/ folder, using mdhq (Defuddle) and normalizing to the vault's Web Clipper frontmatter and title-based filenames. Use when the user says "clip this URL", "clip this article", "save this URL to Clippings", "dump this article as Markdown", "drop this into Clippings", or hands over article URLs to save as clipping notes. Dump only; summaries and link discovery inside notes belong to the crawl skill. Requires Node.js 22+ and network access.
---

# clip

## Overview

Fetch each URL with mdhq in a throwaway root, rewrite the result into the vault's Clippings convention, and save it flat under `Clippings/`. The bundled script does everything deterministically; do not hand-roll fetching, frontmatter, or filename logic.

The script lives at `scripts/clip.mjs`, relative to this SKILL.md. Resolve it from this file's directory rather than a harness-specific absolute path, since the same skill directory is reached through different roots depending on the harness.

```bash
SKILL_DIR="<absolute path of the directory containing this SKILL.md>"
test -f "$SKILL_DIR/scripts/clip.mjs"   # sanity check before proceeding
```

## Run

Run from anywhere inside the vault; the vault root is the nearest ancestor of the current directory that contains `.obsidian`.

```bash
node "$SKILL_DIR/scripts/clip.mjs" <url> [<url>...]
node "$SKILL_DIR/scripts/clip.mjs" --update <url>             # overwrite the existing note for the same source
node "$SKILL_DIR/scripts/clip.mjs" --dest Inbox/web <url>     # destination relative to the vault root, or absolute
node "$SKILL_DIR/scripts/clip.mjs" --vault-root <dir> <url>   # when the cwd is outside the vault
```

- Pass every URL the user gave in one invocation; mdhq fetches in parallel and spaces requests per host.
- Accept only `http(s)` article URLs. Do not extract URLs from notes; that is the crawl skill's job.
- The first run downloads `@songmu/mdhq` through `npx`; allow extra time.

## Output contract

The script prints one JSON line per URL and exits `0` when nothing failed, `1` when any URL failed, `2` on usage errors.

| status | meaning | fields |
|---|---|---|
| `saved` | new note written | `path`, `title` |
| `updated` | `--update` replaced an existing note | `path`, `title` |
| `skipped` | a note with the same `source` already exists; nothing written | `path`, `reason` |
| `failed` | fetch or conversion failed; no file created | `reason` |

`path` is vault-relative when the destination is inside the vault.

## Note format

Frontmatter is normalized to the vault's Web Clipper shape:

```yaml
---
title: "<page title>"
source: "<normalized URL>"
author:
  - "[[<author>]]"        # empty `author:` when the page exposes none
published: YYYY-MM-DD     # empty when unknown
created: YYYY-MM-DD       # today; preserved on --update
description: "<meta description>"
tags:
  - "clippings"
  - "x-post"              # only for x.com / twitter.com sources
---
```

- Drop mdhq-only keys (`language`, `updated`, `modified`, `etag`, `last_modified`, `requested_url`).
- Keep the Markdown body exactly as mdhq produced it. Images stay as remote URLs (`--no-assets`).
- Name the file after `title` with `\ / : * ? " < > | # ^ [ ]` removed (a removed ` | ` leaves a double space, as in existing clippings), cut to 240 UTF-8 bytes; append ` (2)`, ` (3)`, ... when another source already uses the name.
- Detect duplicates by `source` (fragment and trailing slash ignored), both before fetching and after redirect or canonical resolution.

## Report

Reply with one line per URL: status, vault-relative path, and title. For `failed`, copy the `reason` and write nothing else for that URL. Mention that summarizing the new notes is a separate step (`crawl --summarize`) only when the user seems to expect it.

## Boundaries

- Do not summarize, tag with `#ai-agent-note`, edit daily notes, or commit; the vault is backed up by obsidian-git.
- Do not fall back to browser MCP, WebFetch, or authenticated headers when mdhq fails (login walls, JS-only pages, non-HTML responses). Report the failure and stop for that URL.
- mdhq user config is isolated by the script (`XDG_CONFIG_HOME` points at a temp dir), so `~/.config/mdhq/config.json` has no effect.
- To change the pinned mdhq version, edit `MDHQ_PACKAGE` in `scripts/clip.mjs` and re-run the smoke test below.

## Smoke test

After changing the script, run against a throwaway destination, never the real `Clippings/`:

```bash
D="$(mktemp -d)"
node "$SKILL_DIR/scripts/clip.mjs" --dest "$D" https://example.com/ https://example.com/404-check   # saved + failed, exit 1
node "$SKILL_DIR/scripts/clip.mjs" --dest "$D" https://example.com/                                  # skipped
```
