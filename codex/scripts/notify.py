#!/usr/bin/env python3
import json
import subprocess
import sys


def main() -> int:
    notification = json.loads(sys.argv[1])
    if notification.get("type") != "agent-turn-complete":
        return 0
    thread_id = notification.get("thread-id", "")
    title = f"Codex: {thread_id}"
    message = notification.get("last-assistant-message", "Turn Complete!")
    subprocess.check_output(
        [
            "terminal-notifier",
            "-title",
            title,
            "-message",
            message,
            "-group",
            "codex-" + thread_id,
            "-activate",
            "com.googlecode.iterm2",
            "-sound",
            "Glass",
        ]
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
