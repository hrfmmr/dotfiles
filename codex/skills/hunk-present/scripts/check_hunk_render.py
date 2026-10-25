#!/usr/bin/env python3
"""Re-measure how Hunk draws box-art notes, in a pseudo terminal, on a throwaway repo.

Why
    SKILL.md relies on Hunk 0.17.7 facts: runs of ordinary whitespace collapse
    and a leading run vanishes, U+2800 survives (also as an outline indent),
    rationale is not markdown, in stack layout a note's text is (window - 12)
    columns wide, and a wrapped line continues at column 0 with no hanging
    indent. Run this after a Hunk upgrade.

What it touches
    Its own `hunk diff --staged` on a temporary git repo under a temp dir,
    inside a pseudo terminal. It never calls `hunk session` and never attaches
    to a running Hunk, so a human's live session is not affected.

Usage
    uv run --with pyte python3 check_hunk_render.py [--cols 124] [--rows 120] [--mode stack]
    Exit 0 when every fact still holds; 1 when one changed (update SKILL.md).
    The facts are for stack layout; with --mode split the width probes are
    expected to differ, so read the lines instead of the exit code.
    --sample DIR writes a throwaway repo + sidecar into DIR (DIR/repo) and
    prints the Hunk command, for a human to judge the glyphs in their own
    terminal; the pseudo terminal only sees character cells.
"""
import argparse
import fcntl
import json
import os
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

import pyte

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mermaid_to_boxart as boxart  # noqa: E402


def sample_art():
    _, nodes, edges = boxart.parse('flowchart TD\n A["Datadog Log Monitor"] --> B["1.) 通知 Lambda"]')
    return boxart.render("TD", nodes, edges)


SAMPLE_FLOW = (
    'flowchart TD\n DD["Datadog<br/>Log Monitor"] --> EB["EventBridge<br/>partner event bus"]\n'
    ' EB --> L["CHG: 通知 Lambda<br/>失敗を DLQ へ"]\n L --> SNS["SNS topic<br/>アラート通知"]\n'
    ' L -.-> DLQ["NEW: SQS DLQ"]'
)


B = boxart.BRAILLE_BLANK
OUTLINE = ["- 親の主張", "  - 子: 理由", "    - 孫: 出典"]


def indented(lines, blank):
    return "\n".join(blank * (len(l) - len(l.lstrip(" "))) + l.lstrip(" ") for l in lines)


def raw_box(width):
    return "\n".join(["┌" + "─" * (width - 2) + "┐", "│" + "x" * (width - 2) + "│", "└" + "─" * (width - 2) + "┘"])


def pad(art):
    return art.replace(" ", boxart.BRAILLE_BLANK)


def make_repo(root, notes):
    repo = os.path.join(root, "repo")
    os.makedirs(os.path.join(repo, "src"))
    git = ["git", "-c", "user.name=t", "-c", "user.email=t@t", "-C", repo]
    path = os.path.join(repo, "src", "app.py")
    subprocess.run(git + ["init", "-q"], check=True)
    open(path, "w").write("a = 1\nb = 2\nc = 3\n")
    subprocess.run(git + ["add", "."], check=True)
    subprocess.run(git + ["commit", "-qm", "base"], check=True)
    open(path, "a").write("".join(f"v{i} = {i}\n" for i in range(len(notes))))
    subprocess.run(git + ["add", "."], check=True)
    ctx = {
        "version": 1,
        "summary": "probe",
        "files": [
            {
                "path": "src/app.py",
                "summary": "probe",
                "annotations": [
                    {"newRange": [4 + i, 4 + i], "summary": s, "rationale": r, "author": "probe"}
                    for i, (s, r) in enumerate(notes)
                ],
            }
        ],
    }
    json.dump(ctx, open(os.path.join(repo, "ctx.json"), "w"), ensure_ascii=False)
    return repo


