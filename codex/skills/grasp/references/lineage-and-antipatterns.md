# Lineage and anti-patterns

Why each rule exists. Source of truth: this skill's own design log (a decision log with D-numbers, plus an experiment log), kept outside this repository. D-numbers below refer to that decision log. Update this file when a decision changes a rule.

## Lineage: symptom, trigger, cause, rule

| # | Symptom | Trigger | Cause | Rule | D |
|---|---|---|---|---|---|
| 1 | A prerequisites block up front is redundant and loses the thread | experiment 1: "very redundant as a preamble" | matching-only preamble that does not build understanding | supply prerequisites inline where used; no block | D1 |
| 2 | Stop-and-hide-the-answer format cannot be read asynchronously | user: "one-to-one combat does not suit async" | dialogue too synchronous | deliver whole dialogue at once | D2, D3 |
| 3 | Hooks on every question are noise | review of D3 | no density rule | judge by the five lenses; 0 to 1 per topic | D4 |
| 4 | Reading through without hooks is not understanding | review of D3 | smooth explanation creates false understanding | attainment check once after reading, mandatory | D5 |
| 5 | Diagnosed "amount" as the problem; wrong | user: "the problem is local 'I don't get it' while reading top down" | misread problem | give local breaks a way back (hooks); current-position display is a separate remedy | D6, D7 |
| 6 | Entering the causal story hides the system's shape | user: "unclear overall design makes topic 2 onward hard" | overestimated the reader's memory | entry node alone shows a low-context overall picture | D8 |
| 7 | Flat map hides why each node is there | user: "cost of bridging conclusions and content is high" | chained versus parallel not shown | nested map (unpack) | D9 |
| 8 | Core plot handed to a hook; a prerequisites node relapsed into D1 | user: "the root of the design should not be skipped" | wrong hook criterion | hooks for technical prerequisites only; no prerequisites node | D10 |
| 9 | Map too compressed to digest on first sight | user: "no information gets in" | compression obvious to the writer | a plain-language gloss under each node | D11 |
| 10 | Map's dependency claim contradicted the text | found while writing | re-reading cannot catch memory versus text mismatches | verify dependencies by grepping shared identifiers | D12 |
| 11 | Upstream decisions such as the entry choice were missing from the map | user: "there must have been issues leading to this structure" | branch points taken from critique-cycle notes; overall picture placed as a premise | decision inventory, coverage check, out-of-scope ledger | D13 |
| 12 | No procedure checked coverage | user: "self-review for hidden premises" | checks only looked at internal consistency | coverage review as a mandatory gate | D14 |
| 13 | Map is text only; no picture forms | user: "add diagrams"; later "understanding of the intro became much easier" | only words to show shape | map diagrams (overall and per node) | D15, D16 |
| 14 | Table definitions and JSON never shown | user: "I cannot reach understanding" | derivation stories use nouns as known; general knowledge confused with design-specific shapes | concrete first; introduction node per shared object; first-occurrence check | D17 |
| 15 | Writing many nodes at once added unsourced claims, contradictory numbers, backward references | self-check right after writing | concrete writing invites connective claims the source lacks | source check right after writing; reference direction; ID collision rule | D18 |
| 16 | Dialogue was words only; high cognitive load | user: "no diagram support in the dialogue"; later "far easier to read" | concrete material limited to static shapes; dynamic relations told in words | diagram on the spot, one per point; three layers | D19, D20 |

Four recurring diagnoses:

1. What is obvious to the writer is not written: compression, upstream decisions, static shapes, dynamic relations. The writer believes the picture in their head was handed over.
2. Checks drifted toward the writer's concerns (dependencies, facts) and were extended one at a time after each reader complaint. The procedure here moves them ahead of the reader.
3. Treating something as a premise hides thin records and contradictions; making it a node and showing shapes exposes them.
4. The improvements came from the reader's cognition (can the shape be seen, can the relations be seen), not from the writer's concerns.

## Anti-patterns actually hit

**Entry and structure**
- Putting a prerequisites block at the top (D1); collecting prerequisites into a dedicated node (D10, relapse of D1).
- Writing the map first and noticing too many branch points later (experiment 1); count, cut, then map.
- Writing the map in compressed terms only (D11); building the map from text alone (D15).

**Dialogue and hooks**
- Stopping at each step to hide the answer (D2).
- Describing a hook without placing it (D10); giving the core plot to a hook (D10).
- Confusing design-specific concrete material with general knowledge and pushing it to another note or a hook (D17).

**Coverage**
- Taking branch points only from critique-cycle notes (D13): the map becomes a story of what broke.
- Leaving the entry picture as a premise without giving its elements a destination (D13).
- Dropping topics without recording them as out of scope (D13).
- Calling the map verified after internal-consistency checks only (D13).
- Not assigning an introduction node to a shared object (D17).

**Concrete material and diagrams**
- Telling the derivation without showing the data model, schema, or example (D17).
- Carrying the dialogue with words and code or JSON only (D19).
- Counting a text timeline as a diagram (D19).

**Verification and sources**
- Fixing a dependency after re-reading alone (D12).
- Accepting mermaid that only parses (D15).
- Not comparing what was written with the source (D18); pointing "seen in X" at a later node (D18); mixing source IDs with your own (D18).
