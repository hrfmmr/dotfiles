---
name: grasp
description: >
  Guide a human to actually understand a large design, plan, or implementation (usually agent-made)
  before they review or approve it, by producing an Obsidian reading note: a story section that opens it
  (what the system does, one worked example, each problem with its options and the chosen answer),
  teacher-student dialogue, concrete shapes, inline diagrams, coverage gates, and an attainment check.
  Use when the user wants to understand, work through, or be briefed on a big design, ADR, epic,
  plan, or implementation; asks to make sense of it or produce a "reading note";
  says "guide me through this design" or "briefing before approval"; or asks to explain a design with background, diagrams, and the reasons for each choice;
  or says "commented to grasp note" (it watches delivered notes for `.o0:` reader comments).
  Explanation, not critique: do not use for bug hunting or approval decisions (critique, review),
  single-concept explanations (note), or diff-only walkthroughs (crit-explain, hunk-present).
---

# Grasp

Produce a reading note that lets the reviewer derive the design, not just recognize it.
The human keeps the job of assembling understanding; the note supplies the story that leads in, the concrete shapes, the diagrams, and the checks.

Definition status: draft, validated once end to end; the story-section entry replaced the nested map on 2026-10-14. Rationale and history live in `references/lineage-and-antipatterns.md`.

Write headings and dialogue in the language of the source material and the reader; the English labels below (`recorded`/`code`/`inferred`, Student/Teacher, node-rule names) are the defaults to adapt.

## Scope

- Mode: reading an existing artifact. Authoring support is out of scope.
- Inputs: the design document, upstream decision records (epic, task note, ADR, decision log), and the implementation or its plan.
- Output: one Obsidian note (story section, nodes, attainment check, and an appendix with node summary diagrams and ledgers). Keep the user's design log in sync when they maintain one.
- Never: hunt for bugs, decide whether to approve, or do the understanding for the reader. Explain; do not criticize.

## Principles

1. Build the reader's mental shape first and keep it up while they read. Open with a story section read top to bottom (what the system does, one worked example, each problem with its options, choice, and reason, then the parts that solve them); keep diagrams and concrete shapes in every node.
2. Leave the assembling of understanding to the human: hooks are optional, the attainment check asks "can you derive it", the interview is up front, approval stays with the human.
3. Give the reader a fast way back from a local "I don't get this". Use hooks for technical prerequisites only; explain the core plot in the body.
4. Label provenance on every "why": `[recorded]` (stated in a PR, ADR, dialogue log, or design doc), `[code]` (verifiable from code, tests, or output), `[inferred]` (inference; a candidate to confirm with the author).
5. Check coverage and concreteness by procedure, never by the writer's head. What is obvious to the writer is what gets dropped.
6. Record what is dropped. Keep an out-of-scope ledger and show what remains outside approval.
7. Deliver in one pass, state where feedback is wanted (location and question), and decide open items with recommendation-bearing native asks.
8. Write plain, direct sentences: explicit subject and verb, one idea per sentence, each term defined in one sentence where it first appears. No metaphors or analogies; make things concrete with a real example instead.

## Workflow

