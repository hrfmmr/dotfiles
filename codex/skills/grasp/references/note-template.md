# Reading-note template

## Skeleton

```
#ai-agent-note                       (keep only if the vault uses this tag)
# <title>
> [!info] Reading setup               reader, format, structure, prerequisites, hook rule, how hooks work, label legend pointer, progress
---
## Map
  intro paragraph, link to the overall structure diagram
  nested outline                      node: gloss / outcome line / diagram link
  ### Diagrams (per main topic)        overall structure diagram + one summary diagram per node
  ### Ledger                          items not put on the map, with classification and reason
  ### Shared-object ledger            object, source of shape, introduction node, later deltas
  ### Coverage table                  which node covers each axis (final pass)
---
## ① entry node (root)                 starts from a low-context overall picture (minimal diagram)
### ①-n ...
## ② ... (chained chain)   ## ③ ... (parallel, independent thread)
## ④ landing                          design decisions -> implementation (file:line) / what remains / return to the starting question
## Attainment check                   5 to 7 questions
## Provenance-label legend            at the end
## Related
```

## Settings callout

```markdown
> [!info] Reading setup
> **Assumed reader**: <who; a reader who is the author revisiting later forgets details and the "why">
> **Format**: teacher-student dialogue. Callouts are `[!quote] 🧑‍🎓 Student` / `[!abstract] 👨‍🏫 Teacher`. Deliver each node whole and at once. Figures and code sit outside callouts, followed by a one-line caption. Put a diagram on the spot for each dynamic point in the dialogue.
> **Structure**: ID-anchored nested bullets. Distinguish chained from parallel. Topics left off the map go in the ledger.
> **Prerequisites**: no dedicated prerequisites node; pick each one up with a hook where it is used. Only the entry node opens with a minimal overall picture.
> **Hook scope**: only a concrete technical term, API, SDK, or SaaS feature that the logic cannot proceed without.
> **Provenance labels**: `[recorded]` / `[code]` / `[inferred]` (legend at the end).
```

## Map bullets

```markdown
- **① <title>** (root)
  - **Gloss**: <trouble and how it is resolved, plain language; expand jargon at first use>
  - **Outcome**: <what the reader can do after this node>
  - **Diagram**: [[#Diagrams ① <short title>]]
  - **①-1 <title>** (<what it bridges>)
    - **Gloss**: ...
    - **Outcome**: ...
    - **Diagram**: [[#Diagrams ①-1 <short title>]]
```

Heading links need the exact heading text. Keep diagram headings short: `#### Diagrams ①-1 <short title>`.

## Ledgers

Out-of-scope ledger (classification of items not on the map; every row decided):

| # | Item | Source | Decision | Reason |
|---|---|---|---|---|
| L1 | ... | epic D4 | node (①-2) / premise (one sentence, where) / out of scope | reason |

Shared-object ledger:

| Object | Source of shape | Introduction node | Later deltas |
|---|---|---|---|
| `<object>` | `<source, e.g. design doc §6>` | `<node, e.g. ②-1>` | `<what later nodes add>` |

Coverage table (final pass): axis, nodes that cover it, note (out of scope with reason, or undesigned).

Use a different ID prefix for your own ledger rows than the sources use (for example `L1`, not `K1`).

## Node skeleton

```markdown
### ①-1 <title>

**Current position**: ①-1 (<where in the map>). What is established so far: <one line>.

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
