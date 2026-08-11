---
name: images-to-pdf
description: Combine multiple images into a single PDF in a given page order, at high quality without an oversized file. Use when the user says "images to one pdf", "merge these images into a pdf", "convert this folder of screenshots to a single pdf", "make a pdf from these image URLs", "combine the GitHub image attachments into one pdf", or supplies a folder of jpg/png files, a text/markdown file containing image URLs, or GitHub user-attachments image links to be merged into one .pdf. Also covers reordering pages, checking that the page order is correct, and tuning quality versus file size. Requires ImageMagick, plus curl for URL sources and the gh CLI only for authenticated GitHub attachment links.
---

# images-to-pdf

## Overview

Resolve image sources (local directory, glob, URL list file, or direct URLs) into an ordered page list, then merge them into one PDF with a single ImageMagick pass. All of it runs through the bundled script; do not hand-roll download or conversion pipelines.

The script lives at `scripts/images_to_pdf.sh`, relative to this SKILL.md. Resolve it from this file's directory rather than from a harness-specific absolute path, since the same skill directory is reached through different roots depending on the harness.

Before the first command, bind that directory once — substitute the skill base directory your harness reported when it loaded this skill:

```bash
SKILL_DIR="<absolute path of the directory containing this SKILL.md>"
test -x "$SKILL_DIR/scripts/images_to_pdf.sh"   # sanity check before proceeding
```

Every command below uses `"$SKILL_DIR/scripts/images_to_pdf.sh"`.

## Prerequisites

```bash
brew install imagemagick   # provides magick (required)
# curl: required for URL sources (preinstalled on macOS)
# gh:   required only for GitHub-hosted images (github.com/user-attachments/...)
```

## Source forms

| Source | Example | Ordering |
|---|---|---|
| Directory (non-recursive) | `./screenshots` | natural sort (`sort -V`) of png/jpg/jpeg/webp/tif/gif/bmp/heic |
| Glob (quote it) | `'shots/*.png'` | natural sort |
| Single image file | `cover.png` | as given |
| URL list file (`.txt`/`.md`/`.html`) | `ch05/images.txt` | order of appearance in the file |
| Direct URLs | `https://... https://...` | argument order |

Multiple sources may be mixed in one invocation; they are concatenated in the order given.

A URL list file is scanned for `src="..."` attributes first; if none exist, every bare `http(s)` URL in the file is used. This covers GitHub issue/PR markdown pasted as `<img width=... src="https://github.com/user-attachments/assets/...">`.

## Workflow

### Step 1 — Confirm the resolved page order

```bash
"$SKILL_DIR/scripts/images_to_pdf.sh" <SOURCE...> --dry-run
```

Nothing is downloaded or written. Check the count and sequence before converting.

### Step 2 — Convert

```bash
"$SKILL_DIR/scripts/images_to_pdf.sh" <SOURCE...> -o <OUTPUT.pdf>
```

Default preset is `balanced`. Use `--force` only when overwriting an existing PDF is intended.

### Step 3 — Reorder when the sequence is wrong

`--order` takes 1-indexed positions from the Step 1 listing, with ranges and singles:

```bash
... -o out.pdf --order 1-12,15,14,13   # swap the 13th and 15th pages
... -o out.pdf --order 5-1             # descending range
... -o out.pdf --order 1-3             # subset: keep only the first three
```

`--order` is applied before downloading, so unselected URLs are never fetched.

### Step 4 — Verify the order (optional, run when the sequence is uncertain)

Cheap visual check — one contact sheet, tiles read left to right, top to bottom:

```bash
... -o out.pdf --contact-sheet proof.jpg
```

Then read `proof.jpg` and confirm the sequence looks continuous.

Reliable check when the pages carry printed page numbers or section numbers — render each page at readable size and read them:

```bash
i=0; for f in <ordered image paths>; do i=$((i+1)); \
  magick "$f" -resize '1560x1560>' -quality 82 "rd/p$(printf '%02d' $i).jpg"; done
```

Read the renders and confirm the printed numbers increase monotonically. Do this only when order correctness matters; it costs one image read per page.

## Presets

| Preset | Long edge | JPEG quality | Density | Typical result (15 book-spread screenshots) |
|---|---|---|---|---|
| `balanced` (default) | 2100 px | 90 | 200 dpi | ~6.6 MB, text crisp on screen and in print |
| `high` | 3150 px | 93 | 300 dpi | ~2x balanced |
| `small` | 1500 px | 85 | 150 dpi | ~1/3 balanced |
| `lossless` | original | n/a (Zip) | 300 dpi | largest; use for line art or when recompression is unacceptable |

Every preset targets a page about 10.5 in on its long edge, so page sizes stay consistent across presets. Images are never upscaled: an image smaller than the preset's long edge keeps its pixels and produces a proportionally smaller page.

Override individual knobs on top of a preset with `--max-dim`, `--quality`, `--dpi`. `--quality` applies to the JPEG presets only; with `lossless` it is ignored and the script says so.

Pick by intent: default to `balanced`; go `high` when the user asks for maximum fidelity or the pages are dense text; go `small` when the user cares about attachment size limits.

## Options

| Option | Effect |
|---|---|
| `-o, --output PATH` | Output PDF path (required unless `--dry-run`) |
| `--preset NAME` | `balanced` \| `high` \| `small` \| `lossless` |
| `--max-dim N` / `--quality N` / `--dpi N` | Override preset values (`--quality` is JPEG presets only) |
| `--order SPEC` | Reorder or subset pages, e.g. `1-12,15,14,13` |
| `--contact-sheet PATH` | Also write a tiled overview image for order checking |
| `--dry-run` | Print the resolved page list and exit |
| `--force` | Overwrite an existing output PDF or contact sheet |
| `--workdir DIR` | Download into `DIR/downloads` and keep it, instead of a temp dir |
| `--keep` | Keep the generated temp dir instead of deleting it on exit |
| `-h, --help` | Print usage |

## Edge Cases

- **GitHub images return `Not Found`**: `github.com/user-attachments/assets/...` requires auth. The script feeds `gh auth token` to curl through a stdin config file (never an argv header, so the token stays out of the process list) and follows the 302 to the signed S3 URL *without* that header, because S3 rejects the extra header with 403. If `gh` is missing or logged out, the fetch fails with `download failed (HTTP error or unreachable)`; run `gh auth login`.
- **zsh `no matches found`**: quote globs (`'imgs/*.png'`) so the script expands them, or pass the directory instead.
- **Mixed orientations**: a portrait page among landscape spreads produces a differently sized page. That is expected; do not pad it to a uniform size unless the user asks.
- **Transparency**: alpha is flattened onto white before merging, so PNG screenshots with transparent corners do not render as black.
- **Verifying the result**: `magick identify` on a PDF needs Ghostscript, which is often absent. Count pages with `grep -a -c '/Type /Page$' out.pdf` and inspect page boxes with `grep -ao '/MediaBox \[[^]]*\]' out.pdf`; render the first page for a visual check with `qlmanage -t -s 1400 -o . out.pdf`.
- **Inspecting what was fetched**: pass `--workdir <dir>` to keep the downloaded images under `<dir>/downloads` instead of a temp dir that is deleted on exit. Reruns still re-download every URL; the kept files are for inspection and manual reuse, not a cache.
- **Partial output**: the PDF is rendered to a temp file beside the destination and renamed only after ImageMagick succeeds, so a failed run never leaves a truncated PDF in place.

## Reporting

State the output path, page count, file size, and the preset used. Mention any reordering applied and, when order was verified, how it was verified.