```
Phase 0 interview -> Phase 1 sources -> Phase 2 entry draft -> GATE A -> Phase 3 write nodes -> GATE B -> Phase 4 verify -> Phase 5 finish -> Phase 6 operate (watch comments)
                                                                 ^                                                                         |
                                                                 +-------- re-run in diff mode whenever the entry or a node changes -------+
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
- Cite durable sources: code at a named commit, PR bodies, notes. Files under `/tmp` vanish (a reboot cleared them once); if one must be cited, say it is temporary.

### Phase 2. Draft the entry: story section and node list

A compressed map of parts and conclusions does not work as an entry: the reader cannot tell what is being explained or why it was decided, and then the nodes make no sense either. Open the note with a story section instead.

1. Count branch points, then cut to a budget of 5 to 8 nodes: count, cut, then write.
2. Verify dependencies between nodes against the sources. Grep for identifiers shared by the two sections to confirm the dependency exists and what is handed over. Do not decide chained versus parallel by re-reading alone.
3. Write the story section before the nodes. It is prose read top to bottom, not dialogue. Name its heading after the reader's question (for example "Before reading this PR: what was the trouble, and how was it solved"). Its parts, in order:
   - **Summary callout**: the whole story in about five sentences; the place to come back to when lost.
   - **1 What the system does**: the cast and the flow in one diagram. Define each term in one plain sentence where it first appears; no glossary.
   - **2 One example, end to end**: one concrete case, marked illustrative. Show a table of the shared object's key fields at each step, for the success path and for one failure path, each followed by a sequence diagram. Close by naming the troubles from part 3 that the example contains.
   - **3 The troubles and how each was solved**: list them as a, b, c, and so on. Include troubles an upstream change already solved when they give context, and say in the part's opening which ones those are. Write each in a fixed order: the trouble (made concrete with the part 2 example), an options table (ID, option, good points, bad points), what was adopted, and why (with provenance). Give every option an ID `<trouble letter>-<decision number>-<option number>` (`a-1-1`, `a-1-2`, `a-2-1`), label each decision `Options a-1` and `Adopted a-1`, and name the adopted option by its ID, never by position ("the third", "the latter"). When a trouble holds more than one decision, number them (`a-1`, `a-2`), then give one why. A two-way choice whose trade-offs fit in one sentence may be prose, with the IDs inline. Every term or shape the options' cells use must already be defined above the table: when the options turn on a term the story has not defined (an item, a counter, a feature), put a short premise block between the decision label and the table (one-sentence definitions, the shapes involved, a walk-through), because a table cell is not a place where a term may first appear. After the options, add a case list (`Cases a-1`): one bullet per option ID that plays out the option in a concrete scenario (the part 2 example by default), so that both its good and its bad point can be pictured; add no fact beyond the options table and the sources. The prose, undecided, no-alternative, and case forms are in `references/note-template.md`. Put one diagram per item that discusses flow, comparison, or branching.
   - **4 Parts and reading guide**: a table of the parts built, with columns for what each does, the troubles it solves (a, b, ...; "prerequisite" for a part that only makes the others possible), and the node that explains it; then the reading order of the nodes and the overall structure diagram (chained solid, parallel dashed).
   The story section applies to every target. For a design document or a plan, "this change" is the design, "adopted" reads "chosen", provenance is mostly the design's own sections (`[recorded]`) rather than `[code]`, and part 4 lists the planned parts. Fit the summary's sentences to the target.
   When the story section is written, run Gate B's three checks (source, reference direction, figure) and the option-ID, case, and term check (`references/checks.md` #15) on it before writing nodes.
4. Do not build a nested outline with gloss and outcome lines; part 4 does its job. Put one summary diagram per node and the ledgers in an appendix, and link to them from part 4. The root node ① maps the artifact's own units (commits for a PR, sections for a design document, steps for a plan) to the nodes; it does not repeat part 1.
5. Do not use a prerequisites block or a dedicated prerequisites node; the story section supplies premises where they are used.
6. Mark options and their good or bad points `[inferred]` when the records do not state them. A decision record that holds only the decision does not make its options' trade-offs `[recorded]`.

### GATE A. Coverage review

Run the review in `references/coverage-review.md` before writing any node, and do not write nodes until it passes.
In short: diverge from the purpose over 15 axes before looking at the entry draft; merge with the source inventory; classify every item as story item (part 3 letter), node, premise (one sentence and where), out of scope (with reason), or unclassified; check bias types; ask the four hidden-premise questions per element; fix; present the result and decide classifications with native asks that carry recommendations.
Re-run in diff mode whenever a story item or a node is added, changed, or removed, and once more before the attainment check.

### Phase 3. Write nodes

Follow the node rules below. Write one node at a time unless the user asked for all at once.

### GATE B. After each node

- Source check: compare each `[recorded]` claim with the source line. Check identifiers, numbers, and causal links. Illustrative values (times, quantities) must not contradict the design's other numbers.
- Reference direction: "seen in X" points only to earlier nodes; use "will see in X" for later ones.
- Figure check: every answer that talks about structure, flow, time, state transitions, comparison, or branching has a diagram right after it.
- Fix before moving on. Writers naturally invent connective claims the source does not contain.

### Phase 4. Verify mechanically, then independently

Run `scripts/check_note.py` (fences, JSON, links, figure adjacency, text timelines, missing diagrams, identifier shapes, reference direction) and `scripts/render_mermaid.py` (real rendering), then open the images and look at them. See `references/checks.md` and `references/diagrams.md`.

Then have an independent agent fact-check the story section and every `[recorded]` and `[code]` claim against the sources, read-only. Use `crosscheck` when it can run (it needs Herdr); otherwise launch a fresh subagent or the codex CLI that did not write the note. Never skip this step; if no independent agent can run, tell the user the note is unverified before delivering it. Give the checker the source locations and the four error types a plain retelling tends to produce:

- An exhaustive claim ("only", "the three cases") that lists fewer cases than the code's branches. Before writing one, enumerate the branches.
- A loose definition of a counter or column: what exactly changes it, and when it does not change.
- Trade-offs presented as recorded when the record holds only the decision.
- A threshold with a dropped condition: measured from what, and which other clock also applies.

Fix every finding before delivering.

### Phase 5. Finish

- Re-run Gate A as the final pass and fix the coverage table.
- Show what remains outside approval: pending measurements, intentionally deferred items, undesigned areas, and places where the sources disagree with each other.
- Add the attainment check once: 5 to 7 questions that ask whether the reader can derive the design. The questions do not appear in the body. Point each question to the node to go back to. Under each question, put a model answer in a folded callout (`> [!success]- Model answer`), built only from what the body and the sources say, with provenance labels; include these answers in the Phase 4 independent fact check.
- Put the provenance-label legend at the end.

### Phase 6. Operate

- Tell the user where feedback is wanted: place and question, in a table. Tell them to write comments in the note as `.o0: <request>` lines.
- Start the comment watch right after delivery: record the baseline of `.o0:` lines (your own hooks) once with `scripts/watch_comments.py --baseline`, then run the watcher in the background. On each batch, classify and process every new comment, replace each comment line with a folded `> [!note]- AI Follow-up: <request text>` callout (one blockquote level deeper than the comment), and restart the watch as soon as every comment has its reply line. Route requests that change the underlying design or plan to its owner flow and return the result to the same callout. Acknowledge only `.o0:` lines you wrote yourself. Stop when the reader approves the artifact or the session ends. Procedure, reply shapes, and the differences from bump: `references/comment-watch.md`.
- When the user keeps a design log, append an entry whenever the deliberation changes (feedback, verification result, correction). Never rewrite past entries; add a new one that supersedes.

## Node rules

Each node has: heading with nest ID; a current-position line (what is established so far); dialogue; concrete shapes; diagrams; provenance labels with source pointers; 0 to 1 hooks; and two closing lines, "what this establishes" and "where this connects next" (which node it leads to).

- **Dialogue.** Teacher and student, delivered whole and at once. Never stop mid-node to hide answers. Student questions are the entrances to branch points.
- **Core plot in the body.** The "why" that drives the story is explained, not delegated to a hook. There is no separate prerequisites node; prerequisites are supplied where they are used.
- **Concrete first (static shapes).** Before abstract explanation, show the schema, JSON, code, real data, or table. Show a shared object at its introduction node with shape and example; later nodes add only deltas; keep the whole picture in a quick-reference table. The story section may show part of a shape (the fields part 2 needs); the introduction node shows the whole shape. Mark example values as illustrative. When the source does not fix a shape (for example an attribute name), say so with `[inferred]`. Showing concrete shapes exposes gaps and contradictions in the source; report them.
- **Diagram on the spot (dynamic relations).** Right after the teacher's answer that discusses structure, flow, time, state transitions, comparison, or branching, put one diagram, outside the callout, followed by a one-line caption with the source. One point per diagram. Replace text timelines with diagrams. The appendix's summary diagrams do not replace these.
- **Hooks.** Only for a concrete technical term, API, SDK, or SaaS feature that the next inference cannot proceed without. Never for the core plot and never for design-specific shapes (table definitions, schemas, data formats, examples): show those in the body. Place a hook where the prerequisite is used, not ahead. At most one per node. Implement it with the `bump` skill's `.o0:` token inside a folded `[!question]-` callout. These pre-filled lines form the comment watch's baseline, so they are not taken as reader comments until the reader rewrites them or adds an `.o0:` line under the hook.
- **Provenance and pointers.** Label each "why" with `[recorded]`, `[code]`, or `[inferred]`, and point to the source (section and line, or file and line). Prefix source IDs with the source name (for example `plan-§13-K3`, `epic-D1`); give your own ledger IDs a different prefix (for example `L1`).
- **Commit walkthrough.** When the note walks a PR commit by commit, give each commit a subsection: one or two sentences on which troubles (story part 3) it serves, the range (`git diff <parent>..<sha>`), then its essential hunks in ```diff blocks with the explanation inserted as comment lines marked `# [解説]` (no `+`/`-` prefix, so they stand apart from the code). Explain per block: the intent, what it does, and why. Do not refer to code by line numbers, explain line by line, or teach the language or framework. For specs, show only the essential cases the same way, annotated with what each covers.
- **Tone.** Present defect histories as history. Do not turn them into criticism.

