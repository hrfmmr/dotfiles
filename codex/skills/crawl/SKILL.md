---
name: crawl
description: Collect links from a daily note's `## News` / `## Picks` sections or from an explicitly named note, then write concise Japanese callout summaries directly into the daily note or into already-linked `Clippings/` notes. Use when turning curated links into glanceable structured summaries, refreshing existing clipped notes with a high-signal opening block, deciding whether a source deserves a separate deep-dive note, or spinning off explanatory derived notes for key concepts the vault lacks.
---

# crawl

## Overview

Start from links in a daily note or an explicitly named note and produce lightweight, high-signal summaries.
The default is not to create a separate note for every source. Prefer to write the summary where the reader already is: directly in the daily note for bare URLs, or at the top of an existing clipped note when one is already linked.

## Core Principles

- Do not over-invest. Capture the source accurately and add only the minimum concept scaffolding needed for future recall.
- Do not create a separate article note by default. Create one only when the user explicitly asks for a deep-dive note or when the request clearly requires an independent durable note.
- Do not extend existing concept notes by default; extending stays explicit-only. In default mode, create a new derived note only for a keystone keyword that no vault note covers, as defined in Concept Note Workflow.
- Be strictly faithful to the source content; do not introduce external knowledge, personal biases, or unmentioned technical details (e.g., specific tool usage or statistics not in the text) into the summary or logical structure.
- Standardize summaries around the source's dominant value, not around one generic recap template. A shallow "what happened" recap is insufficient when the article's real value is operational guidance, technical mechanism, or a specific argument.
- Write all agent-authored summaries and explanatory prose in plain Japanese. Keep titles, product names, service names, code, and URLs in their original form when that is clearer.
- Prefer direct, plain Japanese over essay-like or compressed phrasing. If compression makes the note harder to scan, expand slightly and use clearer wording.
- When operating from a daily note, prefer a top-level callout inserted immediately below the source line. Do not force a child bullet just to attach the summary.
- Tag newly created agent-authored notes with `#ai-agent-note`.
- Use `#ai-generated` only to mark AI-authored additions inside pre-existing notes.
- Tag article notes derived from x.com posts with `#x-post`.
- Follow the existing `obsidian` skill's Wikilink discipline: link only the highest-value relationships.
- When enriching an existing clipping note, update only the opening summary block and keep the downstream body intact unless a tiny structural fix is required to avoid duplicate headings.

## Summary Standardization

1. Identify the source's dominant value before writing the summary block.
2. Use one of these article-value buckets unless the source clearly demands a custom skeleton:
   - News / announcement: what changed, why it matters, and what to watch next.
   - Opinion / critique: the author's core claim, why they think that, and the practical implication.
   - Technical deep dive: the mechanism, constraints, key moving parts, and what the reader should understand after reading.
   - Incident advisory / response guide: what happened, why it matters operationally, what to check or do first, and what makes the incident dangerous.
3. Do not force a generic recap when it hides the article's real utility. For example, incident advisories should foreground response and scope, not just retell the incident at a high level.
4. Use a callout opening by default:
   - `>[!summary] <dynamic one-line title>`
5. Use a logical-structure block by default, but keep the labels grounded in the article:
   - `論旨`
   - `概要`
   - `論点1: ...`
     - `理由`
     - `根拠`
   - `論点2: ...`
     - `理由`
     - `根拠`
   - `要するに`
6. Keep labels short and content-bearing. Avoid abstract placeholders or mechanical headings that make the structure harder to scan.
7. When the article is primarily valuable as a checklist, response guide, or technical mechanism note, let the summary block reflect that directly even if some labels differ from the default starting shape.
8. Before finalizing, connect the summary to the vault by applying the concept-linking rules in Linking Rules to the primary concepts the source covers.

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

- Discover links, retrieve the source, and write or refresh the summary where the reader already is.
- If a daily-note topic is a bare URL and no existing clipped note is already linked for that topic, insert a top-level callout directly below the source line in the daily note.
- If a daily-note topic already points to an existing clipped note, target that clipped note first and update only its opening summary block.
- Do not create a new clipping note in default mode unless the user explicitly asks for it. Derived notes for keystone keywords follow Concept Note Workflow.

