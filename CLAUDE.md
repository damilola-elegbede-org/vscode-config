# vscode-config

Source of truth for D's VS Code setup on macOS. The repo owns `settings.json`,
`keybindings.json`, `snippets/` (if any) and the extension list. Nothing is
symlinked; sync is manual and two-way.

## When D says "set up my VS Code" (fresh Mac)

1. `make bootstrap` — installs VS Code, JetBrainsMono Nerd Font and shfmt via
   Homebrew, then applies the config and installs every extension.
2. `make check` — must print `in sync`. Report its output verbatim.
3. Tell D to open VS Code once; first launch finishes extension activation.

## When D says "apply" / "push my config to VS Code"

`make plan` first and show D what will change, then `make apply`. Existing
files are backed up to `~/Library/Application Support/Code/User/.vscode-config-backups/<timestamp>/`.

## When D says "capture" / "save my VS Code changes"

1. `make capture`
2. Show D `git diff --stat` and the meaningful hunks.
3. On D's go-ahead: branch, commit, PR (ready for review).

Capture strips machine-specific keys listed in `scripts/capture-blocklist.json`
and refuses any file containing a `/Users/<name>` path, because this repo is
public. If capture fails with "not strict JSON", remove comments or trailing
commas from the VS Code file and re-run; do not hand-edit around it.

## Rules

- Never commit secrets, tokens, or machine paths. The repo is public.
- MCP servers are not configured here; Claude Code reads them from `~/.claude`
  (managed by claude-config).
- Run `make test` before every commit. CI runs ShellCheck and the same tests.
- A new extension goes in via VS Code then `make capture`, or by editing
  `system-configs/extensions.txt` (sorted, lowercase) then `make apply`.
