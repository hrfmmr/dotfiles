#!/usr/bin/env python3
"""Collect, classify and diff the PRs of the Mayor's commanders (stdlib only).

  pr_status.py run [--dry-run] [--json] [--now ISO] [--no-inbox]
      Collect PRs (Inbox thread pulls of each roster commander + the local table),
      read their live state with gh, classify, compare with the last snapshot.
      Writes out/result.json, out/list.md, out/send-list.json (only when changed or
      post=always) and out/ask-<n>.json (one per question to ask), then saves the
      snapshot. --dry-run writes nothing and prints the result instead.
  pr_status.py table upsert <owner/repo#n | url> [--commander N] [--issue I]
      [--local none|agent-review|apply-pending|applied|closed] [--slack URL]
      [--reminded] [--asked MSG_ID] [--answered] [--clear-asked]
  pr_status.py table show
  pr_status.py ingest "<inbox line>"     apply one report.sh `kind=pr` line to the table
  pr_status.py slack-thread <url>        print channel and thread_ts of a Slack permalink

State dir: $PR_STATUS_DIR, default $MAYOR_HOME/pr-status ($MAYOR_HOME default
~/.local/state/herdr-mayor). Exit 0 ok, 1 error, 2 usage.
"""
import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None

HOME = Path(os.environ.get("MAYOR_HOME", Path.home() / ".local/state/herdr-mayor")).expanduser()
DIR = Path(os.environ.get("PR_STATUS_DIR", HOME / "pr-status")).expanduser()
TABLE = DIR / "prs.tsv"
SNAP = DIR / "snapshot.json"
OUT = DIR / "out"
COLS = ["pr", "commander", "issue", "local_state", "slack_url", "reminders",
        "last_reminder_at", "asked_at", "ask_ref", "updated_at"]
LOCAL_STATES = ("none", "agent-review", "apply-pending", "applied", "closed")
REPORT_STATES = {"opened": "none", "agent-review": "agent-review", "agent-review-done": "none",
                 "apply-pending": "apply-pending", "applied": "applied", "closed": "closed"}

# State order = display order. Labels are what the human reads.
STATES = [
    ("ci-failing", "CI 失敗"),
    ("changes-requested", "変更の依頼あり"),
    ("waiting-review", "human のレビュー待ち (レビュアーあり)"),
    ("waiting-review-noreviewer", "human のレビュー待ち (レビュアー未定)"),
    ("agent-review", "agent がローカルでレビュー中"),
    ("approved", "承認済み・merge 待ち"),
    ("apply-pending", "merge 済み・apply 待ち"),
    ("draft", "draft"),
]
LABEL = dict(STATES)
DONE_STATES = ("done", "closed")
MARK_STALL, MARK_NOREV, MARK_CONSULT = "停滞", "レビュアー未定", "要相談"

QUERY = """query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
 number title url state isDraft reviewDecision mergedAt closedAt createdAt author{login}
 reviewRequests(first:20){nodes{requestedReviewer{__typename ... on User{login} ... on Team{slug} ... on Bot{login} ... on Mannequin{login}}}}
 reviews(last:50){nodes{state submittedAt author{__typename login}}}
 comments(last:50){nodes{createdAt author{__typename login}}}
 commits(last:1){nodes{commit{committedDate statusCheckRollup{state}}}}
 timelineItems(last:30,itemTypes:[READY_FOR_REVIEW_EVENT,HEAD_REF_FORCE_PUSHED_EVENT,REVIEW_REQUESTED_EVENT]){nodes{__typename
  ... on ReadyForReviewEvent{createdAt} ... on HeadRefForcePushedEvent{createdAt} ... on ReviewRequestedEvent{createdAt}}}
}}}"""


def die(msg, code=1):
    print(msg, file=sys.stderr)
    sys.exit(code)


# ---------- config, roster, table ----------

def read_kv(path):
    conf = {}
    if path.exists():
        for line in path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                conf[k.strip()] = v.strip()
    return conf


