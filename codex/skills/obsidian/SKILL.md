---
name: obsidian
description: Create or update notes in this Obsidian vault while aligning them with the vault's knowledge graph through deliberate, high-signal Wikilinks. Use when writing or editing Obsidian notes in this project and you need disciplined link placement rather than blanket `[[...]]` expansion.
---

# obsidian

## Overview

Create and revise Obsidian notes so they connect cleanly to this vault's information graph.
Do not spray `[[...]]` throughout the body. Link only the highest-value occurrences and avoid backlink noise caused by mechanically linking every mention.

## Core Rule

- Do not automatically turn every important keyword into `[[xxx]]` each time it appears in the note.
- Use Obsidian Wikilinks `[[xxx]]` only where the relationship between this note and that node matters most.
- The highest-value location is typically where the note first explains how it relates to that node, such as in the opening summary or the first framing statement.
- Always tag agent-created notes with `#ai-agent-note` so they remain discoverable through cross-vault search.
- Treat a term as important when it matches at least one of these conditions:
  - a technical term
  - a service name
  - a tool name
  - a proper noun that already has a note in the vault
  - a concept likely to be revisited
  - a unit that meaningfully stands on its own as a graph node

## Linking Policy

1. Check for an existing note first.
2. If a note already exists, match its title exactly with `[[Existing Title]]`.
3. If it materially improves Japanese readability, `[[Existing Title|Display Text]]` is acceptable.
4. Even if no note exists yet, you may write `[[Proposed New Title]]` when the concept is highly likely to become a reusable node.
5. In side explanations, elaborations, paraphrases, and later re-mentions, prefer plain text.
6. Do not force links onto temporary terms, overly context-bound phrases, or low-reuse modifiers.

## Note Creation Workflow

1. Search for related existing notes before creating a new one.
2. Once you confirm the note is new, place `#ai-agent-note` near the top.
3. Review the title, opening summary, and related sections to identify reusable concepts.
4. Link only the concepts that define the note's context.
5. Prioritize links in these locations:
   - the opening summary
   - the related-notes section
   - the text that defines what the note is about
   - the first sentence that explains the note's relationship to that node
6. Never turn code, commands, paths, environment variables, or issue IDs into `[[...]]`; keep them in code formatting instead.

## Search Heuristics

- Start with titles that are close to an exact match.
- If no exact match exists, check synonyms and spelling variants.
- When multiple candidate notes exist, prefer the more general and more reusable title.
- Even for major concepts already established in this vault, such as `beads` or `Dolt`, link only at the most important occurrence.

## Writing Heuristics

- Even if several concepts seem link-worthy, do not scatter links across the entire body.
- In the main prose, place the link at the first framing occurrence and continue the explanation in plain text.
- If the same concept reappears in a later section, do not usually link it again.
- Keep `#ai-agent-note` as a single identification tag for new notes; do not duplicate it elsewhere in the body.
- Create a related-notes section when it helps, and surface the primary references there.
- For searchability and consistency, align link targets with the canonical titles of existing notes.

## Do Not

- Do not mechanically link every occurrence of a concept that already has a note.
- Do not force links onto non-node material such as code fragments, CLI options, or file paths.
- Do not multiply variant spellings of the same link target; use one stable title per concept.
- Do not write in a way that causes backlink panes to fill with low-value side remarks.