### 2. Summarize-Only Mode

- Treat an explicit shell-facing flag such as `--summarize` as summarize-only mode.
- In this mode, target only already-created clipping notes that correspond to the selected daily-note topics.
- Resolve the target clipping note by checking, in order:
  1. an existing child Wikilink under the topic entry
  2. a direct match in `Clippings/` by title or plausible title variant
  3. an existing clipping note whose `source` matches the topic's primary URL
- If no existing clipping note can be resolved, skip that topic in summarize-only mode; do not create a new clipping note as fallback.
- In summarize-only mode, update the existing clipped note's opening callout block only. Leave the daily note unchanged unless the daily note already contains a failure log that needs a minimal correction.

## Link Discovery

- Extract Markdown links, bare URLs, and supporting links nested under bullet items.
- Treat existing clipped-note Wikilinks inside `## News` / `## Picks` as first-class crawl targets when they clearly correspond to the source being discussed.
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
- Choose the summary skeleton based on the article-value buckets above; do not default to a generic recap if the source is really an advisory, mechanism note, or argument.

Minimal failure log:

```md
- crawl failed: <URL>
  - reason: <why retrieval failed>
```

## Article Note Workflow

1. Check whether an article note already exists under `Clippings/`, including plausible title variants.
2. In default mode, if an existing clipped note is found, update that note's opening summary block instead of creating anything new.
3. In default mode, if no clipped note exists, prefer an inline daily-note callout over creating a new note.
4. In summarize-only mode, if no clipped note exists, skip the topic instead of creating a new note.
5. Create a new article note under `Clippings/` only when the user explicitly asks for a separate note or when the request clearly calls for a deeper durable note.
6. When a separate article note is explicitly needed, match the page title whenever practical; shorten it only if it is unreasonably long.
7. A separate article note should open with the same callout style used elsewhere, rather than reverting to a different summary template.

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

>[!summary] <dynamic one-line title>
> - 論旨
>   - ...
> - 概要
>   - ...
> - 論点1: ...
>   - 理由
>     - ...
>   - 根拠
>     - ...
> - 要するに
>   - ...
```

8. For summarize-only updates to an existing clipping note, insert or replace only the opening block directly after the frontmatter and any existing agent tag block.
9. If an old `#ai-generated` / `## Summary` / `## Logical Structure` block exists near the top, replace it with the new callout block rather than stacking another summary format on top.
10. Use the following summarize-only opening shape as the default starting point:

```md
#ai-generated

>[!summary] <dynamic one-line title>
> - 論旨
>   - ...
> - 概要
>   - ...
> - 論点1: ...
>   - 理由
>     - ...
>   - 根拠
>     - ...
> - 論点2: ...
>   - 理由
>     - ...
>   - 根拠
>     - ...
> - 要するに
>   - ...
```

11. In summarize-only mode, write the callout in plain Japanese while preserving the source's actual claims and nuance.
12. If the article's dominant value would be obscured by the default starting shape, change the labels. For example, incident advisories may need `まずやること`, `確認項目`, or `被害範囲` instead of a generic recap flow.
13. Do not paste long summaries or excessive excerpts from the source.
14. Do not rewrite the existing body below the opening summary block when summarize-only mode is sufficient.
15. If a logical-structure summary is used, prefer labels that reflect the article's real value, such as response steps, risk scope, mechanism, or core claim, instead of mechanically repeating generic headings.

## Concept Note Workflow