def config():
    c = read_kv(DIR / "config")
    c.setdefault("thread_name", "Mayor: PR の状況")
    c.setdefault("stall_business_days", "2")
    c.setdefault("max_reminders", "2")
    c.setdefault("scope", "roster")
    c.setdefault("resolved_lookback_days", "30")
    c.setdefault("post", "change")
    if not c.get("mayor_project"):
        rows = [r for r in tsv(HOME / "inbox-projects.tsv") if r and r[0] == "mayor"]
        if rows:
            c["mayor_project"] = str(HOME / "inbox-projects" / rows[-1][2])
    return c


def tsv(path):
    if not path.exists():
        return []
    return [l.split("\t") for l in path.read_text().splitlines() if l.strip() and not l.startswith("#")]


def norm_ref(s):
    s = s.strip()
    m = re.match(r"https?://github\.com/([^/]+)/([^/]+)/pull/(\d+)", s)
    if m:
        return f"{m.group(1)}/{m.group(2)}#{m.group(3)}"
    m = re.fullmatch(r"([\w.-]+)/([\w.-]+)#(\d+)", s)
    if m:
        return s
    return None


def load_table():
    rows = {}
    for r in tsv(TABLE):
        r = (r + [""] * len(COLS))[:len(COLS)]
        rows[r[0]] = dict(zip(COLS, r))
    return rows


def save_table(rows):
    DIR.mkdir(parents=True, exist_ok=True)
    tmp = TABLE.with_suffix(".tmp")
    with tmp.open("w") as f:
        f.write("# " + "\t".join(COLS) + "\n")
        for k in sorted(rows):
            f.write("\t".join(str(rows[k].get(c, "")).replace("\t", " ").replace("\n", " ") for c in COLS) + "\n")
    tmp.replace(TABLE)


def now_iso():
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def upsert(ref, commander=None, issue=None, local=None, slack=None, reminded=False,
           asked=None, clear_asked=False, answered=False):
    ref2 = norm_ref(ref)
    if not ref2:
        die(f"not a PR ref: {ref} (want owner/repo#n or a GitHub PR URL)", 2)
    if local and local not in LOCAL_STATES:
        die(f"--local must be one of {', '.join(LOCAL_STATES)}", 2)
    rows = load_table()
    r = rows.get(ref2) or {c: "" for c in COLS}
    r["pr"] = ref2
    r.setdefault("reminders", "")
    for key, val in (("commander", commander), ("issue", issue), ("local_state", local), ("slack_url", slack)):
        if val:
            r[key] = val
    r["local_state"] = r.get("local_state") or "none"
    r["reminders"] = r.get("reminders") or "0"
    if reminded:
        r["reminders"] = str(int(r["reminders"]) + 1)
        r["last_reminder_at"] = now_iso()
        r["asked_at"], r["ask_ref"] = "", ""
    if asked:
        r["asked_at"], r["ask_ref"] = now_iso(), asked
    if clear_asked:
        r["asked_at"], r["ask_ref"] = "", ""
    if answered:  # the human answered: nothing left to withdraw, but keep asked_at so it is not re-asked at once
        r["ask_ref"] = ""
    r["updated_at"] = now_iso()
    rows[ref2] = r
    save_table(rows)
    return r


def parse_line(line):
    fields = {}
    for part in line.split(" | "):
        if "=" in part:
            k, v = part.split("=", 1)
            fields[k.strip().lstrip("- ")] = v.strip()
    return fields


# ---------- Inbox ----------

def run_cmd(args, timeout=60):
    p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        raise RuntimeError(f"{' '.join(args[:4])}: {p.stderr.strip()[:300]}")
    return p.stdout


