#!/usr/bin/env python3
"""JSON helpers for vscode-config: strict parse, blocklist strip, leak check, normalized compare."""
import fnmatch
import json
import re
import sys
from pathlib import Path

BLOCKLIST = Path(__file__).with_name("capture-blocklist.json")
LEAK = re.compile(r"/(Users|home)/[^/\"]+")


def load_strict(path):
    text = Path(path).read_text()
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        sys.exit(
            f"error: {path} is not strict JSON ({exc.msg}, line {exc.lineno}).\n"
            "VS Code allows comments and trailing commas; this repo does not. "
            "Remove them in VS Code, then re-run."
        )


def blocked(key, patterns):
    return any(fnmatch.fnmatchcase(key, p) for p in patterns)


def strip(data):
    patterns = json.loads(BLOCKLIST.read_text())["keys"]
    return {k: v for k, v in data.items() if not blocked(k, patterns)}


def dump(data):
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def check_leak(path, text):
    hit = LEAK.search(text)
    if hit:
        sys.exit(f"error: {path} contains a machine path ({hit.group(0)}); refusing to capture into a public repo.")


def main():
    cmd, *args = sys.argv[1:] or ["help"]
    if cmd == "validate":  # validate FILE...
        for path in args:
            load_strict(path)
    elif cmd == "capture-settings":  # capture-settings SRC DEST
        src, dest = args
        out = dump(strip(load_strict(src)))
        check_leak(src, out)
        Path(dest).write_text(out)
    elif cmd == "capture-json":  # capture-json SRC DEST (keybindings: no strip)
        src, dest = args
        out = dump(load_strict(src))
        check_leak(src, out)
        Path(dest).write_text(out)
    elif cmd == "same-settings":  # same-settings REPO LIVE -> exit 1 on drift
        repo, live = args
        sys.exit(0 if strip(load_strict(repo)) == strip(load_strict(live)) else 1)
    elif cmd == "same-json":
        a, b = args
        sys.exit(0 if load_strict(a) == load_strict(b) else 1)
    else:
        sys.exit("usage: vsconfig.py validate|capture-settings|capture-json|same-settings|same-json ...")


if __name__ == "__main__":
    main()
