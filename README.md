# vscode-config

Portable VS Code configuration for macOS. Apply it to any Mac, capture changes
back, and let Claude Code drive both.

```text
make apply    repo ─────────▶ VS Code   (backs up current files first)
make capture  VS Code ─────▶ repo       (strips machine keys; review git diff)
make check    report drift between the two
```

## Fresh Mac

```bash
gh repo clone damilola-elegbede-org/vscode-config && cd vscode-config
make bootstrap        # or: ask Claude Code "set up my VS Code"
```

Requires Homebrew. Installs VS Code, JetBrainsMono Nerd Font, shfmt, then applies.

## What's configured

| Area | Choice | Why |
| --- | --- | --- |
| Editor theme | Gruvbox Dark Hard | Matches the tmux status bar palette |
| Terminal panel | Ghostty's full 16-color palette, `#28fe14` on black, red blinking block cursor, blue selection, copy-on-select, no contrast boost | Mirrors Ghostty (`ghostty +show-config`); transparency/blur not possible in VS Code |
| Font | JetBrainsMono Nerd Font, editor 14 / terminal 13, ligatures | Same family as Ghostty |
| Editing | Format on save (only languages with a formatter; Prettier only where a repo has a Prettier config), rulers 80/100, autosave on focus change, no minimap | |
| Languages | JS/JSX/TS, Python, shell, Markdown, HTML/CSS, YAML, GitHub Actions, Docker, Terraform, Tailwind | Drawn from session edit history |
| AI | Claude Code, CodeRabbit; built-in Copilot chat disabled | MCP lives in `~/.claude` (claude-config) |

Formatters per language: Prettier (JS/TS/JSON/CSS/HTML/Markdown), Ruff (Python),
shfmt (shell), Red Hat YAML, HashiCorp Terraform.

## Pane navigation (tmux-style)

| Keys | Action | Where |
| --- | --- | --- |
| `ctrl+a` then `h/j/k/l` | Move to pane left/down/up/right | Outside the terminal (the terminal keeps `ctrl+a` for the shell and tmux) |
| `ctrl+a` then `v` / `s` | Split editor right / down | Outside the terminal |
| `ctrl+a` then `c` | New terminal | Outside the terminal |
| `cmd+ctrl+h/j/k/l` | Move to pane left/down/up/right | Everywhere, including the terminal |

Note: `ctrl+a` no longer jumps to line start in the editor; use `cmd+left`.

## Layout

```text
system-configs/
  Code/User/settings.json      strict JSON, 2-space
  Code/User/keybindings.json
  extensions.txt               sorted, lowercase, one ID per line
scripts/
  bootstrap.sh apply.sh capture.sh check.sh common.sh
  vsconfig.py                  strict parse, blocklist strip, leak guard
  capture-blocklist.json       machine-specific keys capture drops
tests/test.sh                  hermetic: fake `code`, temp dirs
```

## Limits

- macOS only.
- VS Code files must be strict JSON (no comments, no trailing commas); capture
  fails loudly otherwise.
- Extensions installed but not in the list are reported, never uninstalled.
