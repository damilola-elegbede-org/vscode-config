# vscode-config

Portable VS Code configuration for macOS. Apply it to any Mac, capture changes
back, and let Claude Code drive both with `/sync`.

```text
make apply    repo ─────────▶ VS Code   keeps this Mac's local keys, backs up first
make capture  VS Code ─────▶ repo       drops local/secret keys, refuses paths & tokens
make check    drift report; exit 1 if anything differs
```

Nothing is symlinked and VS Code Settings Sync is not used: you decide which
side wins, every time.

## Fresh Mac

```bash
# 1. Claude Code's own config first (skills, agents, styles, hooks, MCP, permissions)
git clone https://github.com/damilola-elegbede-org/claude-config.git && ./claude-config/scripts/sync.sh
# 2. VS Code
git clone https://github.com/damilola-elegbede-org/vscode-config.git && cd vscode-config
make plan        # what will happen (works before VS Code is installed)
make bootstrap   # Homebrew: VS Code, JetBrainsMono Nerd Font, shfmt; then apply
make check       # expect: in sync
```

Or open Claude Code in the clone and say "set up my VS Code".
Needs Homebrew. Optional: Xcode (Swift formatting), Terraform, Docker.

## Commands

| Command | Does |
| --- | --- |
| `make bootstrap` | Install VS Code, font, shfmt via Homebrew, then `apply`. Safe to re-run. |
| `make plan` | Dry run of `apply`. Writes nothing. |
| `make apply` | Repo → VS Code: settings, keybindings, snippets, missing extensions. Refuses a `main` checkout behind `origin/main` (`--force` to override). |
| `make prune` | `apply`, plus uninstall extensions not in `extensions.txt`. |
| `make capture` | VS Code → repo. Staged: on any refusal the repo is untouched. |
| `make check` | Settings, keybindings and extensions drift. |
| `make test` / `make lint` | 34 hermetic tests / ShellCheck + actionlint. |
| `/sync [check\|apply\|prune\|capture\|bootstrap]` | Claude Code skill in `.claude/skills/sync/` that runs the above with guardrails. |

## What stays local

`scripts/capture-blocklist.json` lists keys that never enter this public repo
and that `apply` preserves on each Mac: window size/zoom, workspace trust,
interpreter and executable paths, SSH remotes, and secret-bearing settings
(`rest-client.environmentVariables`, `sqltools.connections`,
`claudeCode.environmentVariables`). Capture also refuses machine paths
(`/Users/…`, `~/…`), email addresses, and API-token shapes (GitHub, Anthropic,
OpenAI, Slack, AWS, private keys).

## What's configured

| Area | Choice | Source |
| --- | --- | --- |
| Theme | Gruvbox Dark Hard, Gruvbox Material icons; high-contrast auto-detect off | tmux status bar palette |
| Terminal panel | Ghostty's 16-color palette, `#28fe14` on black, red blinking block cursor, blue selection, copy-on-select, no contrast boost | `ghostty +show-config` |
| Font | JetBrainsMono Nerd Font: editor 14, terminal 13, ligatures | Ghostty |
| Editing | Format on save per language, ESLint/Ruff fixes on save, rulers 80/100, autosave on focus change, sticky scroll, linked HTML tags, lockfile nesting, no minimap | |
| Search | `.claude/worktrees` and `node_modules` excluded from search and file watching | 30 Claude worktrees |
| Git | Prompt before committing to `main`/`master`; autofetch | |
| AI | Claude Code: bypass allowed and pinned as the start mode; CodeRabbit; built-in Copilot chat off | skills, agents, styles, hooks, MCP come from `~/.claude` |
| CSV | Rainbow CSV with Gruvbox column colors, aligned columns, grid, sticky header | |

### Formatters

| Languages | Formatter | On save |
| --- | --- | --- |
| JS, JSX, TS, TSX, CSS, HTML, Markdown | Prettier (only where a repo has a Prettier config) | yes |
| JSON, JSONC | VS Code built-in | yes |
| Python | Ruff (+ fix-all, organize imports) | yes |
| Shell (incl. `*.sh.mutation`) | shfmt | yes |
| YAML / Terraform / TOML / Swift | Red Hat YAML / HashiCorp / Even Better TOML / swift-format | yes |
| SQL | SQLTools | manual only (migrations never reformat silently) |

### Extensions (40)

Languages and lint: ESLint, Prettier, Python + Pylance + Ruff, ShellCheck, shfmt,
markdownlint, Markdown All in One, YAML, TOML, Terraform, Docker + Containers,
Swift, Tailwind CSS, Pretty TypeScript Errors, EditorConfig, Error Lens, Code
Spell Checker, Path Intellisense. Testing: Vitest, Playwright. Data: SQLTools +
SQLite driver, SQLite Viewer, Rainbow CSV, DotENV. Other: Excalidraw, REST
Client, Live Preview, GitHub Actions, GitHub Pull Requests, Gruvbox theme and
icons, Claude Code, CodeRabbit. Dependencies pulled in automatically (debugpy,
Python Environments, LLDB DAP) are listed too so `check` stays clean.

Every ID is verified by install before it is committed, and CI checks each
against the Marketplace.

## Keyboard: tmux-style panes

| Keys | Action | Where |
| --- | --- | --- |
| `ctrl+a` then `h/j/k/l` | Move to pane left/down/up/right | Outside the terminal (the terminal keeps `ctrl+a` for the shell and tmux) |
| `ctrl+a` then `v` / `s` | Split editor right / down | Outside the terminal |
| `ctrl+a` then `c` | New terminal | Outside the terminal |
| `cmd+ctrl+h/j/k/l` | Move to pane left/down/up/right | Everywhere, including the terminal |

`ctrl+a` no longer jumps to line start in the editor; use `cmd+left`.

## Layout

```text
system-configs/Code/User/   settings.json, keybindings.json (strict JSON, 2-space)
system-configs/extensions.txt  sorted, lowercase, one ID per line
scripts/                    bootstrap/apply/capture/check, vsconfig.py, capture-blocklist.json, check-marketplace.py
tests/test.sh               hermetic: fake `code`, temp dirs; runs on Linux and macOS (bash 3.2)
.claude/skills/sync/        the /sync skill
.github/                    CI (test matrix, lint, Marketplace), Dependabot, PR template
```

## CI and merging

`CI` runs on every PR and on `main`: `test (ubuntu-latest)`, `test (macos-latest)`
and `lint` are required to merge; `extension IDs exist` is advisory (network).
Dependabot keeps the Actions versions current.

## Limits

- macOS only.
- VS Code files must be strict JSON (no comments, no trailing commas); capture
  fails loudly otherwise.
- `apply` never uninstalls; use `make prune`.
