---
name: pdf-chapter-split
description: Split a single PDF into per-chapter files. Use when the user says "PDFを章ごとに分割して", "章ごとのPDFを作りたい", "split PDF by chapter", "extract chapters from PDF", "split book PDF into chapters", or wants to produce one file per chapter from a book-style PDF. Requires poppler (pdftotext) and pypdf installed in the environment.
---

# pdf-chapter-split

## Overview

Identify chapter boundaries in a book-style PDF using its table-of-contents pages, then split the PDF into one file per chapter using pypdf.

## Prerequisites

```bash
# macOS
brew install poppler   # provides pdftotext
pip install pypdf      # or: uv add pypdf

# Linux (Debian/Ubuntu)
sudo apt install poppler-utils
pip install pypdf
```

## Workflow

### Step 1 — Locate the table of contents

Extract text from the first 30 pages and scan for chapter headings with page numbers:

```bash
pdftotext -f 1 -l 30 -layout "<input.pdf>" - | \
  grep -iE "第\s*[0-9]+\s*章|Chapter\s+([0-9]+|[IVXivx]+)|Part\s+[0-9]+|^\s*[0-9]+\.\s+\S"
```

Note the **book page number** shown beside each chapter title in the TOC.

> **Pattern adjustment**: the grep above covers Japanese (第N章), English numeric/Roman-numeral chapters, Parts, and numbered-section headings. If the TOC uses a different convention (e.g. "Lesson", "Unit", "Kapitel"), extend the pattern or scan the TOC text manually to identify boundary page numbers.

> **No extractable text**: if pdftotext returns empty or garbled output for every page, the PDF is likely a scanned image without an OCR layer. In that case, identify chapter boundaries visually using a PDF viewer, then jump to Step 4.

### Step 2 — Determine the PDF-page offset

The PDF has front-matter pages (cover, TOC, preface) before the book's page 1. Find the offset:

```bash
pdftotext -f <candidate_pdf_page> -l <candidate_pdf_page> -layout "<input.pdf>" -
```

Scan pages in the front-matter range (typically PDF pages 10–40) until you find a page whose extracted text begins with "1" followed by the first chapter heading. If that content appears on PDF page N, then:

```
offset = N - 1   # equals: pdf_page - book_page (number of front-matter pages)
```

Verify with a second anchor point (e.g., a mid-book chapter): `pdf_page = book_page + offset`.

**If the two verification points disagree**: do not assume a single global offset. Calculate the offset per region separately and determine whether the PDF has a section-level re-numbering or duplicate offset zones. Apply each local offset independently when building the chapter map in Step 4.

### Step 3 — Confirm boundary pages

For each chapter start, spot-check the actual PDF page:

```bash
pdftotext -f <pdf_page> -l <pdf_page> -layout "<input.pdf>" -
```

Expect to see the chapter title page. The page immediately after should show the expected book page number for that chapter's first content page (e.g., if the chapter begins at book page 45, the next PDF page should show "45" or "46" alongside the chapter heading).

> For CJK PDFs, decorative chapter-title pages often render as garbled text or symbols — this is normal. Confirm the boundary using the surrounding numbered content pages instead.
> For Latin-script PDFs, the chapter title should be readable directly.

### Step 4 — Build the chapter map

Construct a list of `(label, first_pdf_page, last_pdf_page)` tuples. The last page of chapter N is `first_page_of_chapter_(N+1) - 1`. The final chapter ends at the total page count.

Example map pattern:

```python
chapters = [
    ("00_frontmatter",   1,           offset),       # cover + TOC
    ("01_ch01_<label>",  offset + 1,  ch2_start - 1),
    ("02_ch02_<label>",  ch2_start,   ch3_start - 1),
    # ...
    ("NN_chNN_<label>",  last_start,  total_pages),
]
```

### Step 5 — Split with the bundled script

```bash
python3 ~/.codex/skills/pdf-chapter-split/scripts/split.py \
    --input  "<input.pdf>" \
    --output "<output_dir>" \
    --chapters '01_ch01_<label>:<first_pdf_page>:<last_pdf_page>' \
               '02_ch02_<label>:<first_pdf_page>:<last_pdf_page>' \
               ...
```

The `LABEL` field is separated from page numbers by `rsplit(":", 2)`, so colons within a label (e.g., `ch01_intro:overview`) are safe. Path separators (`/`, `\`) in labels are rejected.

## Edge Cases

- **No PDF bookmarks**: Book-style PDFs frequently lack embedded bookmarks. Always fall back to TOC text extraction (Step 1) rather than relying on bookmark metadata.
- **CJK / non-Unicode decorative fonts**: pdftotext may emit mojibake on chapter title pages using non-Unicode CJK encodings. Trust the surrounding content pages for boundary confirmation.
- **No extractable text (scanned PDF)**: If pdftotext output is empty or noise, determine boundaries visually and skip directly to Step 4.
- **Encrypted PDF**: `scripts/split.py` will exit cleanly with an error message. Decrypt the PDF first (e.g., with `qpdf --decrypt`).
- **Blank separator pages**: Some books insert a blank page between chapters. Include it in the preceding chapter's range.
- **Inconsistent offset**: If verification points disagree, calculate per-region offsets; do not extrapolate a single global value.

## Output Convention

Name output files with a zero-padded numeric prefix so they sort correctly in file managers:

```
00_frontmatter.pdf
01_ch01_<label>.pdf
02_ch02_<label>.pdf
...
```

Label guidelines:
- Use the chapter title in slug form: lowercase, words separated by `-`.
- Replace `/` and special characters with `-`; omit colons or replace with `-`.
- Keep labels under 50 characters to stay within all major filesystem limits.
- Use padding width based on chapter count: 2 digits for up to 99 chapters, 3 digits for 100+.
