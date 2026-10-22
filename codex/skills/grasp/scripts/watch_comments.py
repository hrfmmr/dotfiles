#!/usr/bin/env python3
"""Watch a grasp reading note for reader comments written with the bump token `.o0:`.

A comment is a line with `.o0:` followed by request text, outside fenced code blocks and outside
inline code spans (a reader's follow-up written inside an `AI Follow-up` reply counts). Comments
are counted by their request text, so a copy of a known line, or a line that comes back after
being removed, is new. When a key's count rises, every line with that key is reported.

Modes:
  --baseline   Record the comments present now (the agent's own pre-filled hooks) as known.
               Refuses if the state file already exists, unless --force.
  --list       Print the comments that are not known yet, without waiting, then exit.
  --ack KEY..  Mark only the given keys (from a listing) as known. Use it for lines you wrote
               yourself, or for a comment you defer while asking the reader.
  --once       Same as --list (manual trigger: check once without waiting).
  (default)    Poll the note. When unknown comments exist and the note has been unchanged for
               --quiet seconds, print them and exit 0 (one notification per batch).

Output rows: `NEW_O0_COMMENTS` (or `NO_NEW_COMMENTS`), then one row per comment:
  <key>\tL<line>\t<nearest heading>\t<line text>
Exit codes: 0 new comments (or a successful --baseline/--ack), 1 NO_NEW_COMMENTS (--list/--once),
2 WATCH_TIMEOUT, 3 NOTE_MISSING, 4 STATE_MISSING, 5 STATE_EXISTS (--baseline without --force).

State defaults to ~/.cache/grasp-watch/<hash of the note's real path>.json, outside the vault,
so it survives the session; pass --state with the old file after renaming the note. Baseline counts
stay as recorded; acknowledged counts shrink when lines leave the note.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time

TOKEN = ".o0:"
HEADING = re.compile(r"^#{1,6}\s+(.*)$")
FENCE = re.compile(r"^(`{3,}|~{3,})")
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1")
LIST_MARKER = re.compile(r"^(?:[-*+]|\d+[.)])\s+")


def split_quote(line):
    """Return (blockquote depth, content after the `>` prefixes)."""
    depth, i = 0, 0
    while True:
        j = i
        while j < len(line) and line[j] in " \t":
            j += 1
        if j < len(line) and line[j] == ">":
            depth += 1
            i = j + 1
            continue
        return depth, line[i:].lstrip(" \t")


def norm(text):
    return " ".join(text.split())


def key_of(request):
    return hashlib.sha256(norm(request).encode("utf-8")).hexdigest()[:12]


def scan(path):
    """Return a list of (line_no, heading, line_text, key, request)."""
    out, heading = [], ""
    fence = None          # (char, length, quote_depth)
    with open(path, encoding="utf-8") as f:
        for no, raw in enumerate(f, 1):
            line = raw.rstrip("\n")
            depth, content = split_quote(line)
            fence_view = LIST_MARKER.sub("", content, count=1)
            if fence is not None:
                if depth < fence[2]:
                    fence = None          # the blockquote holding the fence ended
                else:
                    m = FENCE.match(fence_view)
                    if m and m.group(1)[0] == fence[0] and len(m.group(1)) >= fence[1] and not fence_view[len(m.group(1)):].strip():
                        fence = None
                    continue
            m = FENCE.match(fence_view)
            if m:
                fence = (m.group(1)[0], len(m.group(1)), depth)
                continue
            if depth == 0:
                h = HEADING.match(line)
                if h:
                    heading = h.group(1).strip()
                    continue
            visible = INLINE_CODE.sub("", content)
            pos = visible.find(TOKEN)
            if pos < 0:
                continue
            request = visible[pos + len(TOKEN):].strip()
            if not request:
                continue  # incomplete: wait until the reader writes the request
            out.append((no, heading, line.strip(), key_of(request), norm(request)))
    return out


def default_state(note):
    h = hashlib.sha256(os.path.realpath(note).encode("utf-8")).hexdigest()[:16]
    return os.path.join(os.path.expanduser("~/.cache/grasp-watch"), h + ".json")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save(path, state):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=1, sort_keys=True)
    os.replace(tmp, path)


def counts(rows):
    c = {}
    for r in rows:
        c[r[3]] = c.get(r[3], 0) + 1
    return c


def known_counts(state):
    k = dict(state.get("baseline", {}))
    for key, v in state.get("acked", {}).items():
        k[key] = k.get(key, 0) + v
    return k


def unknown(rows, known):
    """Every row whose key now occurs more often than known (the agent decides which line is new)."""
    c = counts(rows)
    return [r for r in rows if c[r[3]] > known.get(r[3], 0)]


def prune(acked, current):
    """Shrink acknowledged counts to what is still in the note (the baseline is kept as recorded)."""
    return {k: min(v, current.get(k, 0)) for k, v in acked.items() if current.get(k, 0) > 0}


def emit(rows, header):
    print(header)
    for no, heading, text, key, _ in rows:
        print(f"{key}\tL{no}\t{heading}\t{text}")
    sys.stdout.flush()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("note")
    ap.add_argument("--state", help="state file (default: ~/.cache/grasp-watch/<hash>.json)")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--baseline", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--ack", nargs="+", metavar="KEY")
    mode.add_argument("--once", action="store_true")
    ap.add_argument("--force", action="store_true", help="allow --baseline to overwrite existing state")
    ap.add_argument("--quiet", type=int, default=60, help="seconds the note must stay unchanged (default 60)")
    ap.add_argument("--interval", type=int, default=10, help="poll interval in seconds (default 10)")
    ap.add_argument("--max-hours", type=float, default=12.0, help="give up after this many hours (default 12)")
    a = ap.parse_args()
    state_path = a.state or default_state(a.note)

    if not os.path.exists(a.note):
        print("NOTE_MISSING")
        return 3

    if a.baseline:
        if os.path.exists(state_path) and not a.force:
            print(f"STATE_EXISTS {state_path} (use --force to re-baseline; comments may be lost)")
            return 5
        rows = scan(a.note)
        save(state_path, {"note": os.path.realpath(a.note), "baseline": counts(rows), "acked": {}})
        print(f"BASELINE {len(rows)} line(s) -> {state_path}")
        return 0

    if not os.path.exists(state_path):
        print(f"STATE_MISSING {state_path} (run --baseline at delivery)")
        return 4

    state = load(state_path)
    if "known" in state and "baseline" not in state:  # state written by an earlier version
        state = {"note": state.get("note"), "baseline": state["known"], "acked": {}}
    rows = scan(a.note)
    state["acked"] = prune(state.get("acked", {}), counts(rows))

    if a.ack:
        current = counts(rows)
        base = state.get("baseline", {})
        for k in a.ack:
            if k in current:
                state["acked"][k] = max(0, current[k] - base.get(k, 0))
        save(state_path, state)
        print(f"ACK {len([k for k in a.ack if k in current])} key(s)")
        return 0

    save(state_path, state)
    if a.list or a.once:
        new = unknown(rows, known_counts(state))
        emit(new, "NEW_O0_COMMENTS" if new else "NO_NEW_COMMENTS")
        return 0 if new else 1

    deadline = time.time() + a.max_hours * 3600
    while time.time() < deadline:
        if not os.path.exists(a.note):
            print("NOTE_MISSING")
            return 3
        state = load(state_path)
        if "known" in state and "baseline" not in state:
            state = {"note": state.get("note"), "baseline": state["known"], "acked": {}}
        rows = scan(a.note)
        pruned = prune(state.get("acked", {}), counts(rows))
        if pruned != state.get("acked"):
            state["acked"] = pruned
            save(state_path, state)
        new = unknown(rows, known_counts(state))
        if new and time.time() - os.path.getmtime(a.note) >= a.quiet:
            emit(new, "NEW_O0_COMMENTS")
            return 0
        time.sleep(a.interval)
    print("WATCH_TIMEOUT")
    return 2


if __name__ == "__main__":
    sys.exit(main())
