#!/usr/bin/env python3
"""Claude Code Stop hook: send a macOS notification via terminal-notifier."""

import json
import subprocess
import sys


def tail_chars(value: str, length: int = 30) -> str:
    if len(value) <= length:
        return value
    return "..." + value[-length:]


def extract_echo_line(transcript_path: str) -> str:
    """Read the transcript JSONL and extract the Echo: line from the last assistant text."""
    try:
        with open(transcript_path) as f:
            lines = f.readlines()
        for line in reversed(lines):
            obj = json.loads(line)
            if obj.get("type") != "assistant":
                continue
            for block in obj.get("message", {}).get("content", []):
                if isinstance(block, dict) and block.get("type") == "text":
                    for text_line in block["text"].split("\n"):
                        if text_line.startswith("Echo:"):
                            return text_line[len("Echo:"):].strip()
    except Exception:
        pass
    return "Turn complete"


def main() -> int:
    hook_input = json.load(sys.stdin)

    # Avoid re-entrance when Stop hook itself triggers another Stop
    if hook_input.get("stop_hook_active"):
        return 0

    cwd = hook_input.get("cwd", "")
    session_id = hook_input.get("session_id", "unknown")
    transcript_path = hook_input.get("transcript_path", "")

    title = "Claude Code"
    echo = extract_echo_line(transcript_path) if transcript_path else "Turn complete"
    message = f"{cwd}\nEcho: {echo}"

    subprocess.check_output(
        [
            "terminal-notifier",
            "-title",
            title,
            "-message",
            message,
            "-group",
            f"claude-code-{session_id}",
            "-activate",
            "com.googlecode.iterm2",
        ]
    )
    subprocess.Popen(["afplay", "/System/Library/Sounds/Submarine.aiff"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
