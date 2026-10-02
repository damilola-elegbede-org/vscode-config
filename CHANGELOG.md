# Changelog

## Unreleased

- JetBrainsMono Nerd Font only (no fallbacks) everywhere VS Code allows a font
  setting: editor, markdown preview, chat (including the
  Claude Code panel), chat code blocks, debug console, commit message box,
  notebook markdown.

## 0.1.0 — 2026-10-02

- Initial configuration: Gruvbox Charcoal theme (Gruvbox Dark Hard on deep charcoal), Ghostty-matched terminal panel,
  40 extensions, per-language formatters, tmux-style pane keys.
- Manual two-way sync: `bootstrap`, `plan`, `apply`, `prune`, `capture`,
  `check`; `/sync` Claude skill.
- Public-repo guards: local/secret keys stay local; capture refuses paths and
  tokens.
- CI: hermetic tests on Linux and macOS, ShellCheck, actionlint, Marketplace
  ID check; Dependabot for Actions.
