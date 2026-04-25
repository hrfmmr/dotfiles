---
name: report
description: >
  Author or proofread team-facing research reports in an Obsidian vault.
  Supports both rewriting existing notes and composing new investigations from scratch.
  Fixed template structure (Background, Problem Setup, Key Points, Methodology,
  Findings, Options, Details, Conclusion) enforced with plain language, mermaid diagrams,
  and inline evidence URLs throughout.
  Use when user says "/report", "write a report", "proofread this report",
  "restructure for the team", "organize this research", or wants to produce a
  team-facing research report in the Obsidian vault.
  Trigger on report, team report, research report, proofread report, investigation summary.
---

# report

## Overview

Produce team-facing research reports at a consistent quality bar.
Every report is structured for comprehension: a clear narrative arc, plain language, and diagrams that anchor the reader's mental model.

## Modes

| Mode | Trigger | Input |
|------|---------|-------|
| **Proofread** | Pass an existing note path | Existing `.md` file + editorial guidance (audience, etc.) |
| **Compose** | Pass a topic + investigation brief | Topic name, methodology, background context |

## Invocation

```
/report <existing-note.md>                     # proofread mode
/report <topic> -- <investigation brief>       # compose mode
/report <existing-note.md> --audience <tier>   # explicit audience
```

## Prerequisites

- cwd is an Obsidian vault.
- For compose mode requiring primary-source research: WebSearch / WebFetch must be available.

## Workflow

### Step 0: Confirm the audience tier

If not specified via arguments, determine the audience:

| Tier | Characteristics |
|------|----------------|
| Engineers | Include technical detail. Define jargon on first use. |
| Mixed (engineers + non-engineers) | Push technical detail to appendices; foreground business-decision material. |
| Executives / decision-makers | Lead with conclusions and impact. Minimize technical background. |

### Step 1: Analyze input

#### Proofread mode
1. Read the existing note.
2. Map current structure against the template; identify gaps.
3. Restructure to the template while preserving all original data, evidence, and findings.

#### Compose mode
1. Derive required information for each template section from the topic and methodology.
2. Collect primary sources via WebSearch / WebFetch.
3. Organize collected material into the template.

### Step 2: Write to the template

Use the fixed section structure below. Sections may be omitted when irrelevant, but **Background, Key Points, and Conclusion are mandatory**.

---

#### Section Template

```
## 1. Background & Purpose
   - Why this investigation is necessary (framed so teammates grasp its relevance)
   - What this investigation aims to clarify (mermaid diagram of the question structure)

## 2. Prerequisite Review (Problem Setup)
   - Full map of related rules, constraints, and technical assumptions (mermaid)
   - Summary of what each prerequisite demands of the current topic (table, plain language)
   - Inline evidence URLs

## 3. Key Points — What Matters
   - The boundary between OK and NG
   - Most authoritative official positions / decision criteria (quote blocks with original text)
   - Decision-flow diagram (mermaid)

## 4. Methodology
   - Investigation procedure (mermaid flowchart)
   - Scope and limitations

## 5. Findings Summary
   - Key discoveries in a comparison table
   - Inline evidence URLs per item
   - Conformance ratings where applicable: ◎ / ○ / △ / ❌

## 6. Options Overview
   - Bird's-eye view of available options (mermaid map)
   - Summary table (one-line description + recommendation level)

## 7. Option Details
   - Subsection per option
   - Architecture diagram (mermaid) for recommended options
   - Advantages, prerequisites, and concerns stated explicitly
   - Required mitigations listed when applicable

## 8. Summary & Conclusion
   - Conclusion diagram (mermaid: question → answer → recommended config → rationale)
   - Rationale summary table
   - Next Steps — items to verify (table: item / contact / reason)

## References
   - Categorized: government guidelines / vendor docs / industry guides / articles
   - Consolidate all inline-cited sources into this list
```

### Step 3: Writing rules

#### Language & tone
- Always write in Japanese. Code blocks, identifiers, and URLs are exempt.
- Use polite style (ですます調) consistently. Do not use abrupt endings (体言止め) or academic style (である調).
- Define jargon on first occurrence; spell out abbreviations in full on first use.
- Adjust detail depth to the audience tier confirmed in Step 0.

#### Mermaid diagrams
- Use liberally. Include at least four:
  1. **Background** — question structure
  2. **Prerequisites** — rule/constraint map
  3. **Key Points** — decision flow (OK/NG branching)
  4. **Conclusion** — conclusion structure
- Add architecture, comparison, or process diagrams as content warrants.
- Wrap Japanese node labels in double quotes inside mermaid blocks.

#### Evidence
- Cite sources inline within each section.
- Also list all sources in the References section (categorized).
- Prefer primary sources (official docs, government publications).

#### Tables
- Use tables for comparisons, inventories, and evaluations.
- Use ◎ / ○ / △ / ❌ for conformance ratings to aid visual scanning.

### Step 4: Desk-task integration

When invoked as a derived note from a desk task:

1. **Tag inheritance**: Copy all `#prj-*` tags from the parent task note's first line to the derived note's first line.
2. **prior/related link**: Add a wikilink to the parent task note in `prior:`.
3. **Turn-N callout**: Append a derived-note callout in the parent's Turn-N:
   ```markdown
   > [!note] 派生ノート
   > [[derived-note-name]]
   ```

Skip these steps when invoked independently of a desk task.

### Step 5: Output & verification

1. Write to vault root.
2. Proofread mode: overwrite the existing file.
3. Compose mode: use the topic name as the filename.
4. Self-check against the template:
   - Mandatory sections (Background, Key Points, Conclusion) present
   - At least 4 mermaid diagrams
   - Inline evidence URLs + consolidated References section
   - Tables used where appropriate

## Quality Checklist

Verify all items before reporting completion. Fix any failures before finishing.

- [ ] Mandatory sections (Background, Key Points, Conclusion) present
- [ ] Mermaid diagrams in 4+ locations
- [ ] Jargon defined in plain language on first use
- [ ] Evidence URLs inline in every section
- [ ] References section at the end
- [ ] Comparison tables used for evaluations
- [ ] Detail depth matches the audience tier
- [ ] Desk integration (tag inheritance, wikilinks) applied when applicable
