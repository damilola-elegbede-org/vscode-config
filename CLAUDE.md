# vscode-config

Source of truth for D's VS Code on macOS. The repo owns `settings.json`,
`keybindings.json`, `snippets/` (if any) and `extensions.txt`. Sync is manual
and two-way; use the `/sync` skill (`.claude/skills/sync/SKILL.md`) for every
sync request. It holds the rules: check first, ask D when both sides changed,
never commit on `main`.

## Fresh Mac ("set up my VS Code")

Follow `INSTALL.md` step by step: prerequisites, claude-config first, plan,
bootstrap, first launch, verify. Report every check verbatim. If the repo
itself is wrong, fix it on a branch and open a PR; do not patch around it.

## Changing the config

- Prefer `make capture` from a live VS Code over hand edits. Hand edits to
  `system-configs/` must stay strict JSON, 2-space, sorted extension list.
- New extension: install it with `code --install-extension <id>` first; only
  commit IDs that installed. If it formats a language, add a `[lang]` block
  with `editor.defaultFormatter` + `editor.formatOnSave`, and add it to
  `FORMATTERS` in `tests/test.sh` (test 14 fails otherwise).
- New theme or setting ID: copy names exactly from the extension's
  `package.json` — a wrong theme label silently falls back to the default.
- Machine-local or secret-bearing key: add it to
  `scripts/capture-blocklist.json` so capture drops it and apply keeps it.

## Rules

- Public repo: never commit secrets, tokens, emails, or machine paths. The
  capture guard refuses them; tell D which key tripped it.
- `make test` and `make lint` before every commit. CI must be green to merge.
- MCP servers, skills, agents, output styles and hooks live in `~/.claude`
  (claude-config). Two Claude settings live here:
  `claudeCode.allowDangerouslySkipPermissions: true` (the extension blocks
  bypass without it) and `claudeCode.initialPermissionMode: "bypassPermissions"`.
  The second is required: without it the extension reuses whatever mode was
  last picked in its UI before it consults `~/.claude`
  (`getInitialPermissionMode()` in the extension's `extension.js`).
- Trusted folders are Claude's `trustedDirectories` in `~/.claude`, not VS Code
  workspace trust (`security.workspace.trust.*` stays local).
- `~/.zshrc` must keep its tmux auto-start guarded with `[ -t 1 ]` and
  `$VSCODE_RESOLVING_ENVIRONMENT`, or VS Code reports "Unable to resolve your
  shell environment".
