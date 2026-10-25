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
    #### a. <trouble>                 trouble -> options table (an ID per option) -> cases (one per option) -> adopted (by ID) -> why
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
> **Structure**: the story section first (system, one example, troubles a, b, ... with ID-labeled options, the adopted ID, and reasons, parts and reading guide), then the nodes. Nodes distinguish chained from parallel. Node summary diagrams and the ledgers are in the appendix.
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

<one sentence on the option ID shape, for example: a-1-3 is trouble a, first decision, third option>

#### a. <trouble as a question>

**The trouble**: <what goes wrong, made concrete with the part 2 example>

**Options a-1**: <one sentence: what is being decided>

<premise block, only when the cells use a term or shape the story has not defined: one-sentence definitions as a list, the shapes involved, a short walk-through of what the options change>

| ID | Option | Good | Bad |
|---|---|---|---|
| a-1-1 | ... | ... | ... |
| a-1-2 | ... | ... | ... |

> <caption with source; mark trade-offs the records do not state as [inferred]>

**Cases a-1** (<the scenario, for example: the part 2 case under each option>; values are illustrative):

- **a-1-1**: <what happens in the scenario under this option; its good point and its bad point both show up>
- **a-1-2**: <same for the next option>

**Adopted a-1**: a-1-2 <short name; what was chosen, with the numbers and rules> [code: ...]

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

## Option IDs

Shape: `<trouble letter>-<decision number>-<option number>`. Always write all three parts; a trouble with one decision uses `-1-` (`b-1-1`). The decision label is the first two parts (`a-1`).

| Case | Write |
|---|---|
| Options in a table | `**Options b-1**`, an ID column (`b-1-1`, `b-1-2`), then `**Adopted b-1**: b-1-2 <short name>` |
| Several decisions in one trouble | number the decisions `a-1`, `a-2`; each has its own options and adopted labels; one why follows, citing the IDs it explains |
| Two-way choice in prose | IDs inline after each option: `**Options a-2**: <option> (a-2-1) or <option> (a-2-2) ...`, then `**Adopted a-2**: a-2-2 <short name>` |
| Decision that fits one paragraph | `**Decided j-3**: ...`; put option IDs inline where alternatives exist; none when the records name no alternative |
| Adopted answer combines options | name each: `**Adopted g-1**: g-1-1 and g-1-2 layered; g-1-3 is not used` |
| Source leaves the choice open | `**Adopted e-2**: undecided; the candidates are e-2-2 and e-2-3` |

- Name the adopted option by ID plus a short name. Never by position ("the third", "the latter") or a bare number.
- Cite an option by its ID wherever it comes up again: diagram nodes, the why, later nodes, ledgers, attainment answers.
- Option IDs start with a lowercase letter, so they do not collide with source IDs (`plan-§6`, `epic-D3`) or ledger IDs (`L1`).
- After delivery, keep IDs stable (reader comments and later nodes cite them). Append a new option at the end; do not renumber.

## Premise before the options

A table cell is a bad place to meet a term for the first time: the reader cannot stop to look it up, and the row reads as a leap. Before writing an options table, list the terms, identifiers, and shapes its cells use, and check where each was defined in the story section.

- A term the story section has not defined goes into a premise block between the `Options` label and the table: a short list of one-sentence definitions (with a provenance label), then the shapes the options differ on (JSON, a small table), then a walk-through that plays the difference out once.
- A definition that exists only in a later node, in a hook, or in a clause far above does not count. Design-specific shapes are shown here, not pushed to a hook or another note.
- When the premise block already plays the options out, the case list covers only the points it did not show and points back to it.
- Mark a definition `[inferred]` when it is the note's own gloss; do not narrow a source's term (for example "work record" is the whole GEN item, not only its progress fields).

## Cases

Pros and cons alone do not let the reader picture what happens. After every options table (or prose options), add a case list, before the adopted line.

- One bullet per option ID, the adopted option included, so the reader sees what it costs as well as what it buys.
- Play each option out in one concrete scenario, the part 2 example by default (its times and field values), and show both the good point and the bad point as things that happen: a message that arrives, a record that is overwritten, a number that is reused. Name the scenario in the label; mark illustrative values.
- Add no fact, mechanism, or step beyond the options table and the sources. Where the table marks a point `[inferred]` or says the records hold none, the case carries the same mark or says so. Cite a source only for a fact the table does not already carry.
- A case that restates the table in other words is not a case; replace it with a scenario.
- A decision labeled `Decided` that names no alternative has no cases. When a premise block already plays the options out (definitions, shapes, a walk-through), the case list covers only the points it did not show and points back to it.

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

## Commit walkthrough (when the note walks commits)

````markdown
### C3 <sha> <short title>

`git diff <parent>..<sha>`. Serves d and g: <one or two sentences tying it to the story>.

```diff
+  def record(message_id)
# [解説] <what this block is for, what it does, and why, in one to three sentences>
+    updated = begin
+      write_send
+    rescue StandardError => e
+      return record_failed(message_id, e)
+    end
# [解説] (<what was left out>, omitted)
```

Spec: <what the cases below pin down, in one sentence>

```diff
# [解説] <why this case is essential>
+  it "answers sent when logging fails after the row was written" do
```
````

Lines marked `# [解説]` are the note's own; say so once at the top of the section.

## Hook

```markdown
> [!question]- 🪝 <the technical property assumed as known>
> Without this, the next step will look like a leap. If you already know it, skip; to ask, rewrite the request below or add your own `.o0:` line under it.
> .o0: <request the reader can activate>
```

Place it where the property is used; at most one per node. The `.o0:` line is a `bump` token. A pre-filled request may read as pending to `bump`; the folded callout is the reader's entrance, so keep the request short and specific. The comment watch baselines pre-filled requests at delivery; a rewritten request or an added `.o0:` line under the hook is taken as the reader's comment (`references/comment-watch.md`).

## Attainment check

- 5 to 7 questions that ask whether the reader can derive the design, not whether they can name terms.
- The answers exist in the body; the questions do not appear in the body.
- Append in parentheses the node to go back to for each question.
- Under each question, add a model answer in a folded callout, so the reader opens it only after trying. Answer only from the body and the sources, keep the conditions and the provenance labels, and do not state anything more strongly than the body does:

  ```markdown
  **Q1.** <question> (back to ③)

  > [!success]- Model answer
  > <3 to 6 lines with provenance labels>
  ```

- Add it once, after all nodes. The model answers are in scope of the Phase 4 independent fact check.

## Provenance-label legend (at the end)

| Label | Meaning |
|---|---|
| `[recorded]` | Stated in a PR, ADR, dialogue log, design document, or decision record |
| `[code]` | Verifiable from code, tests, or execution results |
| `[inferred]` | Not in records or code; a candidate to confirm with the author |

Input priority for the "why": author's records, then commits and review history, then code and tests, then inference.

Source abbreviations (pinned): list each source with its location and version (commit, merged PR, note section). Mark temporary sources (for example files under `/tmp`) and say when one has vanished.