def commanders(conf):
    """[(name, issue, [folders])] for the roster (or every Inbox project with scope=all)."""
    projects = tsv(HOME / "inbox-projects.tsv")
    out = []
    if conf["scope"] == "all":
        names = {}
        for r in projects:
            if len(r) >= 3 and r[0] != "mayor":
                names.setdefault((r[0], r[1]), []).append(r[2])
        return [(n, i, f) for (n, i), f in names.items()]
    for r in tsv(HOME / "roster.tsv"):
        if len(r) < 3:
            continue
        name, issue = r[1], r[2]
        folders = [p[2] for p in projects if len(p) >= 3 and (p[0] == name or p[1] == issue)]
        out.append((name, issue, list(dict.fromkeys(folders))))
    return out


def inbox_pulls(conf, warnings):
    """{ref: {"commander","issue","thread"}} from the pulls of each commander's threads."""
    found = {}
    lookback = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=int(conf["resolved_lookback_days"]))
    for name, issue, folders in commanders(conf):
        for folder in folders:
            path = HOME / "inbox-projects" / folder
            if not path.is_dir():
                continue
            arg = json.dumps({"asked_by": "anyone", "project_path": str(path),
                              "include_resolved": True, "limit": 100}, ensure_ascii=False)
            try:
                res = json.loads(run_cmd(["plannotator", "inbox", "call", "read_thread", arg]))
            except Exception as e:  # noqa: BLE001
                warnings.append(f"read_thread {folder}: {e}")
                continue
            if res.get("total", 0) > 100:
                warnings.append(f"{folder}: {res['total']} threads, only the newest 100 read")
            for t in res.get("threads", []):
                if t.get("resolved_at") and parse_ts(t.get("last_at")) and parse_ts(t["last_at"]) < lookback:
                    continue
                try:
                    pl = json.loads(run_cmd(["plannotator", "inbox", "pulls", "ls", t["thread_id"]]))
                except Exception as e:  # noqa: BLE001
                    warnings.append(f"pulls ls {t['thread_id']}: {e}")
                    continue
                for p in pl.get("pulls", []):
                    ref = norm_ref((p.get("url") or p.get("ref") or "") if isinstance(p, dict) else str(p))
                    if ref:
                        found.setdefault(ref, {"commander": name, "issue": issue, "thread": t["thread_id"]})
    return found


# ---------- GitHub ----------

def gh_pr(ref):
    m = re.fullmatch(r"([\w.-]+)/([\w.-]+)#(\d+)", ref)
    out = run_cmd(["gh", "api", "graphql", "-f", f"query={QUERY}", "-f", f"o={m.group(1)}",
                   "-f", f"r={m.group(2)}", "-F", f"n={m.group(3)}"])
    pr = json.loads(out)["data"]["repository"]["pullRequest"]
    if pr is None:
        raise RuntimeError("not found")
    return pr


def parse_ts(s):
    if not s:
        return None
    return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))


# ---------- business time ----------

def holidays(conf):
    days = set()
    p = conf.get("holidays")
    if p and Path(p).expanduser().exists():
        for line in Path(p).expanduser().read_text().splitlines():
            m = re.match(r"\s*(\d{4}-\d{2}-\d{2})", line)
            if m:
                days.add(dt.date.fromisoformat(m.group(1)))
    return days


def tz(conf):
    if conf.get("timezone") and ZoneInfo:
        return ZoneInfo(conf["timezone"])
    return dt.datetime.now().astimezone().tzinfo


def business_days(start, end, conf, hol):
    """Business days (24h units on weekdays that are not holidays) between two instants."""
    if not start or end <= start:
        return 0.0
    z = tz(conf)
    s, e = start.astimezone(z), end.astimezone(z)
    total = dt.timedelta()
    day = s.date()
    while day <= e.date():
        d0 = dt.datetime.combine(day, dt.time(0), z)
        d1 = d0 + dt.timedelta(days=1)
        if day.weekday() < 5 and day not in hol:
            total += max(dt.timedelta(), min(e, d1) - max(s, d0))
        day += dt.timedelta(days=1)
    return total.total_seconds() / 86400


# ---------- classify ----------

