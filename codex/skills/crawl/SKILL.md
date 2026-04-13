---
name: crawl
description: Collect links from a daily note's `## News` / `## Picks` sections or from an explicitly named note, then create concise `Clippings/` article notes plus only the concept notes required to extend an Obsidian vault. Use when converting curated news links into compact research notes, enriching existing clipping notes with a compact summary header, or growing a knowledge graph from web content.
---

# crawl

## Overview

Start from links in a daily note or an explicitly named note and produce lightweight research notes.
The goal is to track technical developments without over-researching and to steadily compound the Obsidian knowledge graph.

## Core Principles

- Do not over-invest. Capture the source accurately and add only the minimum concept scaffolding needed for future recall.
- Always create article notes under `Clippings/`.
- Create or extend concept notes at the vault root.
- Be strictly faithful to the source content; do not introduce external knowledge, personal biases, or unmentioned technical details (e.g., specific tool usage or statistics not in the text) into the summary or logical structure.
- When operating from a daily note, add a Wikilink from the original topic entry to the article note created from it.
- Tag newly created agent-authored notes with `#ai-agent-note`.
- Use `#ai-generated` only to mark AI-authored additions inside pre-existing notes.
- Tag article notes derived from x.com posts with `#x-post`.
- Follow the existing `obsidian` skill's Wikilink discipline: link only the highest-value relationships.
- When enriching an existing clipping note, update only the opening summary block and keep the downstream body intact unless a tiny structural fix is required to avoid duplicate headings.

## Input Modes

### 1. No Arguments

- Treat today's `yyyy-mm-dd.md` as the daily note and process the `## News` and `## Picks` sections.
- If neither section exists, report that fact and stop.
- If only one section exists, process only that section.

### 2. Note Argument Present

- Scan the named note and enumerate candidate sections or content blocks that contain links.
- Present candidates as a short numbered list and ask which one to process.
- Do not start processing before confirmation.
- If `## News` or `## Picks` already exists, rank those sections first.

## Execution Modes

### 1. Default Create-or-Extend Mode

- Discover links, retrieve the source, and create the clipping note when it does not already exist.
- If the clipping note already exists, prefer leaving it alone unless the request clearly asks for enrichment or the note is obviously incomplete.

### 2. Summarize-Only Mode

- Treat an explicit shell-facing flag such as `--summarize` as summarize-only mode.
- In this mode, target only already-created clipping notes that correspond to the selected daily-note topics.
- Resolve the target clipping note by checking, in order:
  1. an existing child Wikilink under the topic entry
  2. a direct match in `Clippings/` by title or plausible title variant
  3. an existing clipping note whose `source` matches the topic's primary URL
- If no existing clipping note can be resolved, skip that topic in summarize-only mode; do not create a new clipping note as fallback.
- Leave the daily note unchanged in summarize-only mode unless the daily note already contains a failure log that needs a minimal correction.

## Link Discovery

- Extract Markdown links, bare URLs, and supporting links nested under bullet items.
- When one topic has a primary link plus supporting links, treat the primary link as the article note's `source` and treat supporting links as `refs` in the body.
- Collapse duplicate URLs into a single unit of work.

## Retrieval Strategy

1. First try ordinary web retrieval or web search to understand the content.
2. Reach for MCP only when body extraction is insufficient and the missing context is material to note creation.
3. Use only the specific MCP required, such as Chrome DevTools MCP or Playwright MCP.
4. If retrieval still fails, abandon that link.
5. When abandoning a link, leave only a failure log in the daily note.

When summarize-only mode is active:

- Retrieve only what is needed to write the compact opening summary block for the existing clipping note.
- Reuse the clipping note's existing metadata when it is already sufficient; do not spend extra effort rehydrating fields that are unrelated to the summary block.

Minimal failure log:

```md
- crawl failed: <URL>
  - reason: <why retrieval failed>
```

## Article Note Workflow

1. Check whether an article note already exists under `Clippings/`, including plausible title variants.
2. In default mode, if no note exists, create a new one under `Clippings/`.
3. In summarize-only mode, if no note exists, skip the topic instead of creating a new note.
4. Match the page title whenever practical; shorten it only if it is unreasonably long.
5. New article notes should include at least the following:

