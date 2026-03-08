#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SUCCESS_SENTINEL = "<!-- codex:triage:success -->"
FAILURE_SENTINEL = "<!-- codex:triage:failure -->"


@dataclass(frozen=True)
class Issue:
    number: int
    title: str
    url: str
    labels: list[str]


def run_gh(*args: str) -> Any:
    proc = subprocess.run(
        ["gh", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    if not proc.stdout.strip():
        return None
    return json.loads(proc.stdout)


def run_gh_text(*args: str) -> str:
    proc = subprocess.run(
        ["gh", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip()


def resolve_repo(repo: str | None) -> str:
    if repo:
        return repo
    resolved = run_gh_text("repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner").strip()
    if not resolved:
        raise SystemExit("unable to resolve repo from cwd")
    return resolved


def run_json_command(*args: str) -> Any:
    proc = subprocess.run(
        list(args),
        check=True,
        capture_output=True,
        text=True,
    )
    if not proc.stdout.strip():
        return None
    return json.loads(proc.stdout)


def run_text_command(*args: str) -> str:
    proc = subprocess.run(
        list(args),
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip()


def require_allowed_repo(repo: str) -> None:
    if "/" not in repo or repo.startswith("/") or repo.endswith("/"):
        raise SystemExit(f"invalid repo: {repo}")


def repo_slug(repo: str) -> str:
    return repo.replace("/", "--")


def plan_path(repo: str, issue_number: int) -> str:
    return f".plans/gh-{repo_slug(repo)}--{issue_number}.md"


def plan_label(repo: str, issue_number: int) -> str:
    return f"plan:gh-{repo_slug(repo)}--{issue_number}"


def load_issue_comments(repo: str, issue_number: int) -> list[dict[str, Any]]:
    return run_gh(
        "api",
        f"repos/{repo}/issues/{issue_number}/comments",
        "--paginate",
    )


def existing_triage_comment(repo: str, issue_number: int) -> dict[str, Any] | None:
    for comment in load_issue_comments(repo, issue_number):
        body = comment.get("body") or ""
        if SUCCESS_SENTINEL in body or FAILURE_SENTINEL in body:
            return comment
    return None


def find_triage_comment(repo: str, issue_number: int) -> dict[str, Any] | None:
    for comment in load_issue_comments(repo, issue_number):
        body = comment.get("body") or ""
        if SUCCESS_SENTINEL in body or FAILURE_SENTINEL in body:
            return comment
    return None


def has_triage_marker(repo: str, issue_number: int) -> bool:
    comments = load_issue_comments(repo, issue_number)
    return any(
        SUCCESS_SENTINEL in (comment.get("body") or "")
        or FAILURE_SENTINEL in (comment.get("body") or "")
        for comment in comments
    )


def list_open_triage_issues(repo: str) -> list[Issue]:
    items = run_gh(
        "issue",
        "list",
        "--repo",
        repo,
        "--state",
        "open",
        "--label",
        "auto:triage",
        "--json",
        "number,title,url,labels",
        "--limit",
        "200",
    )
    issues: list[Issue] = []
    for item in items:
        labels = [label["name"] for label in item["labels"]]
        issues.append(
            Issue(
                number=item["number"],
                title=item["title"],
                url=item["url"],
                labels=labels,
            )
        )
    return sorted(issues, key=lambda issue: issue.number)


def eligible_issues(repo: str) -> list[Issue]:
    result: list[Issue] = []
    for issue in list_open_triage_issues(repo):
        label_set = set(issue.labels)
        if "auto:triaged" in label_set:
            continue
        if "auto:triage-failed" in label_set:
            continue
        if has_triage_marker(repo, issue.number):
            continue
        result.append(issue)
    return result


def build_transaction(repo: str, issue_number: int) -> dict[str, Any]:
    issue = run_gh(
        "issue",
        "view",
        str(issue_number),
        "--repo",
        repo,
        "--json",
        "number,title,body,url,labels",
    )
    labels = [label["name"] for label in issue["labels"]]
    return {
        "issue_repo": repo,
        "issue_number": issue["number"],
        "issue_title": issue["title"],
        "issue_url": issue["url"],
        "issue_body": issue["body"],
        "labels": labels,
        "plan_path": plan_path(repo, issue["number"]),
        "plan_label": plan_label(repo, issue["number"]),
        "ready_query": f"bd ready --label {plan_label(repo, issue['number'])} --type task --json",
        "root_lookup_query": (
            "bd list --type epic "
            f"--label {plan_label(repo, issue['number'])} "
            f"--metadata-field triage_issue_key={repo}#{issue['number']} --json"
        ),
        "root_metadata": {
            "triage_issue_key": f"{repo}#{issue['number']}",
            "triage_plan_path": plan_path(repo, issue["number"]),
            "triage_plan_label": plan_label(repo, issue["number"]),
            "triage_source_url": issue["url"],
        },
        "comment_sentinel_success": SUCCESS_SENTINEL,
        "comment_sentinel_failure": FAILURE_SENTINEL,
        "transaction_key": f"{repo}#{issue['number']}",
    }


def render_plan_seed(payload: dict[str, Any]) -> str:
    body = (payload["issue_body"] or "").strip() or "_No issue body provided._"
    return f"""# {payload["issue_title"]}

Source issue: {payload["issue_repo"]}#{payload["issue_number"]}
URL: {payload["issue_url"]}
Plan label: {payload["plan_label"]}

## Problem

{body}

## Goals

- Turn the GitHub issue into a local execution plan.
- Preserve a stable mapping from issue to plan file and `plan_label`.
- Prepare the plan so a later beads stage can materialize a backlog without rereading the issue.

## Constraints

- Operate only on the explicitly selected target repository for this run.
- Treat this file as the local source of truth after creation.
- Reuse the same `plan_label` when the issue is retried manually.

## Proposed Changes

- Clarify the execution contract implied by the issue.
- Break the work into plan-ready steps with explicit acceptance and validation.
- Record any assumptions needed before beads generation.

## Plan-Level Pseudocode Diff

```diff
- GitHub issue exists only as an external discussion artifact.
+ Materialize a local plan at {payload["plan_path"]}.
+ Preserve the stable transaction key {payload["transaction_key"]}.
+ Carry forward the downstream execution scope {payload["plan_label"]}.
```
"""


def seed_plan(repo: str, issue_number: int) -> dict[str, Any]:
    payload = build_transaction(repo, issue_number)
    path = Path(payload["plan_path"])
    path.parent.mkdir(parents=True, exist_ok=True)
    existed = path.exists()
    if not existed:
        path.write_text(render_plan_seed(payload), encoding="utf-8")
    payload["plan_exists"] = path.exists()
    payload["plan_seeded"] = not existed
    return payload


def extract_goals(plan_text: str) -> list[str]:
    goals: list[str] = []
    in_goals = False
    for line in plan_text.splitlines():
        if line.startswith("## "):
            in_goals = line.strip() == "## Goals"
            continue
        if not in_goals:
            continue
        match = re.match(r"-\s+(.*)", line)
        if match:
            goals.append(match.group(1).strip())
    return goals


def run_bd(*args: str, sandbox: bool) -> Any:
    cmd = ["bd", *args]
    if sandbox:
        cmd.append("--sandbox")
    cmd.append("--json")
    return run_json_command(*cmd)


def create_bd(*args: str, sandbox: bool) -> str:
    cmd = ["bd", *args, "--silent"]
    if sandbox:
        cmd.append("--sandbox")
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return proc.stdout.strip()


def existing_epic(payload: dict[str, Any], sandbox: bool) -> str | None:
    cmd = [
        "bd",
        "list",
        "--label",
        payload["plan_label"],
        "--type",
        "epic",
        "--flat",
    ]
    if sandbox:
        cmd.append("--sandbox")
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    matches = re.findall(r"(dotfiles-[A-Za-z0-9.]+)", proc.stdout)
    if not matches:
        return None
    return matches[0]


def sync_dolt(issue_key: str, sandbox: bool) -> dict[str, str]:
    if sandbox:
        return {"commit": "skipped", "push": "skipped"}

    result = {"commit": "skipped", "push": "skipped"}
    try:
        run_text_command("bd", "dolt", "commit", "-m", f"triage: materialize backlog for {issue_key}")
        result["commit"] = "ok"
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr or ""
        stdout = exc.stdout or ""
        if "nothing to commit" in stderr or "nothing to commit" in stdout:
            result["commit"] = "nothing_to_commit"
            return result
        raise

    try:
        run_text_command("bd", "dolt", "push")
        result["push"] = "ok"
    except subprocess.CalledProcessError:
        run_text_command("bd", "dolt", "pull")
        run_text_command("bd", "dolt", "push")
        result["push"] = "ok_after_pull"
    return result


def existing_tasks(epic_id: str, sandbox: bool) -> list[str]:
    cmd = ["bd", "list", "--parent", epic_id, "--type", "task", "--flat"]
    if sandbox:
        cmd.append("--sandbox")
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    task_ids: list[str] = []
    for line in proc.stdout.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        match = re.search(r"(dotfiles-[A-Za-z0-9.]+)", stripped)
        if match:
            task_ids.append(match.group(1))
    return task_ids


def materialize_beads(repo: str, issue_number: int, sandbox: bool) -> dict[str, Any]:
    payload = seed_plan(repo, issue_number)
    plan_text = Path(payload["plan_path"]).read_text(encoding="utf-8")
    goals = extract_goals(plan_text) or ["Issue requirements を triage backlog として具体化する"]
    epic_id = existing_epic(payload, sandbox)
    if epic_id:
        payload["epic_id"] = epic_id
        payload["task_ids"] = existing_tasks(epic_id, sandbox)
        payload["ready_snapshot"] = run_bd("ready", "--label", payload["plan_label"], "--type", "task", sandbox=sandbox)
        return payload

    if not epic_id:
        epic_id = create_bd(
            "create",
            "--title",
            f"triage backlog: {payload['issue_title']}",
            "--type",
            "epic",
            "--priority",
            "1",
            "--labels",
            payload["plan_label"],
            "--description",
            f"{payload['issue_repo']}#{payload['issue_number']} を triage して生成した root epic。",
            "--design",
            "1 issue -> 1 plan -> 1 plan_label -> 1 root epic の対応を維持する。",
            "--acceptance",
            "同一 plan_label の task graph と mesh handoff 用 ready query が揃っている。",
            "--metadata",
            json.dumps(payload["root_metadata"], ensure_ascii=True),
            sandbox=sandbox,
        )

    task_ids: list[str] = []
    for index, goal in enumerate(goals, start=1):
        task_ids.append(
            create_bd(
                "create",
                "--title",
                f"triage goal {index}: {goal[:72]}",
                "--type",
                "task",
                "--parent",
                epic_id,
                "--priority",
                "2",
                "--labels",
                payload["plan_label"],
                "--description",
                f"Plan の Goal {index} を実現する: {goal}",
                "--design",
                "triage 生成 graph の一部として独立して進められる粒度に保つ。",
                "--acceptance",
                "Goal に対応する成果と少なくとも 1 つの検証シグナルがある。",
                "--notes",
                "検証シグナル: Goal 達成条件を手動または後続チェックポイントで説明できること。",
                sandbox=sandbox,
            )
        )

    checkpoint_id = create_bd(
        "create",
        "--title",
        "triage checkpoint: mesh handoff を確認する",
        "--type",
        "task",
        "--parent",
        epic_id,
        "--priority",
        "2",
        "--labels",
        payload["plan_label"],
        "--description",
        "生成した task graph が mesh handoff に十分か確認する収束点。",
        "--design",
        "ready snapshot と root epic/task ids をまとめて確認する checkpoint とする。",
        "--acceptance",
        "plan_label, epic_id, task_ids, ready_query が handoff に十分である。",
        "--notes",
        "検証シグナル: bd ready --label <plan_label> --type task --json の結果を handoff に添付できること。",
        sandbox=sandbox,
    )
    for task_id in task_ids:
        cmd = ["bd", "dep", "add", checkpoint_id, task_id, "--type", "blocks"]
        if sandbox:
            cmd.append("--sandbox")
        subprocess.run(cmd, check=True, capture_output=True, text=True)

    task_ids.append(checkpoint_id)
    payload["epic_id"] = epic_id
    payload["task_ids"] = task_ids
    payload["ready_snapshot"] = run_bd("ready", "--label", payload["plan_label"], "--type", "task", sandbox=sandbox)
    payload["sync"] = sync_dolt(payload["transaction_key"], sandbox)
    return payload


def render_comment(
    *,
    repo: str,
    issue_number: int,
    status: str,
    epic_id: str | None = None,
    task_ids: list[str] | None = None,
    stop_reason: str | None = None,
) -> str:
    plan_path_value = plan_path(repo, issue_number)
    plan_label_value = plan_label(repo, issue_number)
    issue_key = f"{repo}#{issue_number}"

    if status == "success":
        if not epic_id or not task_ids:
            raise SystemExit("success comment requires --epic-id and at least one --task-id")
        lines = [
            SUCCESS_SENTINEL,
            "[triage:success]",
            f"repo: {repo}",
            f"issue: #{issue_number}",
            f"issue_key: {issue_key}",
            f"plan_path: {plan_path_value}",
            f"plan_label: {plan_label_value}",
            f"bd_root: {epic_id}",
            f"task_ids: {','.join(task_ids)}",
            f"ready_query: bd ready --label {plan_label_value} --type task --json",
            "status: success",
        ]
        return "\n".join(lines)

    if status == "failed":
        if not stop_reason:
            raise SystemExit("failed comment requires --stop-reason")
        lines = [
            FAILURE_SENTINEL,
            "[triage:failed]",
            f"repo: {repo}",
            f"issue: #{issue_number}",
            f"issue_key: {issue_key}",
            f"plan_path: {plan_path_value}",
            f"plan_label: {plan_label_value}",
            "status: failed",
            f"stop_reason: {stop_reason}",
            "recovery: remove auto:triage-failed after fixing the cause, then let patrol pick it up again",
        ]
        return "\n".join(lines)

    if status == "skipped":
        lines = [
            SUCCESS_SENTINEL,
            "[triage:skipped]",
            f"repo: {repo}",
            f"issue: #{issue_number}",
            f"issue_key: {issue_key}",
            "status: reconciled",
            "reason: existing plan and bd graph already matched this issue",
        ]
        return "\n".join(lines)

    raise SystemExit(f"unsupported status: {status}")


def upsert_triage_comment(repo: str, issue_number: int, body: str) -> dict[str, Any]:
    comment = existing_triage_comment(repo, issue_number)
    if comment:
        return run_gh(
            "api",
            f"repos/{repo}/issues/comments/{comment['id']}",
            "--method",
            "PATCH",
            "--field",
            f"body={body}",
        )

    return run_gh(
        "api",
        f"repos/{repo}/issues/{issue_number}/comments",
        "--method",
        "POST",
        "--field",
        f"body={body}",
    )


def apply_labels(repo: str, issue_number: int, *, add: list[str], remove: list[str]) -> None:
    cmd = ["issue", "edit", str(issue_number), "--repo", repo]
    for label in add:
        cmd.extend(["--add-label", label])
    for label in remove:
        cmd.extend(["--remove-label", label])
    run_gh_text(*cmd)


def writeback_success(repo: str, issue_number: int, epic_id: str, task_ids: list[str]) -> dict[str, Any]:
    body = render_comment(
        repo=repo,
        issue_number=issue_number,
        status="success",
        epic_id=epic_id,
        task_ids=task_ids,
    )
    comment = upsert_triage_comment(repo, issue_number, body)
    apply_labels(
        repo,
        issue_number,
        add=["auto:triaged"],
        remove=["auto:triage-failed"],
    )
    return {
        "issue_repo": repo,
        "issue_number": issue_number,
        "status": "success",
        "comment_id": comment["id"],
        "comment_url": comment["html_url"],
        "labels_added": ["auto:triaged"],
        "labels_removed": ["auto:triage-failed"],
        "writeback_comment_locator": comment["html_url"],
    }


def writeback_failure(repo: str, issue_number: int, stop_reason: str) -> dict[str, Any]:
    body = render_comment(
        repo=repo,
        issue_number=issue_number,
        status="failed",
        stop_reason=stop_reason,
    )
    comment = upsert_triage_comment(repo, issue_number, body)
    apply_labels(
        repo,
        issue_number,
        add=["auto:triage-failed"],
        remove=[],
    )
    return {
        "issue_repo": repo,
        "issue_number": issue_number,
        "status": "failed",
        "comment_id": comment["id"],
        "comment_url": comment["html_url"],
        "labels_added": ["auto:triage-failed"],
        "labels_removed": [],
        "writeback_comment_locator": comment["html_url"],
    }


def apply_writeback(
    *,
    repo: str,
    issue_number: int,
    status: str,
    epic_id: str | None = None,
    task_ids: list[str] | None = None,
    stop_reason: str | None = None,
) -> dict[str, Any]:
    body = render_comment(
        repo=repo,
        issue_number=issue_number,
        status=status,
        epic_id=epic_id,
        task_ids=task_ids,
        stop_reason=stop_reason,
    )

    if status == "success":
        run_gh_text(
            "issue",
            "edit",
            str(issue_number),
            "--repo",
            repo,
            "--add-label",
            "auto:triaged",
            "--remove-label",
            "auto:triage-failed",
        )
    elif status == "failed":
        run_gh_text(
            "issue",
            "edit",
            str(issue_number),
            "--repo",
            repo,
            "--add-label",
            "auto:triage-failed",
        )

    existing = find_triage_comment(repo, issue_number)
    if existing:
        run_gh_text(
            "api",
            f"repos/{repo}/issues/comments/{existing['id']}",
            "--method",
            "PATCH",
            "-f",
            f"body={body}",
        )
        comment_id = existing["id"]
        action = "updated"
    else:
        created = run_gh(
            "api",
            f"repos/{repo}/issues/{issue_number}/comments",
            "--method",
            "POST",
            "-f",
            f"body={body}",
        )
        comment_id = created["id"]
        action = "created"

    return {
        "repo": repo,
        "issue_number": issue_number,
        "status": status,
        "comment_id": comment_id,
        "comment_action": action,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prepare one triage transaction.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List eligible triage issues.")
    list_parser.add_argument("--repo")

    prepare_parser = subparsers.add_parser("prepare", help="Prepare a single triage transaction.")
    prepare_parser.add_argument("--repo")
    prepare_parser.add_argument("--issue", required=True, type=int)

    seed_parser = subparsers.add_parser("seed-plan", help="Seed the local plan file for one issue.")
    seed_parser.add_argument("--repo")
    seed_parser.add_argument("--issue", required=True, type=int)

    beads_parser = subparsers.add_parser("materialize-beads", help="Create a minimal bd graph from the local plan.")
    beads_parser.add_argument("--repo")
    beads_parser.add_argument("--issue", required=True, type=int)
    beads_parser.add_argument("--sandbox", action="store_true")

    success_parser = subparsers.add_parser("writeback-success", help="Apply success labels and triage comment.")
    success_parser.add_argument("--repo")
    success_parser.add_argument("--issue", required=True, type=int)
    success_parser.add_argument("--epic-id", required=True)
    success_parser.add_argument("--task-id", action="append", default=[], required=True)

    failure_parser = subparsers.add_parser("writeback-failure", help="Apply failure labels and triage comment.")
    failure_parser.add_argument("--repo")
    failure_parser.add_argument("--issue", required=True, type=int)
    failure_parser.add_argument("--stop-reason", required=True)

    comment_parser = subparsers.add_parser("render-comment", help="Render a triage bot comment body.")
    comment_parser.add_argument("--repo")
    comment_parser.add_argument("--issue", required=True, type=int)
    comment_parser.add_argument("--status", required=True, choices=["success", "failed", "skipped"])
    comment_parser.add_argument("--epic-id")
    comment_parser.add_argument("--task-id", action="append", default=[])
    comment_parser.add_argument("--stop-reason")

    writeback_parser = subparsers.add_parser("apply-writeback", help="Apply triage label/comment writeback to GitHub.")
    writeback_parser.add_argument("--repo")
    writeback_parser.add_argument("--issue", required=True, type=int)
    writeback_parser.add_argument("--status", required=True, choices=["success", "failed", "skipped"])
    writeback_parser.add_argument("--epic-id")
    writeback_parser.add_argument("--task-id", action="append", default=[])
    writeback_parser.add_argument("--stop-reason")

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = resolve_repo(args.repo)
    require_allowed_repo(repo)

    if args.command == "list":
        payload = [
            {
                "issue_repo": repo,
                "issue_number": issue.number,
                "issue_title": issue.title,
                "issue_url": issue.url,
                "labels": issue.labels,
                "plan_path": plan_path(repo, issue.number),
                "plan_label": plan_label(repo, issue.number),
            }
            for issue in eligible_issues(repo)
        ]
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "prepare":
        payload = build_transaction(repo, args.issue)
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "seed-plan":
        payload = seed_plan(repo, args.issue)
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "materialize-beads":
        payload = materialize_beads(repo, args.issue, args.sandbox)
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "writeback-success":
        payload = writeback_success(repo, args.issue, args.epic_id, args.task_id)
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "writeback-failure":
        payload = writeback_failure(repo, args.issue, args.stop_reason)
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    if args.command == "render-comment":
        body = render_comment(
            repo=repo,
            issue_number=args.issue,
            status=args.status,
            epic_id=args.epic_id,
            task_ids=args.task_id,
            stop_reason=args.stop_reason,
        )
        sys.stdout.write(body)
        sys.stdout.write("\n")
        return 0

    if args.command == "apply-writeback":
        payload = apply_writeback(
            repo=repo,
            issue_number=args.issue,
            status=args.status,
            epic_id=args.epic_id,
            task_ids=args.task_id,
            stop_reason=args.stop_reason,
        )
        json.dump(payload, sys.stdout, ensure_ascii=True, indent=2)
        sys.stdout.write("\n")
        return 0

    raise AssertionError(f"unexpected command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