def is_bot(author, conf):
    if not author:
        return True
    ignore = {x.strip() for x in conf.get("ignore_logins", "").split(",") if x.strip()}
    login = author.get("login", "")
    return author.get("__typename") == "Bot" or login.endswith("[bot]") or login in ignore


def classify(ref, pr, row, conf, now, hol):
    local = row.get("local_state") or "none"
    owner_repo = ref.split("#")[0]
    apply_repos = {x.strip() for x in conf.get("apply_repos", "").split(",") if x.strip()}
    author = (pr.get("author") or {}).get("login")
    reviews = [r for r in pr["reviews"]["nodes"] if not is_bot(r.get("author"), conf)]
    comments = [c for c in pr["comments"]["nodes"] if not is_bot(c.get("author"), conf)]
    commit = (pr["commits"]["nodes"] or [{}])[0].get("commit") or {}
    rollup = ((commit.get("statusCheckRollup") or {}).get("state") or "").upper()
    requested = [n["requestedReviewer"] for n in pr["reviewRequests"]["nodes"] if n.get("requestedReviewer")]
    reviewers = sorted({(x.get("login") or x.get("slug") or "?") for x in requested}
                       | {r["author"]["login"] for r in reviews if r["author"]["login"] != author})
    times = [parse_ts(pr["createdAt"]), parse_ts(commit.get("committedDate"))]
    times += [parse_ts(r.get("submittedAt")) for r in reviews]
    times += [parse_ts(c.get("createdAt")) for c in comments]
    times += [parse_ts(n.get("createdAt")) for n in pr["timelineItems"]["nodes"]]
    last_activity = max(t for t in times if t)
    marks, ask = [], None

    if pr["state"] == "MERGED":
        state = "apply-pending" if (local == "apply-pending" or (owner_repo in apply_repos and local != "applied")) else "done"
    elif pr["state"] == "CLOSED" or local == "closed":
        state = "closed"
    elif pr["isDraft"]:
        state = "draft"
    elif rollup in ("FAILURE", "ERROR"):
        state = "ci-failing"
    elif pr.get("reviewDecision") == "CHANGES_REQUESTED":
        state = "changes-requested"
    elif pr.get("reviewDecision") == "APPROVED":
        state = "approved"
    elif local == "agent-review":
        state = "agent-review"
    elif reviewers or row.get("slack_url"):
        state = "waiting-review"
    else:
        state = "waiting-review-noreviewer"

    stall_days = float(conf["stall_business_days"])
    max_rem = int(conf["max_reminders"])
    reminders = int(row.get("reminders") or 0)
    clock = max(t for t in (last_activity, parse_ts(row.get("last_reminder_at"))) if t)
    idle = business_days(clock, now, conf, hol)
    asked = parse_ts(row.get("asked_at"))
    ask_clock = max(t for t in (clock, asked) if t)
    ask_idle = business_days(ask_clock, now, conf, hol)
    if state == "waiting-review-noreviewer":
        marks.append(MARK_NOREV)
        if not asked:
            ask = "request"
    elif state == "waiting-review" and idle >= stall_days:
        marks.append(MARK_STALL)
        if reminders >= max_rem:
            marks.append(MARK_CONSULT)
        elif ask_idle >= stall_days:
            ask = "remind"
    need_slack = ask == "remind" and not row.get("slack_url")
    if need_slack:
        ask = None  # never post outside the original thread: get its URL from the commander first
    stale_ask = bool(row.get("ask_ref")) and ask is None and not (
        MARK_STALL in marks or MARK_NOREV in marks)
    return {
        "pr": ref, "url": pr["url"], "title": pr["title"], "state": state,
        "label": LABEL.get(state, state), "marks": marks,
        "commander": row.get("commander", ""), "issue": row.get("issue", ""),
        "local_state": local, "reviewers": reviewers, "slack_url": row.get("slack_url", ""),
        "reminders": reminders, "last_activity": last_activity.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "idle_business_days": round(idle, 1), "ask": ask, "need_slack_url": need_slack, "stale_ask_ref": row.get("ask_ref") if stale_ask else "",
    }


