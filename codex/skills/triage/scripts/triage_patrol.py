#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

from triage_once import (
    apply_writeback,
    build_transaction,
    eligible_issues,
    materialize_beads,
    require_allowed_repo,
    resolve_repo,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a lightweight triage patrol loop.")
    parser.add_argument("--repo")
    parser.add_argument("--interval", type=int, default=300, help="Polling interval in seconds.")
    parser.add_argument("--limit", type=int, default=20, help="Maximum issues to process per cycle.")
    parser.add_argument("--once", action="store_true", help="Run a single patrol cycle and exit.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Prepare transaction payloads without bd or GitHub writeback.",
    )
    parser.add_argument(
        "--write-github",
        action="store_true",
        help="Apply success/failure label and comment writeback after each transaction.",
    )
    return parser.parse_args()


def cycle(repo: str, limit: int, *, dry_run: bool, write_github: bool) -> list[dict[str, object]]:
    payloads: list[dict[str, object]] = []
    for issue in eligible_issues(repo)[:limit]:
        try:
            if dry_run:
                prepared = build_transaction(repo, issue.number)
                prepared["plan_exists"] = Path(prepared["plan_path"]).exists()
                prepared["plan_seeded"] = False
                prepared["graph_created"] = False
            else:
                prepared = materialize_beads(repo, issue.number, sandbox=False)
                if write_github:
                    prepared["writeback"] = apply_writeback(
                        repo=repo,
                        issue_number=issue.number,
                        status="success",
                        epic_id=prepared["epic_id"],
                        task_ids=prepared["task_ids"],
                    )
            payloads.append(
                {
                    "issue_repo": repo,
                    "issue_number": issue.number,
                    "issue_title": issue.title,
                    "issue_url": issue.url,
                    "plan_path": prepared["plan_path"],
                    "plan_label": prepared["plan_label"],
                    "plan_exists": prepared["plan_exists"],
                    "plan_seeded": prepared["plan_seeded"],
                    "graph_created": prepared["graph_created"],
                    "transaction_key": prepared["transaction_key"],
                    "status": "success",
                    "writeback": prepared.get("writeback"),
                }
            )
        except Exception as exc:  # pragma: no cover - surfaced in patrol JSON
            failure = {
                "issue_repo": repo,
                "issue_number": issue.number,
                "issue_title": issue.title,
                "issue_url": issue.url,
                "status": "failed",
                "error": str(exc),
            }
            if write_github and not dry_run:
                failure["writeback"] = apply_writeback(
                    repo=repo,
                    issue_number=issue.number,
                    status="failed",
                    stop_reason=str(exc),
                )
            payloads.append(failure)
    return payloads


def main() -> int:
    args = parse_args()
    repo = resolve_repo(args.repo)
    require_allowed_repo(repo)
    if args.write_github is False and args.once is False and args.dry_run is False:
        raise SystemExit("--write-github is required for continuous mode to preserve machine-readable terminal states")

    while True:
        payload = {
            "issue_repo": repo,
            "mode": "once" if args.once else "continuous",
            "dry_run": args.dry_run,
            "write_github": args.write_github,
            "interval_seconds": args.interval,
            "issues": cycle(repo, args.limit, dry_run=args.dry_run, write_github=args.write_github),
        }
        print(json.dumps(payload, ensure_ascii=True, indent=2))

        if args.once:
            return 0

        time.sleep(args.interval)


if __name__ == "__main__":
    raise SystemExit(main())