```md
---
title:
source:
author:
published:
created: <today>
description:
tags:
  - clippings
  - x-post # only for x.com posts
---
#ai-agent-note

## Summary
2-4 sentence summary

## Keywords
- [[Concept A]]
- Concept B

## What
- What it is
- What it provides

## Why
- Why it mattered enough to capture
- What problem or backdrop made it relevant

## Notes
- Key signal from the source
- List supporting links as `refs` when present
```

6. For summarize-only updates to an existing clipping note, insert or replace only the opening block directly after the frontmatter and any existing agent tag block. The opening block includes the summary, logical structure, and the `# body` boundary.
7. Use the following summarize-only opening shape:

```md
#ai-generated

## Summary
(Exactly 5 sentences)

## Logical Structure
- **Core Thesis**: (One-line core claim and its logical necessity)
- **Issue Map & Interpretation**:
  - **[Issue 1: Topic Name]** -> **Author's Stance:** (Author's evaluation/interpretation/warning)
    - (Sub-point 1: Reasoning or specific data/evidence from the article)
    - (Sub-point 2: Secondary points or conditions)
  - **[Issue 2: Topic Name]** -> **Author's Stance:** ...
- **Synthesis**: (Overall summary of how points integrate and the final conclusion)

---
# body
```

8. In summarize-only mode, the `## Summary` must be exactly five sentences capturing the core backdrop, evaluation, claim, and nuance without bloating the note.
9. In summarize-only mode, the `## Logical Structure` must use the hierarchical format (Issue Map & Interpretation) to show the depth of the argument and the author's stance on each major point. Ensure that every level of the hierarchy is grounded in the source text.
10. Prefer concepts, tools, technologies, and service names as keywords.
11. Keep `What` and `Why` compact. A few bullets and a brief summary are enough.
12. Do not paste long summaries or excessive excerpts from the source.
13. Do not rewrite the existing `# body` section or its subordinate sections (`Keywords`, `What`, `Why`, `Notes`) when summarize-only mode is sufficient. Treat everything after the `# body` heading as the preserved original content.

## Concept Note Workflow

1. Consider only the most important concept surfaced by the article.
2. Before creating a new concept note, check for an equivalent or near-equivalent existing note.
3. If an existing note already explains the concept well enough, do not create or append anything.
4. Only when an existing note is empty or thin should you lightly consult primary sources such as official documentation and append a concise explanation.
5. Use `#ai-agent-note` for new concept notes.
6. Use `#ai-generated` only when AI adds explanatory text to an existing note.

Minimal concept note shape:

```md
# <Concept Name>

#ai-agent-note

- What: What the concept or tool is
- Why: What problem it addresses and why it is relevant now
- Refs:
  - <official docs>
  - [[Related Article Note]]
```

Append example for an existing note:

```md
## AI Added Summary

#ai-generated

- What: What the concept or tool is
- Why: What problem it addresses and why it is relevant now
```

## Linking Rules

- If an existing note name is available, match that exact Wikilink target.
- In article notes, link only the most important concepts with `[[...]]`.
- When updating a daily note, add only one article-note Wikilink per topic entry. Do not hang concept notes beneath it.
- Do not turn every noun in a paragraph into a Wikilink.
- Never turn code, CLI commands, URLs, dates, or issue IDs into Wikilinks.

## Daily Note Update Workflow

1. When starting from a daily note and creating a new article note, add a Wikilink to that article note directly under the original topic entry.
2. Use a child bullet for the addition and preserve existing supporting links or notes with the smallest possible diff.
3. If a topic is skipped and no article note is created, add no Wikilink beyond the failure log.
4. In summarize-only mode, do not add another child Wikilink for a topic that is already clipped.

## Output Quality Bar

- Each processed link should become understandable within a few dozen seconds of reading.
- Reading only the article note should make both the subject and its relevance clear.
- Do not turn concept notes into encyclopedias. Preserve only the minimum that makes the next reread efficient.
- A summarize-only update should let the reader grasp the article's thesis and skeleton from the opening block alone.

## Stop Conditions

- The source cannot be retrieved.
- The core claim cannot be identified.
- Existing notes are already sufficient and a new note would add noise.
- Summarize-only mode cannot resolve the target clipping note.
- The existing clipping note already has a good five-sentence summary and a clear logic-outline block near the top.

In those cases, do not force completion. Leave only the smallest useful failure log or skip rationale.
