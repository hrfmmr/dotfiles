# mermaid → unicode box-art converter

`scripts/mermaid_to_boxart.py` — stdlib-only, no network, no WASM. Turns a
Mermaid flowchart into terminal-style box-drawing art so an overview comment
renders anywhere (crit and most markdown viewers do NOT render mermaid).

## Provenance

Inspired by the output style of
<https://github.com/simonw/tools/blob/main/grok-mermaid.html>. That page's own
converter is a Rust→WASM blob (`grok-mermaid.wasm`, from `xai-org/grok-build`)
and exposes no reusable JavaScript, so this is an independent local
reimplementation of the idea, not a port. Local reference is self-contained.

## Usage

```bash
python3 scripts/mermaid_to_boxart.py diagram.mmd     # path
python3 scripts/mermaid_to_boxart.py < diagram.mmd   # stdin
```

A leading ` ```mermaid ` fence and trailing ` ``` ` are stripped automatically,
so you can pipe a fenced block straight in. Paste the STDOUT into the overview
comment inside a plain ` ``` ` code fence (never ` ```mermaid `).

## Supported subset

- header `flowchart TD|TB|BT|LR|RL` or `graph …` — direction is normalized to a
  top-to-bottom layered layout (this reinforces the ①→⑫ reading route).
- nodes `ID["label"]`, `ID[label]`, `ID(label)`, `ID{label}`, `ID((label))`;
  `<br/>` splits a label into multiple lines; parentheses inside `[...]` labels
  are handled.
- edges `A --> B`, `A -->|"label"| B`, `A -.-> B` (dotted → `┊`/`▽`), `A --- B`;
  nodes may be declared inline; `A --> B --> C` chains are split.
- multi-rank ("skip") edges are routed through virtual pass-through columns.

## Known limits (keep diagrams small)

- `subgraph … end` is parsed but its border is NOT drawn. Encode grouping in the
  node label instead, e.g. `SN["③ service network (owner)"]`.
- Only flowchart/graph is converted. For a genuinely sequence- or state-shaped
  change, hand-author the box-art (still inside a plain ` ``` ` fence).
- No crossing minimization; dense branchy graphs may show edge crossings. Prefer
  one clear diagram of <= ~10 nodes; hand-tune the output if needed.
- Display width assumes East-Asian Wide/Fullwidth = 2 columns, others = 1
  (circled numbers ①.. count as 1); minor drift is possible in some terminals.
