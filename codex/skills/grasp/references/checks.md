# Checks

Fifteen checks. "Mechanical (coarse)" means a script narrows candidates; a human or the writer judges.

| # | Check | When | Method | Kind | Prevents |
|---|---|---|---|---|---|
| 1 | Branch-point budget | Phase 2 | count, cut to 5 to 8 nodes, then write the entry | judgment | budget overrun |
| 2 | Dependency check | Phase 2 | grep identifiers shared by the two sections | mechanical (coarse) | wrong dependency in the reading-order diagram |
| 3 | Coverage review | Gate A | 15-axis divergence merged with the decision inventory | judgment plus grep | dropped upstream decisions and topics |
| 4 | Shared-object ledger | Gate A | list objects, assign introduction nodes | judgment | shapes with no introduction |
| 5 | Four hidden-premise questions | Gate A | ask per element and per term | judgment | hidden premises |
| 6 | Source check | Gate B | compare each `【recorded】` claim with the source line; check identifiers, numbers, causal links; enumerate the code's branches before an exhaustive claim | judgment plus grep | claims the source does not contain; contradictory example numbers |
| 7 | Reference direction | Gate B | check "seen in X" against node order | mechanical (coarse) | reading-order errors |
| 8 | Figure check | Gate B | count flow, time, state, structure, comparison markers per teacher answer; flag answers with no diagram after them; list text timelines | mechanical (coarse) | dynamic relations told only in words |
| 9 | Identifier and shape | Phase 4 | extract backticked identifiers; check that a code block, JSON, or table shows them by first use | mechanical (coarse) | names used without a shape |
| 10 | Real rendering | Phase 4 | render mermaid with mermaid-cli and Chrome; open the images | mechanical plus visual | diagrams that parse but render badly |
| 11 | JSON, links, fences | Phase 4 | parse JSON blocks, resolve `[[#heading]]` links, check fences pair up | mechanical | broken examples, dead links |
| 12 | Attainment check | Phase 5 | 5 to 7 questions the reader answers | judgment (reader) | the feeling of understanding without deriving |
| 13 | Coverage table (final) | Phase 5 | 15 axes against story items and nodes | judgment | coverage broken by later edits |
| 14 | Independent fact-check | Phase 4 | another agent (codex when available) compares the story section and every `【recorded】` and `【code】` claim with the sources, read-only, given the four error types in SKILL.md Phase 4 | judgment (independent agent) | exhaustive claims short of the code, loose definitions of counters and columns, trade-offs presented as recorded, thresholds with a dropped condition |
| 15 | Option IDs, cases, and terms | Phase 2 (story section), Gate A and B re-runs | every options table has an ID column; every `Adopted x-n` (or `Decided`) line names an ID that exists in that decision; later mentions cite IDs, not positions ("the third", "the latter"); grep `\b[a-z]-[0-9]+-[0-9]+\b`; every set of options is followed by a case list with one bullet per ID, each a scenario that shows the good and the bad point and adds no fact beyond the table; every term, identifier, and shape that a table cell uses is defined or shown above the table (list them, find each first definition) | judgment plus grep | an adopted option the reader cannot match to a row; pros and cons the reader cannot picture; a term met for the first time inside a table cell |

## Scripts

```
python3 scripts/check_note.py NOTE.md [--from-heading REGEX] [--to-heading REGEX] [--node-regex REGEX] [--limit N] [--json]
python3 scripts/render_mermaid.py [--setup] NOTE.md [--outdir DIR] [--only 1,4-6] [--jobs N] [--scale S]
```

`check_note.py` covers checks 7, 8, 9, and 11. It exits 1 on hard errors (unbalanced fences, invalid JSON, unresolved heading links) and prints coarse warnings otherwise:

- **figure adjacency**: a diagram without a blank line before it or a `>` caption after it.
- **text timeline**: a code block whose lines start with times or `t=` markers; replace with a sequence diagram.
- **dynamic answer without diagram**: a teacher answer with at least `--marker-threshold` (default 3) flow, time, or transition markers and no diagram before the next student question. The built-in markers are tuned for Japanese-language notes; adjust the script's regexes for other languages.
- **identifier shape**: a backticked identifier that appears in prose before any code block or table shows it, or never appears in one.
- **reference direction**: a backward "seen in X" phrase (matches the Japanese phrasing "X で見た") pointing at a node that comes later in reading order.

Use `--from-heading` and `--to-heading` to limit identifier and reference checks to the node body (skip the story section and appendix), for example `--from-heading '^## ①' --to-heading '^## (Attainment check|Appendix)'`. Shapes shown before the window (story-section tables and code) still count as shown. The default node pattern matches circled-digit headings such as `## ①`, `### ①-1`, `### ②-1b`; override with `--node-regex`.

`render_mermaid.py` writes one PNG per mermaid block and exits 1 if any block fails. Open the PNGs afterwards; a clean exit does not mean a good layout.

## Known limits

- Identifier-and-shape check cannot see definitions given in captions with an example; it over-reports. Decide by hand whether a defining sentence with an example is enough.
- Figure check is a floor, not a census. On the test note before its diagrams were added, threshold 3 flagged 4 teacher answers and the text-timeline check flagged 6 blocks, while 33 diagrams were eventually added (7 of them replacing text blocks). It also over-reports simple definitional answers. Read the note for the rest and decide by hand.
- Reference-direction check covers one phrasing (Japanese "X で見た"). Read for other phrasings, including in other languages.
- Source check is judgment: re-read the source line for each `【recorded】` claim; a script cannot do it.
- The writer's own source check misses what the writer believes. On the first story-section note, the independent fact-check found 1 wrong and 7 imprecise claims after the writer's checks had passed.
- No script checks the story section's structure (summary, parts 1 to 4, the fixed order of each trouble, the option IDs, cases, and terms of check 15). Check it by reading against the template.