def screen_of(repo, cols, rows, mode):
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(repo)
        env = dict(os.environ, TERM="xterm-256color", COLUMNS=str(cols), LINES=str(rows), EDITOR="true")
        os.execvpe("hunk", ["hunk", "diff", "--staged", "--mode", mode, "--agent-context", "ctx.json", "--agent-notes"], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    screen = pyte.Screen(cols, rows)
    stream = pyte.ByteStream(screen)
    end = time.time() + 4
    while time.time() < end:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if ready:
            try:
                stream.feed(os.read(fd, 65536))
            except OSError:
                break
    try:
        os.write(fd, b"q")
        time.sleep(0.3)
        os.kill(pid, signal.SIGKILL)
    except (OSError, ProcessLookupError):
        pass
    return [[screen.buffer[y][x].data for x in range(cols)] for y in range(rows)]


def cards(grid):
    """Return {summary: (borders_aligned, body_lines)} for every note card on the screen."""
    found, y = {}, 0
    while y < len(grid):
        row = grid[y]
        if "╭" in row and "╮" in row:
            xl, xr = row.index("╭"), len(row) - 1 - row[::-1].index("╮")
            body, aligned, y = [], True, y + 1
            while y < len(grid) and "╰" not in grid[y]:
                aligned &= grid[y][xl] == "│" and grid[y][xr] == "│"
                text = "".join(grid[y][xl + 1 : xr]).rstrip(" ")
                body.append(text[1:] if text.startswith(" ") else text)
                y += 1
            while body and not body[0]:
                body.pop(0)
            while body and not body[-1]:
                body.pop()
            if body:
                found[body[0]] = (aligned, body[1:])
        y += 1
    return found


def write_sample(root, text_width):
    _, nodes, edges = boxart.parse(SAMPLE_FLOW)
    flow = boxart.render("TD", nodes, edges)
    notes = [
        ("1.) braille padding: every right border should line up", pad(flow)),
        ("2.) plain spaces (broken on purpose, for comparison)", flow),
        (f"3.) widest box that fits a pane of {text_width + 12} columns", pad(raw_box(text_width))),
        ("4.) outline indented with U+2800: three levels should be visible", indented(OUTLINE, B)),
        ("5.) outline indented with spaces (broken on purpose): the levels vanish", indented(OUTLINE, " ")),
    ]
    repo = make_repo(root, notes)
    print(f"cd {repo} && hunk diff --staged --mode stack --agent-context ctx.json --agent-notes")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--cols", type=int, default=124)
    ap.add_argument("--rows", type=int, default=120)
    ap.add_argument("--mode", default="stack")
    ap.add_argument("--sample", metavar="DIR", help="write a sample repo for a human to open, then exit")
    args = ap.parse_args()
    text_width = args.cols - 12
    if args.sample:
        return write_sample(args.sample, text_width)

    art = sample_art()
    probes = {
        "braille": (pad(art), "braille-padded art is kept with its right border aligned"),
        "space": (art, "plain-space art is damaged (whitespace collapses)"),
        "markdown": ("**bold** `code`\n```", "rationale is shown as typed, not as markdown"),
        "fit": (pad(raw_box(text_width)), f"art {text_width} columns wide fits (window - 12)"),
        "wrap": (pad(raw_box(text_width + 1)), f"art {text_width + 1} columns wide wraps"),
        "indent": (indented(OUTLINE, B), "outline indent made of U+2800 is kept at every level"),
        "plainindent": (indented(OUTLINE, " "), "outline indent made of spaces vanishes"),
        "hanging": (B * 2 + "- " + " ".join(["word"] * (text_width // 5 + 4)), "a wrapped line continues at column 0, no hanging indent"),
    }
    with tempfile.TemporaryDirectory() as root:
        repo = make_repo(root, [(name, rationale) for name, (rationale, _) in probes.items()])
        version = subprocess.run(["hunk", "--version"], capture_output=True, text=True).stdout.strip()
        found = cards(screen_of(repo, args.cols, args.rows, args.mode))
    print(f"hunk {version}, {args.cols}x{args.rows}, mode={args.mode}")

    results = {}
    for name, (rationale, _) in probes.items():
        aligned, body = found.get(name, (False, None))
        same = body == [l.rstrip(" ") for l in rationale.split("\n")]
        results[name] = (aligned, same, body)
    expect = {
        "braille": lambda a, s, b: a and s,
        "space": lambda a, s, b: not s,
        "markdown": lambda a, s, b: s,
        "fit": lambda a, s, b: a and s,
        "wrap": lambda a, s, b: b is not None and not s,
        "indent": lambda a, s, b: a and s,
        "plainindent": lambda a, s, b: b is not None and not s and [l.lstrip(B) for l in b] == [l.lstrip() for l in OUTLINE],
        "hanging": lambda a, s, b: b is not None and len(b) == 2 and b[0].startswith(B) and not b[1].startswith(B),
    }
    changed = 0
    for name, (_, label) in probes.items():
        a, s, b = results[name]
        holds = expect[name](a, s, b)
        changed += not holds
        print(f"{'ok  ' if holds else 'DIFF'} {name}: {label} (borders_aligned={a}, text_identical={s})")
    print("all facts in SKILL.md still hold" if not changed else f"{changed} fact(s) changed: update SKILL.md 3b")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
