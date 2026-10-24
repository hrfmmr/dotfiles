# Lineage and anti-patterns

Why each rule exists. Source of truth: this skill's own design log (a decision log with D-numbers, plus an experiment log), kept outside this repository. D-numbers below refer to that decision log. Update this file when a decision changes a rule. Rows added after that log stopped carry a date in the D column instead of a D-number.

## Lineage: symptom, trigger, cause, rule

| # | Symptom | Trigger | Cause | Rule | D |
|---|---|---|---|---|---|
| 1 | A prerequisites block up front is redundant and loses the thread | experiment 1: "very redundant as a preamble" | matching-only preamble that does not build understanding | supply prerequisites inline where used; no block | D1 |
| 2 | Stop-and-hide-the-answer format cannot be read asynchronously | user: "one-to-one combat does not suit async" | dialogue too synchronous | deliver whole dialogue at once | D2, D3 |
| 3 | Hooks on every question are noise | review of D3 | no density rule | judge by the five lenses; 0 to 1 per topic | D4 |
| 4 | Reading through without hooks is not understanding | review of D3 | smooth explanation creates false understanding | attainment check once after reading, mandatory | D5 |
| 5 | Diagnosed "amount" as the problem; wrong | user: "the problem is local 'I don't get it' while reading top down" | misread problem | give local breaks a way back (hooks); current-position display is a separate remedy | D6, D7 |
| 6 | Entering the causal story hides the system's shape | user: "unclear overall design makes topic 2 onward hard" | overestimated the reader's memory | entry node alone shows a low-context overall picture (superseded by 17: story section part 1) | D8 |
| 7 | Flat map hides why each node is there | user: "cost of bridging conclusions and content is high" | chained versus parallel not shown | nested map (unpack) (superseded by 17: parts table and reading order) | D9 |
| 8 | Core plot handed to a hook; a prerequisites node relapsed into D1 | user: "the root of the design should not be skipped" | wrong hook criterion | hooks for technical prerequisites only; no prerequisites node | D10 |
| 9 | Map too compressed to digest on first sight | user: "no information gets in" | compression obvious to the writer | a plain-language gloss under each node (superseded by 17: story section) | D11 |
| 10 | Map's dependency claim contradicted the text | found while writing | re-reading cannot catch memory versus text mismatches | verify dependencies by grepping shared identifiers | D12 |
| 11 | Upstream decisions such as the entry choice were missing from the map | user: "there must have been issues leading to this structure" | branch points taken from critique-cycle notes; overall picture placed as a premise | decision inventory, coverage check, out-of-scope ledger | D13 |
| 12 | No procedure checked coverage | user: "self-review for hidden premises" | checks only looked at internal consistency | coverage review as a mandatory gate | D14 |
| 13 | Map is text only; no picture forms | user: "add diagrams"; later "understanding of the intro became much easier" | only words to show shape | map diagrams (overall and per node) (superseded by 17: overall diagram in part 4, node diagrams in the appendix) | D15, D16 |
| 14 | Table definitions and JSON never shown | user: "I cannot reach understanding" | derivation stories use nouns as known; general knowledge confused with design-specific shapes | concrete first; introduction node per shared object; first-occurrence check | D17 |
| 15 | Writing many nodes at once added unsourced claims, contradictory numbers, backward references | self-check right after writing | concrete writing invites connective claims the source lacks | source check right after writing; reference direction; ID collision rule | D18 |
| 16 | Dialogue was words only; high cognitive load | user: "no diagram support in the dialogue"; later "far easier to read" | concrete material limited to static shapes; dynamic relations told in words | diagram on the spot, one per point; three layers | D19, D20 |
| 17 | The nested map with glosses was unreadable as an entry, and the nodes made no sense without it | user: "even the key points of the map make no sense; if I stumble there, the details are meaningless"; after the rewrite: "reading from the top, picking up premises one at a time, it is very clear what is being explained and how it was decided" | the map listed parts and conclusions without the trouble, the options, and the reasons; a compressed outline is the writer's index, not the reader's entry | story section before the nodes (summary, system, one worked example, troubles with options, choice, and reason, parts table); outline removed; summary diagrams and ledgers to an appendix | 2026-10-14 |
| 18 | The writer's checks passed, then an independent fact-check found 1 wrong and 7 imprecise claims in the story section | codex fact-check of the first story-section note | plain retelling invites exhaustive "only N" claims, loose counter definitions, trade-offs credited to records that hold only the decision, and dropped threshold conditions | mandatory independent fact-check in Phase 4 with the four error types; unrecorded trade-offs are `[inferred]`; enumerate branches before an exhaustive claim | 2026-10-14 |
| 19 | Sources cited from `/tmp` vanished after a reboot | fact-check could not open the cited log | temporary location used as a source | cite durable sources; say when a source is temporary | 2026-10-14 |
| 20 | A per-commit walkthrough with excerpts, line-number references, line-by-line notes and Ruby/Rails tutorials was hard to follow | user: "line numbers given separately do not map to the code"; "line-by-line is not needed"; "language explanations are noise" | explanation sat apart from the code, at the wrong granularity, with general knowledge mixed in | diff blocks with inserted `# [解説]` comments, per-block intent, no language tutorials, essential spec cases only | 2026-10-15 |
| 21 | After delivery the reader wrote questions and requests in the note, and had to point to each line in the chat | user: "write human comments with `.o0:` and have a dedicated file-changes watcher pick them up"; decided with grill-me (reply in bump's shape, route design requests to the owner flow, start at delivery, baseline the agent's own hooks); user: "fold the AI Follow-up callout" | Phase 6 only listed where feedback was wanted; nothing collected comments written in the note | comment watch at delivery (`scripts/watch_comments.py`, `references/comment-watch.md`): baseline, 60-second settle, folded `AI Follow-up` reply that replaces the comment, owner-flow routing for design requests | 2026-10-17 |
| 22 | The reader wanted to check their answers to the attainment check without hunting through the nodes | user: "add model answers in Q&A form in collapsible callouts" (2026-10-17); the first model answers were checked independently and dropped conditions the body kept ("the CA trust stays limited" without its test) | answers only in the body; no way to self-check | a folded model answer under each question, built only from the body, with provenance labels, and fact-checked like the body | 2026-10-17 |
| 23 | In the story section's troubles, the options had no IDs and the adopted line pointed by number or position ("3つ目", "the latter"); the reader could not tell at a glance which option was adopted | user: "the options have no identifiers, so it is hard to see at a glance which one is adopted; give each option an ID (for example a-1-1, a-1-2, a-2-1) and write it into the skill definition" (2026-10-24, on the aws-iac-ir note) | decisions were numbered (options 1, adopted 1) but the options table had no key column, so the adopted line could only count rows | an ID `<letter>-<decision>-<option>` per option, an ID column in the options table, `Adopted a-1` names the ID, later references cite IDs (`references/note-template.md` Option IDs, `references/checks.md` #15) | 2026-10-24 |
| 24 | The options tables listed pros and cons only; in many places the reader could not picture what would actually happen under each option | user: "in many places the per-option explanation is only Pros/Cons and it is hard to picture what happens concretely; write down to a concrete case where each option's pros and cons show up; make it a skill standard" (2026-10-24, on the aws-iac-ir note) | an option's good and bad points were abstract statements ("the window is too short", "the record is overwritten"); the story had a running example, but the options never used it | after every options table, a case list with one bullet per option ID: the part 2 example played out under that option, both points visible, no fact beyond the table and sources (`references/note-template.md` Cases, `references/checks.md` #15) | 2026-10-24 |

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
- Opening with a nested map of parts and conclusions instead of a story of trouble, options, and choice (2026-10-14).
- Pointing at the adopted option by position ("the third", "the latter") or a bare number, with no ID column in the options table (2026-10-24).
- Listing an option's good and bad points without playing it out in a concrete scenario, or writing the case as the same abstract statement in other words (2026-10-24).
- Explaining with metaphors or analogies instead of a concrete example (2026-10-14).

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
- Writing "only" or "the N cases" without enumerating the code's branches (2026-10-14).
- Showing an options table's trade-offs as recorded when the record holds only the decision (2026-10-14).
- Citing files under `/tmp` without saying they are temporary (2026-10-14).
- Explaining a commit with line-number references and line-by-line notes beside the code, or teaching the language, instead of annotating the diff per block (2026-10-15).
- Leaving `.o0:` or a status marker in the note after answering, or treating the agent's own pre-filled hook lines as reader comments (2026-10-17).
- Writing a model answer that is stronger than the body (dropping the condition or the test it depends on), or answering from material the node does not contain (2026-10-17).
