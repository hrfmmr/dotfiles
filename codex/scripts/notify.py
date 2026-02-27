#!/usr/bin/env python3
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


def resolve_tmux_server_name(session_name: str) -> str | None:
    tmux_dir = Path(f"/tmp/tmux-{os.getuid()}")
    if not tmux_dir.is_dir():
        return None

    for sock in tmux_dir.iterdir():
        server_name = sock.name
        result = subprocess.run(
            ["tmux", "-L", server_name, "list-sessions", "-F", "#{session_name}"],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            continue
        sessions = result.stdout.splitlines()
        if session_name in sessions:
            return server_name
    return None


def main() -> int:
    notification = json.loads(sys.argv[1])
    if notification.get("type") != "agent-turn-complete":
        return 0
    cwd = notification.get("cwd", "")
    last_message = notification.get("last-assistant-message", "Turn Complete!")
    # TMUX_SESSION="codex-$(echo #{pane_current_path} | md5sum | cut -c1-8)"
    session_suffix = hashlib.md5((cwd + "\n").encode("utf-8")).hexdigest()[:8]
    session_name = f"codex-{session_suffix}"
    tmux_server_name = resolve_tmux_server_name(session_name) or "unknown"

    title = f"Codex: {cwd}"
    message = f"tmux: {tmux_server_name}|{session_name}\n{last_message}"
    subprocess.check_output(
        [
            "terminal-notifier",
            "-title",
            title,
            "-message",
            message,
            "-group",
            "codex-" + notification.get("thread-id", cwd),
            "-activate",
            "com.googlecode.iterm2",
        ]
    )
    subprocess.Popen(["afplay", "/System/Library/Sounds/Submarine.aiff"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