# ---------- drafts and payloads ----------

def local_date(ts, conf):
    return parse_ts(ts).astimezone(tz(conf)).strftime("%m-%d")


def draft(item, conf):
    if item["ask"] == "remind":
        n = item["reminders"] + 1
        return (f"「{item['title']}」のレビューの件で、{local_date(item['last_activity'], conf)} から動きが止まっています。\n"
                "お手すきのときに見ていただけると助かります。\n"
                "難しければ、見られそうな時期か、代わりに見られる方を教えてください。"), n
    return (f"レビューをお願いします。\n{item['title']}\n{item['url']}"), 0


def question(item, conf):
    text, n = draft(item, conf)
    quoted = "\n".join("> " + l for l in text.splitlines())
    who = f"{item['commander']} ({item['issue']})" if item["commander"] else "担当の commander 不明"
    if item["ask"] == "remind":
        where = f"もとのレビュー依頼のスレッドに返信します。\n\n{item['slack_url']}"
        head = f"{item['pr']} のレビューの催促を Slack に送ってよいですか?"
        ctx = (f"{who} の PR です。レビュー待ちのまま {item['idle_business_days']} 営業日、レビュー・コメント・push がありません。"
               f"催促は {n} 回目です (上限 {conf['max_reminders']} 回)。{where}")
    else:
        ch = conf.get("review_channel") or "未設定 (担当の commander に聞いてから送ります)"
        head = f"{item['pr']} のレビュー依頼を Slack に出してよいですか?"
        ctx = f"{who} の PR で、レビュアーが決まっていません。投稿先: {ch}。"
    body = (f":::question\n{head}\n\n{ctx}\n\n下書き:\n\n{quoted}\n\n"
            "- [ ] 送る\n- [ ] 直して送る — 直した文面をメモに書いてください\n- [ ] 送らない\n\n"
            "Recommended: 送る\n:::")
    return body, n


def render(items, diff, conf, now, warnings):
    z = tz(conf)
    lines = [f"**PR の状況 ({now.astimezone(z).strftime('%Y-%m-%d %H:%M')})**。最新の 1 通が今の全体像です。", ""]
    live = [i for i in items if i["state"] not in DONE_STATES]
    for key, label in STATES:
        group = [i for i in live if i["state"] == key]
        if not group:
            continue
        lines.append(f"### {label}: {len(group)} 本")
        for i in group:
            marks = "".join(f"【{m}】" for m in i["marks"])
            who = f"{i['commander']} ({i['issue']})" if i["commander"] else "担当不明"
            extra = f"最後の動き {local_date(i['last_activity'], conf)}"
            if key.startswith("waiting-review"):
                extra += f"、{i['idle_business_days']} 営業日"
                if i["reminders"]:
                    extra += f"、催促 {i['reminders']} 回"
                if i["need_slack_url"]:
                    extra += "、Slack の依頼の URL が未記録"
            lines.append(f"- {marks}[{i['pr']}]({i['url']}) {i['title']} — {who}。{extra}")
        lines.append("")
    done = [i for i in items if i["state"] in DONE_STATES]
    if not live:
        lines += ["動いている PR はありません。", ""]
    if done:
        lines += [f"済み・close: {len(done)} 本 (一覧には出していません)", ""]
    if diff["changes"]:
        lines.append("### 前回からの変化")
        lines += [f"- {c}" for c in diff["changes"]]
        lines.append("")
    if warnings:
        lines.append("### 読めなかったもの")
        lines += [f"- {w}" for w in warnings]
    return "\n".join(lines).rstrip() + "\n"


