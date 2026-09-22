---
name: grasp
description: >
  Guide a human to actually understand a large design, plan, or implementation (usually agent-made)
  before they review or approve it, by producing an Obsidian reading note: a nested map,
  teacher-student dialogue, concrete shapes, inline diagrams, coverage gates, and an attainment check.
  Use when the user wants to understand, work through, or be briefed on a big design, ADR, epic,
  plan, or implementation; asks to make sense of it or produce a "reading note";
  says "guide me through this design" or "briefing before approval"; or asks to explain a design with a map and diagrams.
  Explanation, not critique: do not use for bug hunting or approval decisions (critique, review),
  single-concept explanations (note), or diff-only walkthroughs (crit-explain, hunk-present).
---

# Grasp

Produce a reading note that lets the reviewer derive the design, not just recognize it.
The human keeps the job of assembling understanding; the note supplies the map, the concrete shapes, the diagrams, and the checks.

Definition status: draft, validated once end to end. Rationale and history live in `references/lineage-and-antipatterns.md`.

Write headings and dialogue in the language of the source material and the reader; the English labels below (`recorded`/`code`/`inferred`, Student/Teacher, node-rule names) are the defaults to adapt.

## Scope

- Mode: reading an existing artifact. Authoring support is out of scope.
- Inputs: the design document, upstream decision records (epic, task note, ADR, decision log), and the implementation or its plan.
- Output: one Obsidian note (map, nodes, ledgers, attainment check). Keep the user's design log in sync when they maintain one.
- Never: hunt for bugs, decide whether to approve, or do the understanding for the reader. Explain; do not criticize.

## Principles

1. Build the reader's mental shape first and keep it up while they read: minimal overall picture, plain-language gloss, diagrams, concrete shapes.
2. Leave the assembling of understanding to the human: hooks are optional, the attainment check asks "can you derive it", the interview is up front, approval stays with the human.
3. Give the reader a fast way back from a local "I don't get this". Use hooks for technical prerequisites only; explain the core plot in the body.
4. Label provenance on every "why": `[recorded]` (stated in a PR, ADR, dialogue log, or design doc), `[code]` (verifiable from code, tests, or output), `[inferred]` (inference; a candidate to confirm with the author).
5. Check coverage and concreteness by procedure, never by the writer's head. What is obvious to the writer is what gets dropped.
6. Record what is dropped. Keep an out-of-scope ledger and show what remains outside approval.
7. Deliver in one pass, state where feedback is wanted (location and question), and decide open items with recommendation-bearing native asks.

## Workflow

```
Phase 0 interview -> Phase 1 sources -> Phase 2 map draft -> GATE A -> Phase 3 write nodes -> GATE B -> Phase 4 verify -> Phase 5 finish -> Phase 6 operate
                                                               ^                                                                         |
                                                               +---------- re-run in diff mode whenever the map or a node changes -------+
```

### Phase 0. Interview

Ask three things with AskUserQuestion, recommended option first:

- Reader and assumed knowledge. When the reader is the author revisiting later, treat the prerequisite inventory as "recall versus re-read", and assume they forgot the details and the "why".
- Scope: design only, or design plus implementation. Call unfinished implementation "plan".
- Pace: all at once, node by node, or hybrid. Default to node by node unless the user says all at once.

### Phase 1. Collect sources

- Do not rely on one design document. Gather (a) upstream decision records: decisions, rejected alternatives, facts, insights; (b) the design document's table of contents; (c) implementation steps; (d) the source's own success criteria.
- Build a decision inventory from all of them. The path from requirements to the final structure lives in the upstream records, not in the design document.
- List shared objects (data models, table definitions, event or API formats, configuration, state transitions) and assign each an introduction node: the first node that uses it.
- Note where records are thin. Those places become `[inferred]` when written.

### Phase 2. Draft the map