1. In summarize-only mode, create no notes.
2. In default mode, after the summary and link resolution, pick up to 2 keystone keywords per source. A keystone keyword is a term that the source's central argument or mechanism depends on, that the source names without fully explaining, and that a reader would need in order to follow the logical structure. Prefer techniques, data structures, protocols, standards, and mechanisms; skip people, companies, products, and generic words.
3. Before creating, search the vault for each keyword at the source's specificity (exact name, aliases, qualified variants). If a note covers the same concept, link it and create nothing; a broader parent note does not count as covering it.
4. For each remaining keyword, create a derived explanatory note by following the `note` skill in standard mode (vault root, filename `{Topic Name}.md`). Scope it to the concept as the source uses it and keep it compact; add a diagram only where a flow or structure needs one.
5. Keep the summary callout source-faithful. External knowledge belongs only in the derived note, never in the callout.
6. Tag each new note `#ai-agent-note` and end it with the Refs block below. Link the first mention of the keyword in the summary body to the new note, following the Linking Rules.
7. Create none when retrieval failed or the source's core claim could not be identified.
8. Extending an existing note, including filling an empty or thin one, is explicit-only. When the user asks, lightly consult primary sources such as official documentation, append a concise explanation, and mark it `#ai-generated`.
9. Report the created notes in the response to the user.

Refs block for the end of each derived note:

```md
## Refs

- Source: <article URL>
- Appeared in: [[<daily note or clipping note>]]
- <official docs, when consulted>
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
- When updating a daily note, add only one article-note Wikilink per topic entry. Do not hang concept notes beneath it as child bullets; inline concept links inside the summary callout follow the concept-linking rules below.
- Concept linking in summaries: identify the 1-3 concepts, technologies, or products that are central subjects of the source (not passing mentions). State each at the specificity the source uses, including its qualifier (the particular kind, variant, or use of the thing), and look it up in the vault before writing the summary. Search filenames and aliases with a real query rather than guessing a few names: the exact name first, then derived or qualified variants that contain it.
- Accept a match only when the note covers the same concept as the source's subject. Do not substitute a broader parent or umbrella note (a generic category the concept belongs to) just because it exists; that link is noise and hides the missing precise link. Link a general note only when the source itself discusses that general topic.
- Wikilink the first mention of each matched concept inside the summary block body, using the exact existing note name. Do not put Wikilinks in the callout title line.
- Link only to notes that exist at the time of linking. If no note matches at the source's specificity, do not fall back to a looser note and do not leave a dangling link. Keystone keywords get a derived note first (see Concept Note Workflow) and are then linked; for any other unmatched central concept, leave the term as plain text and mention it in the response to the user as a link candidate, not in the note.
- Do not turn every noun in a paragraph into a Wikilink.
- Never turn code, CLI commands, URLs, dates, or issue IDs into Wikilinks.

## Daily Note Update Workflow

1. When starting from a daily note and the topic is a bare URL with no existing clipped note target, insert a top-level callout immediately below the source line.
2. Keep the smallest possible diff around the original topic entry. Preserve existing supporting bullets or notes.
3. If the topic already points to an existing clipped note, update that note instead of adding another summary block to the daily note by default.
4. If a topic is skipped and no note is updated, add no extra structure beyond the failure log when needed.
5. Do not add another child Wikilink for a topic that is already clipped unless the user explicitly asks for a new separate note.

## Output Quality Bar

- Each processed link should become understandable within a few dozen seconds of reading.
- Reading only the summary block should make both the subject and its relevance clear.
- The summary should preserve the source's main utility. If the source is mainly valuable as a response guide, technical mechanism note, or argument, the summary must make that visible at a glance.
- The logical structure should reduce cognitive load, not increase it. If the nesting makes the note harder to scan, simplify the labels or the depth.
- Do not turn derived notes into encyclopedias. Scope them to the concept as the source uses it, so the next reread is efficient.
- A summarize-only update should let the reader grasp the article's thesis, value, and next-action shape from the opening block alone.

## Stop Conditions

- The source cannot be retrieved.
- The core claim cannot be identified.
- Existing notes are already sufficient and another summary pass would add noise.
- Summarize-only mode cannot resolve the target clipping note.
- The summary skeleton still obscures the source's dominant value after one simplification pass.

In those cases, do not force completion. Leave only the smallest useful failure log or skip rationale.
