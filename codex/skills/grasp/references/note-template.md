# Reading-note template

## Skeleton

```
#ai-agent-note                       (keep only if the vault uses this tag)
# <title>
> [!info] Reading setup               reader, format, structure, prerequisites, hook rule, how hooks work, label legend pointer, progress
---
## Before reading: what was the trouble, and how was it solved      (story section; prose, not dialogue)
  > [!summary] summary callout         the whole story in about five sentences
  ### 1 What the system does          cast and flow in one diagram; terms defined where first used
  ### 2 One example, end to end       per-step field table + sequence diagram, success path and one failure path
  ### 3 The troubles and how each was solved
    #### a. <trouble>                 trouble -> options table -> adopted -> why
    #### b. ...
  ### 4 Parts and reading guide       parts table (what / troubles solved / node), reading order, overall structure diagram
---
## ① root node                        maps the artifact's units (commits, sections, steps) to the nodes; current position points back to the story section
### ①-n ...
## ② ... (chained chain)   ## ③ ... (parallel, independent thread)
## ④ landing                          design decisions -> implementation (file:line) / what remains / return to the starting question
## Attainment check                   5 to 7 questions
## Where feedback is wanted          place and question, in a table
## Appendix A Node summary diagrams   one per node, linked from story part 4
## Appendix B Ledgers                 out-of-scope ledger, shared-object ledger, coverage table (final pass)
## Provenance-label legend            at the end, with the pinned source abbreviations
## Related
```

## Settings callout

```markdown
> [!info] Reading setup
> **Assumed reader**: <who; a reader who is the author revisiting later forgets details and the "why">
> **State**: as of <date>, <target> at <commit or version>. Line numbers refer to it.
> **Format**: the story section is prose; the nodes are teacher-student dialogue. Callouts are `[!quote] 🧑‍🎓 Student` / `[!abstract] 👨‍🏫 Teacher`. Deliver each node whole and at once. Figures and code sit outside callouts, followed by a one-line caption. Put a diagram on the spot for each dynamic point in the dialogue.
> **Structure**: the story section first (system, one example, troubles a, b, ... with options and reasons, parts and reading guide), then the nodes. Nodes distinguish chained from parallel. Node summary diagrams and the ledgers are in the appendix.
> **Prerequisites**: no dedicated prerequisites node. The story section defines terms where they first appear; nodes pick up technical prerequisites with a hook where they are used.
> **Hook scope**: only a concrete technical term, API, SDK, or SaaS feature that the logic cannot proceed without.
> **Provenance labels**: `[recorded]` / `[code]` / `[inferred]` (legend at the end).
```

## Story section

Plain, direct sentences; one idea per sentence; no metaphors or analogies. Define each term in one sentence where it first appears.

```markdown
## Before reading: what was the trouble, and how was it solved

> [!summary] The story in five sentences
> 1. <what the system does, one sentence>
> 2. <what goes wrong without this change>
> 3. <what this change adds>
> 4. <the key mechanism that keeps it correct>
> 5. <how people notice when it goes wrong>

### 1 What the system does

<cast and flow in prose; each term defined in one sentence at first use>

<one flowchart of the cast and the flow>

> <caption with source>

### 2 One example, end to end

<the case, marked illustrative; list the fields the table shows, each with a one-sentence meaning>

| Step | What happened | <field 1> | <field 2> | ... |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

> <caption with source; values are illustrative>

<sequence diagram of the same steps>

> <caption>

<same again for one failure path>

This example contains several troubles this change solves: <list>. Part 3 shows why each takes this form.

### 3 The troubles and how each was solved

<one sentence: which troubles an upstream change already solved, and which this change solves>

#### a. <trouble as a question>

**The trouble**: <what goes wrong, made concrete with the part 2 example>

**Options**:

| Option | Good | Bad |
|---|---|---|
| ... | ... | ... |

> <caption with source; mark trade-offs the records do not state as [inferred]>

**Adopted**: <what was chosen, with the numbers and rules> [code: ...]

**Why**: <reason> [recorded: ...]

<one diagram when the item discusses flow, comparison, or branching>

> <caption with source>

### 4 Parts and reading guide

| Part | What it does | Troubles solved | Node |
|---|---|---|---|
| ... | ... | a, c | ② |
| ... | ... | prerequisite | ④ |

> <caption with source>

- **① <title>**: <what to look at there> ([[#Diagram ① <short title>]])
- ...

<overall structure diagram: reading order and dependencies, chained solid, parallel dashed>

> <caption: which shared identifiers confirm each dependency>
```

Heading links need the exact heading text. Keep the appendix diagram headings short: `#### Diagram ①-1 <short title>`.

## Ledgers

Ledgers go in the appendix. Out-of-scope ledger (classification of items not put in the story section or a node; every row decided):

| # | Item | Source | Decision | Reason |
|---|---|---|---|---|
| L1 | ... | epic D4 | story item (3-b) / node (①-2) / premise (one sentence, where) / out of scope | reason |

Shared-object ledger:

| Object | Source of shape | Introduction node | Later deltas |
|---|---|---|---|
| `<object>` | `<source, e.g. design doc §6>` | `<node, e.g. ②-1>` | `<what later nodes add>` |

Coverage table (final pass): axis, story items and nodes that cover it, note (out of scope with reason, or undesigned).

Use a different ID prefix for your own ledger rows than the sources use (for example `L1`, not `K1`).

## Node skeleton

```markdown
### ①-1 <title>

**Current position**: ①-1 (<where in the reading order>). What is established so far: <one line; the root node points back to the story section>.

> [!quote] 🧑‍🎓 Student
> <question that is the entrance to a branch point>

> [!abstract] 👨‍🏫 Teacher
> [recorded] <answer with provenance label> [recorded: <source pointer>]

<concrete shape first: table, JSON, code>

> <one-line caption with source and "values are illustrative" when they are>

<diagram right after the answer that discusses flow, time, structure, state, comparison, or branching>

> <one-line caption with source>

**What this establishes**: <summary>

**Where this connects next**: <which node this leads to>
```

## Hook

```markdown
> [!question]- 🪝 <the technical property assumed as known>
> Without this, the next step will look like a leap. If you already know it, skip; otherwise write below.
> .o0: <request the reader can activate>
```

Place it where the property is used; at most one per node. The `.o0:` line is a `bump` token. A pre-filled request may read as pending to `bump`; the folded callout is the reader's entrance, so keep the request short and specific.

## Attainment check

- 5 to 7 questions that ask whether the reader can derive the design, not whether they can name terms.
- Answers exist in the body; the questions do not appear in the body.
- Append in parentheses the node to go back to for each question.
- Add it once, after all nodes.

## Provenance-label legend (at the end)

| Label | Meaning |
|---|---|
| `[recorded]` | Stated in a PR, ADR, dialogue log, design document, or decision record |
| `[code]` | Verifiable from code, tests, or execution results |
| `[inferred]` | Not in records or code; a candidate to confirm with the author |

Input priority for the "why": author's records, then commits and review history, then code and tests, then inference.

Source abbreviations (pinned): list each source with its location and version (commit, merged PR, note section). Mark temporary sources (for example files under `/tmp`) and say when one has vanished.