def compare(items, snap):
    prev = snap.get("prs", {})
    cur = {i["pr"]: {"state": i["state"], "marks": i["marks"], "reminders": i["reminders"]} for i in items}
    changes = []
    for ref, c in cur.items():
        p = prev.get(ref)
        if not p:
            changes.append(f"{ref}: 新しく見つかった ({LABEL.get(c['state'], c['state'])})")
        elif p != c:
            if p["state"] != c["state"]:
                changes.append(f"{ref}: {LABEL.get(p['state'], p['state'])} → {LABEL.get(c['state'], c['state'])}")
            if p["marks"] != c["marks"]:
                changes.append(f"{ref}: 印 {''.join(p['marks']) or 'なし'} → {''.join(c['marks']) or 'なし'}")
            if p["reminders"] != c["reminders"]:
                changes.append(f"{ref}: 催促 {p['reminders']} 回 → {c['reminders']} 回")
    for ref in prev:
        if ref not in cur:
            changes.append(f"{ref}: 一覧から外れた")
    return {"changed": bool(changes), "changes": changes, "snapshot": {"prs": cur}}


def cmd_run(a):
    conf = config()
    now = parse_ts(a.now) if a.now else dt.datetime.now(dt.timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=tz(conf))
    hol = holidays(conf)
    warnings = []
    rows = load_table()
    roster_names = {n for n, _, _ in commanders(conf)}
    attached = {} if a.no_inbox else inbox_pulls(conf, warnings)
    refs = dict(attached)
    for ref, r in rows.items():
        if conf["scope"] == "all" or not r.get("commander") or r["commander"] in roster_names:
            refs.setdefault(ref, {"commander": r.get("commander", ""), "issue": r.get("issue", "")})
    merged_rows = {}
    for ref, src in refs.items():
        row = dict(rows.get(ref, {}))
        row.setdefault("commander", src.get("commander", ""))
        row["commander"] = row["commander"] or src.get("commander", "")
        row["issue"] = row.get("issue") or src.get("issue", "")
        merged_rows[ref] = row
    with ThreadPoolExecutor(max_workers=6) as ex:
        fetched = dict(zip(merged_rows, ex.map(lambda r: _safe(gh_pr, r), merged_rows)))
    items = []
    for ref, pr in fetched.items():
        if isinstance(pr, Exception):
            warnings.append(f"gh {ref}: {pr}")
            continue
        items.append(classify(ref, pr, merged_rows[ref], conf, now, hol))
    items.sort(key=lambda i: (i["commander"], i["pr"]))
    snap = json.loads(SNAP.read_text()) if SNAP.exists() else {}
    diff = compare(items, snap)
    md = render(items, diff, conf, now, warnings)
    asks = [i for i in items if i["ask"]]
    payloads = {}
    post = diff["changed"] or conf["post"] == "always" or not SNAP.exists()
    project = conf.get("mayor_project", "")
    day = now.astimezone(tz(conf)).strftime("%Y%m%d%H%M")
    if post:
        payloads["send-list.json"] = {"project_path": project, "thread": conf["thread_name"],
                                      "subject": conf["thread_name"], "body": md,
                                      "idempotency_key": f"pr-status-list-{day}"}
    for i in asks:
        body, n = question(i, conf)
        slug = re.sub(r"[^\w]+", "-", i["pr"])
        payloads[f"ask-{slug}.json"] = {"project_path": project, "thread": conf["thread_name"],
                                        "subject": conf["thread_name"], "body": body,
                                        "idempotency_key": f"pr-status-{i['ask']}{n}-{slug}-{day[:8]}"}
    result = {"now": now.strftime("%Y-%m-%dT%H:%M:%SZ"), "changed": diff["changed"], "post": post,
              "changes": diff["changes"], "items": items, "asks": [i["pr"] for i in asks],
              "need_slack_url": [i["pr"] for i in items if i["need_slack_url"]],
              "stale_asks": [{"pr": i["pr"], "ask_ref": i["stale_ask_ref"]} for i in items if i["stale_ask_ref"]],
              "warnings": warnings, "mayor_project": project, "thread": conf["thread_name"],
              "attached_count": len(attached), "table_count": len(rows)}
    if a.dry_run:
        print(json.dumps(result, ensure_ascii=False, indent=1) if a.json else md)
        if not a.json:
            print(f"changed={'yes' if diff['changed'] else 'no'} asks={len(asks)} (dry run: nothing written)")
        return
    new_rows = {ref: src for ref, src in attached.items() if ref not in rows}
    if new_rows:  # keep every attached PR in the table, so later upserts keep commander and issue
        for ref, src in new_rows.items():
            rows[ref] = {c: "" for c in COLS} | {"pr": ref, "commander": src["commander"], "issue": src["issue"],
                                                "local_state": "none", "reminders": "0", "updated_at": now_iso()}
        save_table(rows)
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.json"):
        old.unlink()
    (OUT / "list.md").write_text(md)
    for name, p in payloads.items():
        (OUT / name).write_text(json.dumps(p, ensure_ascii=False, indent=1))
    (OUT / "result.json").write_text(json.dumps(result, ensure_ascii=False, indent=1))
    SNAP.write_text(json.dumps(diff["snapshot"], ensure_ascii=False, indent=1))
    print(json.dumps(result, ensure_ascii=False, indent=1) if a.json else md)
    print(f"changed={'yes' if diff['changed'] else 'no'} post={'yes' if post else 'no'} asks={len(asks)} out={OUT}")