## Output conventions

- Speaker callouts follow `note --discuss`: student `> [!quote] 🧑‍🎓 Student`, teacher `> [!abstract] 👨‍🏫 Teacher`.
- Figures, code, and tables sit outside callouts, followed by a plain `>` one-line caption.
- The story section is prose, not dialogue; its figures and tables follow the same caption rule.
- Diagram layers: an overall structure diagram (story section part 4), node summary diagrams (appendix), and per-point diagrams in the story section and the dialogue. Details in `references/diagrams.md`.
- Note skeleton, ledgers, and templates: `references/note-template.md`.

## Composition

- `unpack`: ID-anchored node numbering and provenance-label discipline.
- `note` (discuss option): teacher-student callout convention.
- `bump`: the `.o0:` token that implements hooks and reader comments; the comment watch follows its token, settle window, and derived-note rules, and differs in the reply callout (folded) and state location (see `references/comment-watch.md`).
- `obsidian`: deliberate wikilinks in the vault.
- `crosscheck`: the mandatory Phase 4 fact-check of the story section and claims (in Herdr; elsewhere use a fresh subagent or the codex CLI), or a blind pass of Gate A step 1 by an agent that sees only the purpose and the axes.
- `desk` and `bd`: the decision records that Phase 1 reads.

## References

- `references/coverage-review.md`: Gate A procedure, 15-axis table, bias types, four questions, pass conditions.
- `references/note-template.md`: reading-note skeleton, story section, option IDs, ledgers, hook, attainment check, legend.
- `references/diagrams.md`: three diagram layers, static versus dynamic, choosing a diagram, verification setup, layout rules.
- `references/checks.md`: the 15 checks, when each runs, script usage, known limits.
- `references/comment-watch.md`: Phase 6 comment watch: syntax, baseline, watcher lifetime, classification, reply shapes.
- `references/lineage-and-antipatterns.md`: why each rule exists (symptom, trigger, cause, rule) and the anti-patterns actually hit.
