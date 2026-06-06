#!/usr/bin/env python3
"""Split a PDF into per-chapter files.

Usage:
    python3 split.py --input book.pdf --output ./chapters \
        --chapters '01_ch01_intro:1:60' '02_ch02_methods:61:120'

Each --chapters entry is  LABEL:FIRST_PAGE:LAST_PAGE  (1-indexed PDF pages).
Labels must not contain path separators; colons in labels are fine because
the parser uses rsplit from the right (FIRST_PAGE and LAST_PAGE are always
the last two colon-delimited fields).
"""

import argparse
import os
import pathlib
import sys

try:
    import pypdf
except ImportError:
    sys.exit("pypdf not found. Run: pip install pypdf")


def parse_chapter(spec: str) -> tuple[str, int, int]:
    # rsplit from the right so labels may contain colons (e.g. "ch01_TCP:IP")
    parts = spec.rsplit(":", 2)
    if len(parts) != 3:
        sys.exit(f"Bad chapter spec (expected LABEL:FIRST_PAGE:LAST_PAGE): {spec!r}")
    label, first_str, last_str = parts
    try:
        return label, int(first_str), int(last_str)
    except ValueError:
        sys.exit(f"Page numbers must be integers in spec: {spec!r}")


def split(input_path: str, output_dir: str, chapters: list[tuple[str, int, int]]) -> None:
    if not os.path.isfile(input_path):
        sys.exit(f"Input path is not a regular file: {input_path!r}")

    os.makedirs(output_dir, exist_ok=True)

    try:
        pdf_file = open(input_path, "rb")  # noqa: SIM115 — closed via with below
        reader = pypdf.PdfReader(pdf_file)
        if reader.is_encrypted:
            sys.exit("Encrypted PDFs are not supported.")
    except pypdf.errors.PdfReadError as e:
        sys.exit(f"Failed to read PDF: {e}")

    with pdf_file:
        total = len(reader.pages)

        for label, first, last in chapters:
            safe_label = pathlib.Path(label).name
            if not safe_label or safe_label != label:
                sys.exit(f"Invalid label (path separators not allowed): {label!r}")

            if first < 1 or last > total or first > last:
                sys.exit(
                    f"Invalid range {first}-{last} for '{label}' "
                    f"(PDF has {total} pages, and first must be <= last)"
                )

            writer = pypdf.PdfWriter()
            for i in range(first - 1, last):
                writer.add_page(reader.pages[i])

            out_path = os.path.join(output_dir, f"{safe_label}.pdf")
            tmp_path = out_path + ".tmp"
            try:
                with open(tmp_path, "wb") as f:
                    writer.write(f)
                os.replace(tmp_path, out_path)
            except BaseException:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
                raise

            size_mb = os.path.getsize(out_path) / 1024 / 1024
            print(f"  {safe_label}.pdf  ({last - first + 1}pp, {size_mb:.1f}MB)")


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--input", required=True, help="Source PDF path")
    ap.add_argument("--output", required=True, help="Output directory")
    ap.add_argument(
        "--chapters",
        nargs="+",
        required=True,
        metavar="LABEL:FIRST_PAGE:LAST_PAGE",
        help="Chapter specs; repeat for each chapter.",
    )
    args = ap.parse_args()

    chapters = [parse_chapter(s) for s in args.chapters]
    print(f"Splitting {args.input!r} into {len(chapters)} file(s)…")
    split(args.input, args.output, chapters)
    print("Done.")


if __name__ == "__main__":
    main()