def _safe(fn, arg):
    try:
        return fn(arg)
    except Exception as e:  # noqa: BLE001
        return e


def cmd_table(a):
    if a.op == "show":
        sys.stdout.write("\t".join(COLS) + "\n")
        for r in load_table().values():
            sys.stdout.write("\t".join(r.get(c, "") for c in COLS) + "\n")
        return
    if not a.ref:
        die("table upsert needs a PR ref", 2)
    r = upsert(a.ref, a.commander, a.issue, a.local, a.slack, a.reminded, a.asked, a.clear_asked, a.answered)
    print("\t".join(r.get(c, "") for c in COLS))


def cmd_ingest(a):
    f = parse_line(a.line)
    if f.get("kind") != "pr":
        die("not a kind=pr line", 2)
    state = f.get("state", "")
    if state and state not in REPORT_STATES:
        die(f"unknown state={state}", 2)
    sender = f.get("from") if f.get("from") not in ("", "unknown") else None
    r = upsert(f.get("pr", ""), sender, f.get("issue") or None,
               REPORT_STATES.get(state) if state else None, f.get("slack") or None)
    print("\t".join(r.get(c, "") for c in COLS))


def cmd_slack(a):
    m = re.search(r"/archives/([A-Z0-9]+)/p(\d{10})(\d{6})", a.url)
    if not m:
        die("not a Slack message permalink", 2)
    ts = f"{m.group(2)}.{m.group(3)}"
    q = re.search(r"[?&]thread_ts=(\d+\.\d+)", a.url)
    print(json.dumps({"channel": m.group(1), "message_ts": ts, "thread_ts": q.group(1) if q else ts}))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--dry-run", action="store_true")
    r.add_argument("--json", action="store_true")
    r.add_argument("--now")
    r.add_argument("--no-inbox", action="store_true", help="skip the Inbox; table rows only")
    t = sub.add_parser("table")
    t.add_argument("op", choices=["upsert", "show"])
    t.add_argument("ref", nargs="?")
    t.add_argument("--commander")
    t.add_argument("--issue")
    t.add_argument("--local")
    t.add_argument("--slack")
    t.add_argument("--reminded", action="store_true")
    t.add_argument("--asked")
    t.add_argument("--clear-asked", action="store_true")
    t.add_argument("--answered", action="store_true")
    i = sub.add_parser("ingest")
    i.add_argument("line")
    s = sub.add_parser("slack-thread")
    s.add_argument("url")
    a = ap.parse_args()
    {"run": cmd_run, "table": cmd_table, "ingest": cmd_ingest, "slack-thread": cmd_slack}[a.cmd](a)


if __name__ == "__main__":
    main()
