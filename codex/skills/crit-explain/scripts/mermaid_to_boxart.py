#!/usr/bin/env python3
"""Convert a Mermaid flowchart into terminal-style Unicode box-drawing art.

Purpose
    crit-explain overview comments embed a structure diagram. Crit (and most
    markdown viewers) do not render mermaid, so this converts the flowchart to
    static box-art that renders anywhere inside a plain ``` code fence.

Provenance
    Local, dependency-free reimagining of the mermaid -> box-art idea from
    https://github.com/simonw/tools/blob/main/grok-mermaid.html
    That page's own converter is a Rust->WASM blob (grok-mermaid.wasm, from
    xai-org/grok-build) and exposes no reusable JS, so the algorithm here is an
    independent stdlib-only implementation, not a port.

Supported subset (what crit-explain emits)
    - header: `flowchart TD|TB|BT|LR|RL` or `graph ...`
      (direction is normalized to a top-to-bottom layered layout, which
       reinforces the ①->⑫ reading route)
    - node decls: ID["label"] / ID[label] / ID(label) / ID{label} / ID((label))
      label may contain <br/> for multi-line, and circled numbers ①..⑫
    - edges: A --> B / A -->|"label"| B / A -.-> B (dotted) / A --- B
    - nodes may be declared inline in edges: A["x"] --> B["y"]
    - subgraph ... end : parsed (borders not drawn); inner nodes/edges kept
    - multi-rank ("skip") edges: routed through virtual pass-through columns

Usage
    python3 mermaid_to_boxart.py diagram.mmd
    python3 mermaid_to_boxart.py < diagram.mmd
    A leading ```mermaid fence and trailing ``` are stripped automatically.
"""
import re
import sys
import unicodedata

GAP = 4  # display columns between items in a rank


def dwidth(s):
    """East-Asian-aware display width (Wide/Fullwidth = 2, else 1)."""
    return sum(2 if unicodedata.east_asian_width(c) in ("W", "F") else 1 for c in s)


# ---------------------------------------------------------------- parsing ----

ARROW_RE = re.compile(r"(-\.->|-->|===>|==>|---|-\.-)")
_ID_RE = re.compile(r"[A-Za-z0-9_]+")
_OPENERS = ("[[", "((", "[(", "[", "(", "{")
_OPEN2CLOSE = {"[[": "]]", "((": "))", "[(": ")]", "[": "]", "(": ")", "{": "}"}


def _clean_label(raw):
    raw = raw.strip().strip('"').strip("'")
    parts = re.split(r"<br\s*/?>", raw)
    return [p.strip() for p in parts if p.strip()] or [""]


def scan_nodes(line):
    """Bracket-aware node scanner. Returns [(start, end, id, label_lines)].

    Handles parentheses inside `[...]` labels (a plain regex cannot) by picking
    the closer from the opener and honouring quoted labels.
    """
    results = []
    i, n = 0, len(line)
    while i < n:
        m = _ID_RE.match(line, i)
        if not m:
            i += 1
            continue
        nid, j = m.group(0), m.end()
        opener = next((op for op in _OPENERS if line.startswith(op, j)), None)
        if not opener:
            i = j
            continue
        k = j + len(opener)
        close = _OPEN2CLOSE[opener]
        if k < n and line[k] in "\"'":
            q = line[k]
            k += 1
            start = k
            while k < n and line[k] != q:
                k += 1
            label = line[start:k]
            k += 1
            while k < n and not line.startswith(close, k):
                k += 1
            k += len(close)
        else:
            start = k
            while k < n and not line.startswith(close, k):
                k += 1
            label = line[start:k]
            k += len(close)
        results.append((m.start(), k, nid, _clean_label(label)))
        i = k
    return results


def _bare(line, found):
    """Replace each node decl span with the bare id, for edge parsing."""
    out, prev = [], 0
    for start, end, nid, _ in found:
        out.append(line[prev:start])
        out.append(nid)
        prev = end
    out.append(line[prev:])
    return "".join(out)


