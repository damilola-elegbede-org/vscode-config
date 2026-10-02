---
name: sync
description: Sync D's VS Code with this repo — apply the repo to VS Code, capture VS Code back into the repo, check drift, or bootstrap a fresh Mac. Use when D says "sync my VS Code", "set up my VS Code", "save my VS Code changes", "is VS Code in sync", or runs /sync.
---

# /sync

Run from a clone of this repository. Pick the mode from `$ARGUMENTS` (default: `check`, then ask).

| Mode | Command | When |
| --- | --- | --- |
| `check` | `make check` | "is it in sync?" — always safe, run first |
| `apply` | `make plan`, show it, then `make apply` | push the repo to VS Code |
| `prune` | `make plan`, then `make prune` | apply and uninstall extensions removed from the list |
| `capture` | `make capture`, then `git diff --stat` + meaningful hunks | save VS Code changes into the repo |
| `bootstrap` | see CLAUDE.md "Fresh Mac" | new machine |

## Rules

1. Run `make check` before `apply` or `capture` and report its output verbatim.
   If it shows drift in BOTH directions (repo changed and VS Code changed), stop
   and ask D which side wins — `apply` overwrites D's live edits, `capture`
   overwrites the repo.
2. `apply` refuses a checkout on `main` that is behind `origin/main`. Run
   `git pull`; pass `--force` only if D asks.
3. After `capture`, never commit on `main`: branch, commit, open a PR (ready
   for review), after `make test` passes. The repo is public — if capture
   refuses a path or token, tell D which key; do not hand-edit around the guard.
4. Machine-local and secret-bearing keys (`scripts/capture-blocklist.json`)
   never enter the repo and are preserved on apply. To keep a new key local,
   add it to the blocklist in the same PR.
5. Finish with `make check` = `in sync`.
