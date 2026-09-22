#!/usr/bin/env python3
"""Render every mermaid block of a Markdown note to PNG (mermaid-cli + a system Chrome).

First time:  render_mermaid.py --setup
Then:        render_mermaid.py NOTE.md --outdir /tmp/grasp-png [--only 1,4-6] [--jobs 4] [--scale 2]

Exit 1 if any block fails to render. A clean exit does not mean a good layout: open the PNGs and look.
The cache directory (default ~/.cache/grasp, override with GRASP_CACHE) holds mermaid-cli
and a puppeteer config that points at the system Chrome; no browser download happens.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import os
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path(os.environ.get("GRASP_CACHE", Path.home() / ".cache" / "grasp"))
CHROMES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
]


def find_chrome() -> str:
    for c in CHROMES:
        if Path(c).exists():
            return c
    sys.exit("no system Chrome/Chromium found; install one or edit CHROMES in this script")


def setup() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    if not (CACHE / "package.json").exists():
        subprocess.run(["npm", "init", "-y"], cwd=CACHE, check=True, capture_output=True)
    env = dict(os.environ, PUPPETEER_SKIP_DOWNLOAD="1")
    subprocess.run(["npm", "install", "@mermaid-js/mermaid-cli"], cwd=CACHE, check=True, env=env)
    (CACHE / "pptr.json").write_text(json.dumps({"executablePath": find_chrome(), "args": ["--no-sandbox"]}), encoding="utf-8")
    print(f"setup done: {CACHE}")


def parse_only(spec: str | None, total: int) -> list[int]:
    if not spec:
        return list(range(1, total + 1))
    out: list[int] = []
    for part in spec.split(","):
        a, _, b = part.partition("-")
        out.extend(range(int(a), int(b or a) + 1))
    return [i for i in out if 1 <= i <= total]


def extract(text: str) -> list[tuple[int, str]]:
    """Return (start line, source) for each mermaid fence."""
    out, lines, i = [], text.split("\n"), 0
    while i < len(lines):
        if lines[i].startswith("```mermaid"):
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                j += 1
            out.append((i + 1, "\n".join(lines[i + 1 : j]) + "\n"))
            i = j
        i += 1
    return out


def render_one(idx: int, line: int, src: str, outdir: Path, scale: int) -> tuple[int, int, bool, str]:
    mmd, png = outdir / f"{idx:02d}.mmd", outdir / f"{idx:02d}.png"
    mmd.write_text(src, encoding="utf-8")
    png.unlink(missing_ok=True)
    r = subprocess.run(
        [str(CACHE / "node_modules" / ".bin" / "mmdc"), "-p", str(CACHE / "pptr.json"), "-i", str(mmd), "-o", str(png), "-b", "white", "-s", str(scale)],
        capture_output=True,
        text=True,
    )
    msg = (r.stdout + r.stderr).strip()
    ok = png.exists() and png.stat().st_size > 0 and not re.search(r"error", msg, re.I)
    return idx, line, ok, msg[:200]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("note", nargs="?")
    ap.add_argument("--setup", action="store_true", help="install mermaid-cli into the cache and write the puppeteer config")
    ap.add_argument("--outdir", default="grasp-png")
    ap.add_argument("--only", help="1-based block numbers, e.g. 1,4-6")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()

    if args.setup:
        setup()
        if not args.note:
            return 0
    if not args.note:
        ap.error("note path required")
    if not (CACHE / "node_modules" / ".bin" / "mmdc").exists() or not (CACHE / "pptr.json").exists():
        sys.exit("mermaid-cli not set up; run: render_mermaid.py --setup")

    blocks = extract(Path(args.note).read_text(encoding="utf-8"))
    chosen = parse_only(args.only, len(blocks))
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    failed = 0
    with cf.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as ex:
        futs = [ex.submit(render_one, i, blocks[i - 1][0], blocks[i - 1][1], outdir, args.scale) for i in chosen]
        for f in sorted((x.result() for x in cf.as_completed(futs)), key=lambda t: t[0]):
            idx, line, ok, msg = f
            print(f"{'OK  ' if ok else 'FAIL'} #{idx:02d} (note line {line}) -> {outdir / f'{idx:02d}.png'}" + ("" if ok else f"  {msg}"))
            failed += 0 if ok else 1
    print(f"{len(chosen) - failed}/{len(chosen)} rendered; PNGs in {outdir}. Open them and check layout by eye.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