def parse(text):
    """Return (direction, nodes, edges).

    nodes: dict id -> {"label": [lines]}
    edges: list of (src_id, dst_id, label|None, dotted: bool)
    """
    direction = "TD"
    nodes = {}
    edges = []
    order = []

    def register(nid, label_lines=None):
        if nid not in nodes:
            nodes[nid] = {"label": label_lines or [nid]}
            order.append(nid)
        elif label_lines and nodes[nid]["label"] == [nid]:
            nodes[nid]["label"] = label_lines

    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("%%"):
            continue
        head = re.match(r"(?:flowchart|graph)\s+([A-Za-z]{2})\b", line)
        if head:
            direction = head.group(1).upper()
            continue
        if line.startswith("subgraph") or line == "end":
            # subgraph borders are not drawn; do NOT register the container id
            continue

        # register every node declared on the line, then simplify to bare ids
        found = scan_nodes(line)
        for _, _, nid, label in found:
            register(nid, label)
        bare = _bare(line, found)

        if not ARROW_RE.search(bare):
            continue
        # split a chain "A --> B --> C" into consecutive pairs
        tokens = ARROW_RE.split(bare)
        # tokens: [seg0, arrow0, seg1, arrow1, seg2, ...]
        i = 0
        while i + 2 < len(tokens):
            left = tokens[i].strip()
            arrow = tokens[i + 1]
            right = tokens[i + 2].strip()
            lm = re.search(r"([A-Za-z0-9_]+)\s*$", left)
            # edge label: |...| lives at the start of the right segment
            label = None
            rmatch = re.match(r"\s*\|([^|]*)\|\s*(.*)$", right)
            if rmatch:
                label = rmatch.group(1).strip().strip('"').strip("'")
                right = rmatch.group(2).strip()
            rm = re.match(r"\s*([A-Za-z0-9_]+)", right)
            if lm and rm:
                u, v = lm.group(1), rm.group(1)
                register(u)
                register(v)
                edges.append((u, v, label or None, arrow.startswith("-.")))
            i += 2

    return direction, nodes, edges


# --------------------------------------------------------------- ranking ----


def assign_ranks(nodes, edges):
    rank = {n: 0 for n in nodes}
    adj = {n: [] for n in nodes}
    indeg = {n: 0 for n in nodes}
    for u, v, _, _ in edges:
        adj[u].append(v)
        indeg[v] += 1
    # longest-path ranking with a cycle guard
    for _ in range(len(nodes) + 1):
        changed = False
        for u, v, _, _ in edges:
            if rank[v] < rank[u] + 1:
                rank[v] = rank[u] + 1
                changed = True
        if not changed:
            break
    return rank


# ------------------------------------------------------------- rendering ----


def make_box(lines, dotted=False):
    inner = max((dwidth(l) for l in lines), default=0) + 2
    h, v, tl, tr, bl, br = ("─", "│", "┌", "┐", "└", "┘")
    out = [tl + h * inner + tr]
    for l in lines:
        space = inner - dwidth(l)
        lp = space // 2
        rp = space - lp
        out.append(v + " " * lp + l + " " * rp + v)
    out.append(bl + h * inner + br)
    return out, inner + 2


class Band:
    """Char grid for the connector strip between two ranks (width-1 cells)."""

    def __init__(self, height, width):
        self.height = max(1, height)
        self.width = width
        self.g = [[" "] * width for _ in range(self.height)]

    def _merge(self, r, c, ch):
        if 0 <= r < self.height and 0 <= c < self.width:
            cur = self.g[r][c]
            cross = {"─", "┈"}
            vert = {"│", "┊"}
            if (ch in cross and cur in vert) or (ch in vert and cur in cross):
                self.g[r][c] = "┼"
            elif cur == " " or ch not in cross:
                self.g[r][c] = ch

    def _text(self, r, c, s):
        for i, ch in enumerate(s):
            if 0 <= c + i < self.width:
                self.g[r][c + i] = ch

    def route(self, row, cs, ct, dotted, label):
        vch = "┊" if dotted else "│"
        hch = "┈" if dotted else "─"
        for r in range(0, row):  # source vertical down to the turn row
            self._merge(r, cs, vch)
        if cs == ct:
            self._merge(row, cs, vch)
        else:
            step = 1 if ct > cs else -1
            self._merge(row, cs, "└" if ct > cs else "┘")
            for c in range(cs + step, ct, step):
                self._merge(row, c, hch)
            self._merge(row, ct, "┐" if ct > cs else "┌")
        for r in range(row + 1, self.height):  # target vertical down to box
            self._merge(r, ct, vch)
        self.g[self.height - 1][ct] = "▽" if dotted else "▼"
        if label:
            self._text(row, max(cs, ct) + 2, label)

    def render(self):
        return ["".join(self.g[r]).rstrip() for r in range(self.height)]