1. Count branch points, then cut to a budget of 5 to 8 nodes: count, cut, then map.
2. Verify dependencies between nodes against the sources. Grep for identifiers shared by the two sections to confirm the dependency exists and what is handed over. Do not decide chained versus parallel by re-reading alone.
3. Build a nested, ID-anchored outline (unpack style): root, chained children (use the previous node's conclusion), parallel siblings (independent; light cross-references allowed).
4. Under each node add a **gloss** (plain-language: the trouble and how it is resolved; expand jargon at first use), an **outcome line** (what the reader can do after this node), and a link to its diagram. Keep the top-level line compressed.
5. Open with a low-context overall picture at the entry node: minimal diagram and cast of characters. Do not use a prerequisites block or a dedicated prerequisites node.
6. Add an overall structure diagram and one summary diagram per node in a "Diagrams" section of the map; link each node to its diagram.

### GATE A. Coverage review

Run the review in `references/coverage-review.md` before writing any node, and do not write nodes until it passes.
In short: diverge from the purpose over 15 axes before looking at the map; merge with the source inventory; classify every item as node, premise (one sentence and where), out of scope (with reason), or unclassified; check bias types; ask the four hidden-premise questions per element; fix; present the result and decide classifications with native asks that carry recommendations.
Re-run in diff mode whenever the map or a node is added, changed, or removed, and once more before the attainment check.

### Phase 3. Write nodes

Follow the node rules below. Write one node at a time unless the user asked for all at once.

### GATE B. After each node

- Source check: compare each `[recorded]` claim with the source line. Check identifiers, numbers, and causal links. Illustrative values (times, quantities) must not contradict the design's other numbers.
- Reference direction: "seen in X" points only to earlier nodes; use "will see in X" for later ones.
- Figure check: every answer that talks about structure, flow, time, state transitions, comparison, or branching has a diagram right after it.
- Fix before moving on. Writers naturally invent connective claims the source does not contain.

### Phase 4. Verify mechanically

Run `scripts/check_note.py` (fences, JSON, links, figure adjacency, text timelines, missing diagrams, identifier shapes, reference direction) and `scripts/render_mermaid.py` (real rendering), then open the images and look at them. See `references/checks.md` and `references/diagrams.md`.

### Phase 5. Finish

- Re-run Gate A as the final pass and fix the coverage table.
- Show what remains outside approval: pending measurements, intentionally deferred items, undesigned areas, and places where the sources disagree with each other.
- Add the attainment check once: 5 to 7 questions that ask whether the reader can derive the design. Answers exist in the body; the questions do not. Point each question to the node to go back to.
- Put the provenance-label legend at the end.

### Phase 6. Operate

- Tell the user where feedback is wanted: place and question, in a table.
- When the user keeps a design log, append an entry whenever the deliberation changes (feedback, verification result, correction). Never rewrite past entries; add a new one that supersedes.

## Node rules

Each node has: heading with nest ID; a current-position line (what is established so far); dialogue; concrete shapes; diagrams; provenance labels with source pointers; 0 to 1 hooks; and two closing lines, "what this establishes" and "where this connects next" (which node it leads to).

- **Dialogue.** Teacher and student, delivered whole and at once. Never stop mid-node to hide answers. Student questions are the entrances to branch points.
- **Core plot in the body.** The "why" that drives the story is explained, not delegated to a hook. There is no separate prerequisites node; prerequisites are supplied where they are used.
- **Concrete first (static shapes).** Before abstract explanation, show the schema, JSON, code, real data, or table. Show a shared object at its introduction node with shape and example; later nodes add only deltas; keep the whole picture in a quick-reference table. Mark example values as illustrative. When the source does not fix a shape (for example an attribute name), say so with `[inferred]`. Showing concrete shapes exposes gaps and contradictions in the source; report them.
- **Diagram on the spot (dynamic relations).** Right after the teacher's answer that discusses structure, flow, time, state transitions, comparison, or branching, put one diagram, outside the callout, followed by a one-line caption with the source. One point per diagram. Replace text timelines with diagrams. The map's summary diagrams do not replace these.
- **Hooks.** Only for a concrete technical term, API, SDK, or SaaS feature that the next inference cannot proceed without. Never for the core plot and never for design-specific shapes (table definitions, schemas, data formats, examples): show those in the body. Place a hook where the prerequisite is used, not ahead. At most one per node. Implement it with the `bump` skill's `.o0:` token inside a folded `[!question]-` callout.
- **Provenance and pointers.** Label each "why" with `[recorded]`, `[code]`, or `[inferred]`, and point to the source (section and line, or file and line). Prefix source IDs with the source name (for example `plan-§13-K3`, `epic-D1`); give your own ledger IDs a different prefix (for example `L1`).
- **Tone.** Present defect histories as history. Do not turn them into criticism.

## Output conventions

- Speaker callouts follow `note --discuss`: student `> [!quote] 🧑‍🎓 Student`, teacher `> [!abstract] 👨‍🏫 Teacher`.
- Figures, code, and tables sit outside callouts, followed by a plain `>` one-line caption.
- Diagram layers: an overall structure diagram, node summary diagrams (both in the map), and per-point diagrams in the dialogue. Details in `references/diagrams.md`.
- Note skeleton, ledgers, and templates: `references/note-template.md`.

## Composition

- `unpack`: nested ID-anchored outline and provenance-label discipline.
- `note` (discuss option): teacher-student callout convention.
- `bump`: the `.o0:` token that implements hooks.
- `obsidian`: deliberate wikilinks in the vault.
- `crosscheck`: independent re-verification of `[recorded]` claims, or a blind pass of Gate A step 1 by an agent that sees only the purpose and the axes.
- `desk` and `bd`: the decision records that Phase 1 reads.

## References

- `references/coverage-review.md`: Gate A procedure, 15-axis table, bias types, four questions, pass conditions.
- `references/note-template.md`: reading-note skeleton, map bullets, ledgers, hook, attainment check, legend.
- `references/diagrams.md`: three diagram layers, static versus dynamic, choosing a diagram, verification setup, layout rules.
- `references/checks.md`: the 13 checks, when each runs, script usage, known limits.
- `references/lineage-and-antipatterns.md`: why each rule exists (symptom, trigger, cause, rule) and the anti-patterns actually hit.
