# Diagrams

## Two kinds of concrete material

- **Static shape**: schema, JSON, code, real data, tables. Show it before abstract explanation.
- **Dynamic relation**: structure, flow, time, state transitions, comparison, branching. Show it as a diagram right after the answer that discusses it.

Showing only static shapes leaves the reader to draw the relations in their head. A text timeline in a code block does not count as a diagram.

## Three layers

| Layer | Where | Role |
|---|---|---|
| Overall structure diagram | first entry of the map's Diagrams section | order of nodes and their dependencies at a glance |
| Node summary diagram | map's Diagrams section, one per node, linked from each node | structure or flow of the node in brief |
| Per-point diagram | in the dialogue, right after the teacher's answer, outside the callout | the relation being discussed right now |

The layers serve different jobs; keep all three unless the artifact is small. Duplicating a summary diagram inline is allowed but is a known open question.

## Choosing a diagram

| The answer talks about | Use |
|---|---|
| who is where, who owns what | structure diagram (flowchart with subgraphs) |
| who calls whom, in what order | sequence diagram |
| what happens when | sequence diagram (with times in messages) |
| state changes and their triggers | state diagram |
| A versus B, before versus after | contrast diagram (two subgraphs stacked top to bottom) |
| a decision with branches | flowchart with small decision nodes |
| a table of many rows | keep the table; do not force it into a diagram |
| a directory tree | ASCII tree |

## Rules

- One point per diagram. Do not pack several points into one.
- Draw only what the sources support. A wrong connection in a diagram is remembered longer than a wrong sentence.
- Keep labels short. Put long identifiers, code, and prose in the text or a table, not in nodes.
- Mark illustrative values in the caption. Keep them consistent with the design's other numbers.
- Every diagram gets a one-line caption with its source (section and line, or file and line).
- Replace text timelines (`t=100 ...`, `13:00 ...`) with sequence diagrams that keep the same times.

## Placement

Right after the teacher's answer, outside the callout, with a blank line before and a `>` caption after. Put the concrete static shape (JSON, table) before the diagram when both apply.

## Verification (real rendering)

Syntax that parses can still render badly. Render and look.

```
python3 scripts/render_mermaid.py --setup            # first time: installs mermaid-cli into a cache, finds a system Chrome
python3 scripts/render_mermaid.py NOTE.md --outdir /tmp/grasp-png
```

Then open the PNGs and check: layout, overlaps, clipped notes, stray nodes. Re-extract from the note itself before finalizing so the note's actual content is what gets verified.

## Layout rules that mattered

- Do not put long identifiers inside decision (diamond) nodes; the diamond balloons. Move detail to edge labels.
- To show two or more groups in order, use `flowchart TB`, give each subgraph `direction LR`, and link the groups with `~~~`. With `flowchart LR` alone, groups may stack vertically in reverse order.
- Avoid stray nodes; group them with related nodes.
- Keep edge labels short; long labels wrap badly.
- In sequence diagrams, keep `:` and `;` out of message text.
- Wide notes: use `Note over A,B` spanning more actors so text does not overflow the box.
- Prefer the plain flowchart, sequence, and state syntaxes; avoid newer syntax that older Obsidian versions may not render.
- Set `color` explicitly in `classDef` fills so text stays readable in dark themes.