def render(direction, nodes, edges):
    if not nodes:
        return ""
    rank = assign_ranks(nodes, edges)
    reverse = direction in ("BT", "RL")
    maxr = max(rank.values())
    if reverse:
        rank = {n: maxr - r for n, r in rank.items()}
        maxr = max(rank.values())

    # virtual pass-through columns for multi-rank edges: every edge segment
    # becomes adjacent-rank so the router only ever connects neighbours.
    order = list(nodes.keys())
    ranks = [[] for _ in range(maxr + 1)]
    for n in order:
        ranks[rank[n]].append(n)
    boxinfo = {}  # id -> (lines, width) ; virtuals get width 1
    for n in order:
        boxinfo[n] = make_box(nodes[n]["label"])

    segs = [[] for _ in range(maxr)]  # segs[r] = edges from rank r to r+1
    vcount = 0
    for u, v, label, dotted in edges:
        ru, rv = rank[u], rank[v]
        if rv <= ru:
            continue  # skip back/self edges in this simple layout
        if rv == ru + 1:
            segs[ru].append((u, v, label, dotted, True))
            continue
        prev = u
        for r in range(ru + 1, rv):
            vid = f"__v{vcount}"
            vcount += 1
            boxinfo[vid] = (["┊" if dotted else "│"], 1)
            ranks[r].append(vid)
            segs[r - 1].append((prev, vid, label if r == ru + 1 else None, dotted, False))
            prev = vid
        segs[rv - 1].append((prev, v, None, dotted, True))

    # x layout: pack each rank left->right, then centre by display width
    widths = []
    for items in ranks:
        w = sum(boxinfo[i][1] for i in items) + GAP * max(0, len(items) - 1)
        widths.append(w)
    total = max(widths) if widths else 0
    centers = {}  # id -> center display-column
    for items, w in zip(ranks, widths):
        x = (total - w) // 2
        for i in items:
            bw = boxinfo[i][1]
            centers[i] = x + bw // 2
            x += bw + GAP

    def rank_block(items):
        blocks = [boxinfo[i][0] for i in items]
        h = max(len(b) for b in blocks)
        lefts = []
        x = (total - (sum(boxinfo[i][1] for i in items) + GAP * max(0, len(items) - 1))) // 2
        for i in items:
            lefts.append(x)
            x += boxinfo[i][1] + GAP
        rows = []
        for r in range(h):
            line = ""
            col = 0
            for i, left in zip(items, lefts):
                b = boxinfo[i][0]
                pad = left - col
                if pad > 0:
                    line += " " * pad
                    col += pad
                cell = b[r] if r < len(b) else " " * boxinfo[i][1]
                line += cell
                col += boxinfo[i][1]
            rows.append(line.rstrip())
        return rows

    out = []
    for r in range(maxr + 1):
        out.extend(rank_block(ranks[r]))
        if r < maxr:
            # one turn row per edge + a dedicated final row for arrowheads
            band = Band(len(segs[r]) + 1, total + 40)
            for idx, (u, v, label, dotted, _) in enumerate(segs[r]):
                band.route(idx, centers[u], centers[v], dotted, label)
            out.extend(band.render())
    return "\n".join(out).rstrip("\n")


def main(argv):
    if len(argv) > 1:
        with open(argv[1], encoding="utf-8") as fh:
            text = fh.read()
    else:
        text = sys.stdin.read()
    text = re.sub(r"^\s*```(?:mermaid)?\s*", "", text)
    text = re.sub(r"\s*```\s*$", "", text)
    direction, nodes, edges = parse(text)
    print(render(direction, nodes, edges))


if __name__ == "__main__":
    main(sys.argv)
