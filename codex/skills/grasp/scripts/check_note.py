#!/usr/bin/env python3
"""Mechanical triage for a reading note (Markdown).

Hard errors (exit 1): unbalanced code fences, invalid JSON blocks, unresolved [[#heading]] links.
Coarse warnings (judge by hand): figure adjacency, text timelines, dynamic answers without a
diagram, identifiers used before (or without) a shape, backward "seen in X" references.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

TIME_LINE = re.compile(r"^\s*(?:t\s*=?\s*\d+|t\d+|\d{1,2}:\d{2})(?![\w])")
# Flow, time, and transition markers; arrows that only point to a source are not counted.
MARKER = re.compile(
    r"→(?!\s*(?:設計plan|bd\b|task note|epic|plan|\[\[|D\d))|⇒|\d{1,2}:\d{2}|遷移|呼び出|届[くきい]|順に|時系列"
)
SEEN_IN = re.compile(r"([①-⑳](?:-\d+[a-z]?)?)\s*で見(?:た|ました|ておいた|てきた)")
DEFAULT_NODE = r"^#{2,4}\s+([①-⑳](?:-\d+[a-z]?)?)(?:\s|$)"
IDENT = re.compile(r"`([A-Za-z_][A-Za-z0-9_.#\-]*)`")


def parse(text: str):
    lines = text.split("\n")
    blocks, in_prose = [], [True] * len(lines)
    open_at, lang = None, ""
    for n, line in enumerate(lines):
        if line.startswith("```"):
            in_prose[n] = False
            if open_at is None:
                open_at, lang = n, line[3:].strip().lower()
            else:
                blocks.append({"lang": lang, "start": open_at, "end": n, "body": lines[open_at + 1 : n]})
                open_at = None
            continue
        if open_at is not None:
            in_prose[n] = False
    return lines, blocks, in_prose, open_at


def is_candidate_identifier(tok: str) -> bool:
    if len(tok) < 4 or tok[0].isdigit():
        return False
    return "_" in tok or "#" in tok or bool(re.fullmatch(r"[A-Z][A-Z0-9_]{3,}", tok)) or bool(re.search(r"[a-z][A-Z]", tok))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("note")
    ap.add_argument("--from-heading", help="regex; limit identifier/reference checks to lines after the first matching heading")
    ap.add_argument("--to-heading", help="regex; stop those checks at the first matching heading after --from-heading")
    ap.add_argument("--node-regex", default=DEFAULT_NODE, help="regex with one group capturing the node id in a heading")
    ap.add_argument("--marker-threshold", type=int, default=3, help="markers per teacher answer before a missing diagram is flagged")
    ap.add_argument("--limit", type=int, default=30, help="max items printed per warning section")
    ap.add_argument("--json", action="store_true", help="print a JSON report")
    args = ap.parse_args()

    text = Path(args.note).read_text(encoding="utf-8")
    lines, blocks, in_prose, dangling = parse(text)
    errors: list[str] = []
    warns: dict[str, list[str]] = {k: [] for k in ("figure adjacency", "text timeline", "dynamic answer without diagram", "identifier shape", "reference direction")}

    if dangling is not None:
        errors.append(f"unbalanced code fence: block opened at line {dangling + 1} never closed")

    # headings and body window
    headings = {}
    for n, line in enumerate(lines):
        m = re.match(r"^(#{1,6})\s+(.*?)\s*$", line)
        if m and in_prose[n]:
            headings.setdefault(m.group(2), n)
    lo, hi = 0, len(lines)
    if args.from_heading:
        for n, line in enumerate(lines):
            if in_prose[n] and re.match(r"^#{1,6}\s", line) and re.search(args.from_heading, line):
                lo = n
                break
        if args.to_heading:
            for n in range(lo + 1, len(lines)):
                if in_prose[n] and re.match(r"^#{1,6}\s", lines[n]) and re.search(args.to_heading, lines[n]):
                    hi = n
                    break

    # JSON blocks
    json_ok = json_frag = 0
    for b in blocks:
        if b["lang"] != "json":
            continue
        body = "\n".join(b["body"]).strip()
        if not body or body[0] not in "{[":
            json_frag += 1
            continue
        try:
            json.loads(body)
            json_ok += 1
        except Exception as exc:  # noqa: BLE001
            errors.append(f"invalid JSON block at line {b['start'] + 1}: {str(exc)[:60]}")

    # heading links
    links = 0
    for n, line in enumerate(lines):
        if not in_prose[n]:
            continue
        for m in re.finditer(r"\[\[#([^\]|]+)", line):
            links += 1
            if m.group(1).strip() not in headings:
                errors.append(f"unresolved heading link at line {n + 1}: [[#{m.group(1).strip()}]]")

    # figure adjacency, text timelines
    mermaid = [b for b in blocks if b["lang"] == "mermaid"]
    for b in mermaid:
        s, e = b["start"], b["end"]
        before_ok = s == 0 or lines[s - 1].strip() == ""
        after_ok = e + 2 < len(lines) and lines[e + 1].strip() == "" and (lines[e + 2].startswith("> ") or lines[e + 2].startswith("#"))
        if not (before_ok and after_ok):
            warns["figure adjacency"].append(f"line {s + 1}: needs a blank line before and a '> ' caption after")
    for b in blocks:
        if b["lang"] in ("", "text") and sum(1 for l in b["body"] if TIME_LINE.match(l)) >= 3:
            warns["text timeline"].append(f"line {b['start'] + 1}: {sum(1 for l in b['body'] if TIME_LINE.match(l))} time-marked lines; replace with a sequence diagram")

    # teacher answers with dynamic content but no diagram before the next student question
    mermaid_starts = [b["start"] for b in mermaid]
    n = 0
    while n < len(lines):
        if in_prose[n] and re.match(r"^>\s*\[!abstract\]", lines[n]):
            e = n
            while e + 1 < len(lines) and lines[e + 1].startswith(">"):
                e += 1
            score = sum(len(MARKER.findall(l)) for l in lines[n : e + 1])
            stop = len(lines)
            for k in range(e + 1, len(lines)):
                if (in_prose[k] and lines[k].startswith("> [!quote]")) or (in_prose[k] and re.match(r"^#{1,6}\s", lines[k])):
                    stop = k
                    break
            has_fig = any(e < s < stop for s in mermaid_starts)
            if score >= args.marker_threshold and not has_fig:
                warns["dynamic answer without diagram"].append(f"line {n + 1}: {score} flow/time/transition markers, no diagram before the next question")
            n = e + 1
        else:
            n += 1

    # node order for reference direction
    node_re = re.compile(args.node_regex)
    order: dict[str, int] = {}
    node_at: list[str | None] = [None] * len(lines)
    cur = None
    for k, line in enumerate(lines):
        if in_prose[k]:
            m = node_re.match(line)
            if m:
                cur = m.group(1)
                order.setdefault(cur, k)
        node_at[k] = cur
    for k in range(lo, hi):
        if not in_prose[k] or node_at[k] is None:
            continue
        for m in SEEN_IN.finditer(lines[k]):
            x, y = m.group(1), node_at[k]
            if x != y and x in order and y in order and order[x] >= order[y]:
                warns["reference direction"].append(f"line {k + 1}: in node {y} says '{x} で見た' but {x} comes later")

    # identifier -> shape
    first_prose: dict[str, int] = {}
    first_shape: dict[str, int] = {}
    cand_re: dict[str, re.Pattern[str]] = {}
    for k in range(lo, hi):
        line = lines[k]
        if in_prose[k] and not line.startswith("|") and not line.startswith("#"):
            for m in IDENT.finditer(line):
                tok = m.group(1)
                if is_candidate_identifier(tok):
                    first_prose.setdefault(tok, k)
    for tok in first_prose:
        # dotted field paths are matched by their last segment (a JSON excerpt shows only the leaf key)
        cand_re[tok] = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(tok.split(".")[-1]) + r"(?![A-Za-z0-9_])")
    for k in range(lo, hi):
        line = lines[k]
        if (not in_prose[k]) or line.startswith("|"):
            for tok, rx in cand_re.items():
                if tok not in first_shape and rx.search(line):
                    first_shape[tok] = k
    for tok, kp in sorted(first_prose.items(), key=lambda t: t[1]):
        ks = first_shape.get(tok)
        if ks is None:
            warns["identifier shape"].append(f"line {kp + 1}: `{tok}` never appears in a code block or table")
        elif ks > kp:
            warns["identifier shape"].append(f"line {kp + 1}: `{tok}` used before its shape (first shown at line {ks + 1})")

    hooks = sum(1 for l in lines if l.startswith("> .o0:"))
    # English defaults plus the Japanese labels the template used before D23's rename; count either spelling.
    label_aliases = {"recorded": ("recorded", "記録"), "code": ("code", "コード"), "inferred": ("inferred", "推測")}
    labels = {name: sum(text.count(f"[{tok}") for tok in toks) for name, toks in label_aliases.items()}
    summary = {
        "lines": len(lines),
        "nodes": len(order),
        "mermaid": len(mermaid),
        "json_blocks": json_ok,
        "json_fragments_skipped": json_frag,
        "heading_links": links,
        "hooks": hooks,
        "labels": labels,
    }
    if args.json:
        print(json.dumps({"summary": summary, "errors": errors, "warnings": warns}, ensure_ascii=False, indent=2))
    else:
        print("summary:", json.dumps(summary, ensure_ascii=False))
        print(f"errors: {len(errors)}")
        for e in errors:
            print("  ERROR", e)
        for name, items in warns.items():
            print(f"{name}: {len(items)}")
            for it in items[: args.limit]:
                print("  -", it)
            if len(items) > args.limit:
                print(f"  ... {len(items) - args.limit} more")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
