#!/usr/bin/env python3
"""JSON helpers for vscode-config: strict parse, blocklist strip/overlay, leak guard, normalized compare."""
import fnmatch
import json
import re
import sys
from pathlib import Path

BLOCKLIST = Path(__file__).with_name("capture-blocklist.json")
# Anything that identifies a machine or looks like a credential. The repo is public.
LEAKS = [
    ("machine path", re.compile(r"/(Users|home|Volumes|private)/[^/\"]+")),
    ("home-relative path", re.compile(r"\"~/")),
    ("email address", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    ("Anthropic key", re.compile(r"sk-ant-[A-Za-z0-9_-]{8,}")),
    ("OpenAI-style key", re.compile(r"\bsk-[A-Za-z0-9]{20,}")),
    ("GitHub token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}")),
    ("Slack token", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("private key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
]


def load_strict(path):
    try:
        text = Path(path).read_text()
    except FileNotFoundError:
        sys.exit(f"error: {path} does not exist.")
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        sys.exit(
            f"error: {path} is not strict JSON ({exc.msg}, line {exc.lineno}).\n"
            "VS Code allows comments and trailing commas; this repo does not. "
            "Remove them in VS Code, then re-run."
        )


def patterns():
    return json.loads(BLOCKLIST.read_text())["keys"]


def blocked(key, pats):
    return any(fnmatch.fnmatchcase(key, p) for p in pats)


def strip(data):
    pats = patterns()
    return {k: v for k, v in data.items() if not blocked(k, pats)}


def dump(data):
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def check_leak(path, data):
    """Exit naming the leak type and top-level key only; never echo the matched value."""
    items = data.items() if isinstance(data, dict) else enumerate(data)
    for key, value in items:
        text = json.dumps({str(key): value}, ensure_ascii=False)
        for label, rx in LEAKS:
            if rx.search(text):
                sys.exit(f"error: {path}: key '{key}' contains a {label}; refusing to capture into a public repo.")


def main():
    cmd, *args = sys.argv[1:] or ["help"]
    if cmd == "validate":  # validate FILE...
        for path in args:
            load_strict(path)
    elif cmd == "capture-settings":  # capture-settings LIVE DEST: strip local keys, refuse leaks
        src, dest = args
        data = strip(load_strict(src))
        check_leak(src, data)
        out = dump(data)
        Path(dest).write_text(out)
    elif cmd == "capture-json":  # capture-json LIVE DEST (keybindings: no strip)
        src, dest = args
        data = load_strict(src)
        check_leak(src, data)
        out = dump(data)
        Path(dest).write_text(out)
    elif cmd == "scan-text":  # scan-text FILE...: leak patterns over raw text (JSONC snippets)
        for path in args:
            text = Path(path).read_text()
            for label, rx in LEAKS:
                if rx.search(text):
                    sys.exit(f"error: {path} contains a {label}; refusing to capture into a public repo.")
    elif cmd == "apply-settings":  # apply-settings REPO LIVE DEST: repo keys + the live machine's local keys
        repo, live, dest = args
        out = strip(load_strict(repo))
        if Path(live).exists():
            pats = patterns()
            out.update({k: v for k, v in load_strict(live).items() if blocked(k, pats)})
        Path(dest).write_text(dump(out))
    elif cmd == "same-settings":  # same-settings REPO LIVE -> exit 1 on drift
        repo, live = args
        sys.exit(0 if strip(load_strict(repo)) == strip(load_strict(live)) else 1)
    elif cmd == "same-json":
        a, b = args
        sys.exit(0 if load_strict(a) == load_strict(b) else 1)
    else:
        sys.exit("usage: vsconfig.py validate|capture-settings|capture-json|scan-text|apply-settings|same-settings|same-json ...")


if __name__ == "__main__":
    main()
