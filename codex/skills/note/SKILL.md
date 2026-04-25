---
name: note
description: >
  Create learning-oriented derived notes in an Obsidian vault for technical topics and concepts.
  Use when the user asks "what is X?", "explain X", "create a derived note on X", or otherwise requests a prerequisite-enriched explanation of a specific topic.
  The `discuss` option produces a teacher-student dialogue-style note.
  Trigger on "what is ~", "explain ~", "derived note", "learning note", "dialogue format", "discuss", or any request for a technical concept explanation.
---

# note

## Overview

Create a dedicated learning derived note in the Obsidian vault in response to questions or explanation requests about technical topics and concepts.
Supplement prerequisite knowledge thoroughly and use mermaid diagrams proactively for interactions and flows to make concepts easier to grasp.

## Workflow

### 1. Mode Selection

Determine the mode from arguments or user instructions.

| Mode | Trigger | Output Format |
|---|---|---|
| **standard** (default) | No `discuss` specified | Reference-style explanatory note |
| **discuss** | `discuss` argument, "dialogue format" instruction, etc. | Teacher-student dialogue-style note |

### 2. Topic Identification

- Identify the topic from the user's question.
- Search for existing notes in the vault (to prevent duplicates).
- If an existing note is found, decide whether to propose an update or create a new deeper-dive derived note.
- **discuss mode**: If a parent note is specified, cover all concepts that appear in it.

### 3. Note Creation

#### 3a. standard mode

- Filename: `{Topic Name}.md`
- Location: vault root
- First line: Inherit `#prj-*` tags from the parent task note (when in a desk-live session). Omit if no such tags exist.

Structure template:

```markdown
{#prj-* tags (if any)}

# {Topic Name}

## Prerequisites

{Thorough explanation of foundational concepts needed to understand the topic}

## {Core Topic Explanation}

{Core explanation. Structured to progressively deepen understanding.}

## Diagrams

{mermaid flowchart / sequence diagram / state diagram etc. for visual explanation}
{Required when there are interactions, flows, state transitions, or other elements where diagrams are effective}

## Related Commands / Options (if applicable)

{Comparison with similar commands or alternatives}

## Context for Current Work (if applicable)

{How this topic relates to the current task}
```

#### 3b. discuss mode

- Filename: `{Topic Name} Dialogue-Based Overview.md`
- Location: vault root
- First line: Inherit `#prj-*` tags from the parent note.

Structure template:

```markdown
{#prj-* tags (if any)}

# {Topic Name}: Dialogue-Based Overview

parent: [[{Parent Note Name}]]

> This dialogue explains the content of [[{Parent Note Name}]] as a teacher-student conversation.

> [!info] How to Read This Document
> **Purpose**: {one-line description of what this tutorial covers}
>
> **Audience**: {target audience}
>
> **Prerequisites**: {prerequisites with Wikilinks}
>
> **Metaphor**: {metaphor used throughout, if any}

---

## Topic Map for This Dialogue

This dialogue covers N topics in the following order: {flow description}.

{mermaid graph TB showing all chapter topics linked in dependency order}

| # | Topic | Question Answered |
|---|------|-------------------|
| **①** | **{Topic}** | {Question this chapter answers} |
| **②** | ... | ... |

> {One-line reading guide, e.g., reading from top to bottom builds understanding from "why" to "what" to "how to protect it."}

---

## ① {Motivation / Problem to Solve}

> [!quote] 🧑‍🎓 Student
> {Naive question}

> [!abstract] 👨‍🏫 Teacher
> {Breaks down the background of the problem}

{mermaid diagram if applicable}

> {One-line summary caption after the diagram}

> [!quote] 🧑‍🎓 Student
> {Student restates in own words}

---

## ② {Topic for Each Concept}

{Progressive deep-dive through dialogue, using the same callout pattern.}
{Use `---` between distinct Q&A exchanges within the same chapter.}

---

## Summary: Big Picture Map

> [!quote] 🧑‍🎓 Student
> {Request for summary}

> [!abstract] 👨‍🏫 Teacher
> {Introduces the map}

{mermaid diagram — bird's-eye view of relationships between concepts}

> {One-line caption for the map}

> [!quote] 🧑‍🎓 Student
> {Summary of what was learned — genuine reinterpretation, not repetition}

> [!abstract] 👨‍🏫 Teacher
> {One-sentence distillation of the essence}
```

Writing rules for discuss mode:

- **Callout format**: Use Obsidian callout blocks for all dialogue. Student: `> [!quote] 🧑‍🎓 Student`. Teacher: `> [!abstract] 👨‍🏫 Teacher`. Never use `**Student**:` / `**Teacher**:` bare text.
- **Chapter numbering**: Use circled numbers (①, ②, ③, ...) for chapter headings, not `Chapter N:`.
- **Topic map**: Place a mermaid `graph TB` and a summary table at the top, before the first chapter. This gives readers a bird's-eye view of the structure.
- **Separators**: Use `---` between distinct Q&A exchanges within a chapter. Each chapter heading also has `---` before it.
- **Diagram captions**: After every mermaid diagram or code block, add a `>` blockquote summarizing the key takeaway in one line.
- **Chapter structure**: Divide chapters along concept dependencies. Order so that knowledge from earlier chapters serves as prerequisite for later ones.
- **Dialogue tone**: The teacher is polite but casual. The student asks naive questions without hesitation.
- **Metaphor consistency**: Reuse the same metaphor across chapters. Do not reset when introducing a new metaphor.
- **Embedded figures**: Insert comparison tables and mermaid diagrams naturally within the dialogue flow. Do not create standalone sections solely for diagrams.
- **Student insights**: At the end of each chapter, the student restates the key points in their own words — a genuine reinterpretation, not a repetition of the teacher's explanation.
- **Summary chapter**: In the final chapter, present a mermaid graph as a map of the big picture, providing a bird's-eye view of connections between concepts.

### 4. Content Quality Standards (both modes)

- Explain progressively from prerequisites so the reader understands "why it works that way."
- Provide a concise definition when a technical term first appears.
- Use comparison tables to clarify differences between options.
- Mermaid diagrams are required for:
  - Process flows (flowchart)
  - Inter-component interactions (sequence diagram)
  - State transitions (state diagram)
  - Configuration comparisons (flowchart with branching)

### 5. Wikilink Placement

- Place links to the created derived note in an Obsidian callout block for visibility:
  ```markdown
  > [!note]
  > [[{Note Name}]]
  ```
- Placement: Near where the topic was mentioned in the original conversation.
- During a desk-live session, append the callout inside the relevant Turn-N of the task note.
- Follow the `$obsidian` skill's Linking Policy; avoid excessive links.

### 6. Integration with Existing Skills

- Comply with the `$obsidian` skill's Linking Policy when creating notes.
- When invoked during a desk-live session, Turn-N recording is the caller's (desk-live) responsibility. This skill only handles note creation.
