# Fresh-Mac install runbook

For a Claude Code session setting up D's VS Code on a new Mac. Follow the
steps in order. Each step has a check; do not continue past a failed check.
Steps marked **D** need D at the keyboard (password, GUI prompt, or login);
ask D to run them with the `!` prefix so the output lands in the session.

D's prompt to start a new session:

> Set up my VS Code on this Mac from
> https://github.com/damilola-elegbede-org/vscode-config — follow its
> INSTALL.md exactly and report each check.

## 0. Prerequisites

| Need                                  | Check                                                                           | If missing                                                                                                                                                     |
| ------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Homebrew                              | `brew --version`                                                                | **D:** `! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, then follow its "Next steps" to put `brew` on PATH |
| Xcode Command Line Tools (git, Swift) | `xcode-select -p`                                                               | **D:** `! xcode-select --install` (GUI dialog)                                                                                                                 |
| jq (claude-config sync)               | `jq --version`                                                                  | `brew install jq`                                                                                                                                              |
| GitHub access                         | `git ls-remote https://github.com/damilola-elegbede-org/vscode-config.git HEAD` | Both repos are public; no auth needed to clone. `gh` is only needed to open PRs: `brew install gh`, then **D:** `! gh auth login`                              |

## 1. Claude Code config first (claude-config)

The VS Code Claude extension reads `~/.claude` (skills, agents, output styles,
hooks, MCP, permission mode). Sync it before VS Code so the extension starts
with D's setup.

```bash
mkdir -p ~/dev && cd ~/dev
git clone https://github.com/damilola-elegbede-org/claude-config.git
cd claude-config && ./scripts/sync.sh
```

Check: `~/.claude/settings.json` exists and
`jq -r .permissions.defaultMode ~/.claude/settings.json` prints
`bypassPermissions`. If sync fails, stop and report its output; that is a
claude-config problem, not this repo's.

## 2. Clone this repo and preview

```bash
cd ~/dev
git clone https://github.com/damilola-elegbede-org/vscode-config.git
cd vscode-config
make plan
```

Check: `make plan` ends with `dry run: nothing written`. Show D the plan.

## 3. Bootstrap

```bash
make bootstrap
```

Installs VS Code, JetBrainsMono Nerd Font and shfmt with Homebrew, then
applies settings, keybindings and 40 extensions. Safe to re-run. Notes about
missing Terraform/Docker/Xcode are informational.

Check: `which code` prints a path, and the run ends with `applied. backup: …`.
If an extension install fails, re-run `make apply` once. If it fails again,
stop: report the extension ID and the error to D, and do not continue to
step 4 (step 5's `make check` cannot pass with it missing).

## 4. First launch (D)

**D:** open VS Code once on the dev folder (`open -a "Visual Studio Code" ~/dev`).
VS Code has no default-folder setting; its default `window.restoreWindows`
(`all`, machine-local, never captured) reopens the last folder, so every later
launch starts in `~/dev`. macOS may ask
to confirm opening an app downloaded from the internet; choose Open. Wait for
the window, then continue.

## 5. Verify

Run all of these and report the output verbatim:

```bash
make check                                     # expect: in sync
sqlite3 ~/Library/Application\ Support/Code/User/globalStorage/state.vscdb \
  "select substr(value,1,80) from ItemTable where key='colorThemeData';"
                                               # expect: ..."label":"Dark 2026"...
/bin/zsh -ilc 'echo shell-ok'                  # expect: shell-ok, exit 0
system_profiler SPFontsDataType | grep -c 'Family: JetBrainsMono Nerd Font'
                                               # expect: a number > 0
```

Then ask D to confirm visually: Dark 2026 editor (neutral dark; no charcoal override), black terminal
panel with green text, and the Claude Code panel showing **Bypass
permissions** as the mode.

## Known problems and fixes

| Symptom                                            | Cause                                                                                             | Fix                                                                                                                                        |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| "Unable to resolve your shell environment"         | `~/.zshrc` auto-starts tmux in every interactive shell, including VS Code's background `zsh -ilc` | Guard the autostart: add `[ -t 1 ] && [ -z "$VSCODE_RESOLVING_ENVIRONMENT" ]` to the `if` that runs `exec tmux`. Back up `~/.zshrc` first. |
| Theme is High Contrast (black with orange borders) | VS Code auto-switched on first launch                                                             | Already prevented by `window.autoDetectHighContrast: false`; if seen, run `make apply` and reload the window                               |
| Theme silently stays default                       | Theme label typo, or VS Code older than the built-in Dark 2026 theme                              | `make check`; `code --version`; upgrade VS Code (`brew upgrade --cask visual-studio-code`) and reload the window                           |
| `make capture`/`check` says "not strict JSON"      | A comment or trailing comma in VS Code's file                                                     | Remove it in VS Code; do not hand-edit the repo around it                                                                                  |
| `code: command not found`                          | Cask link missing                                                                                 | `brew reinstall --cask visual-studio-code`                                                                                                 |
| Claude panel not in Bypass                         | Extension remembers an old UI choice, or `~/.claude` not synced                                   | Step 1 check; `claudeCode.initialPermissionMode` is pinned in this repo                                                                    |
| `make apply` refuses: behind origin/main           | Stale clone on `main`                                                                             | `git pull`, then re-run                                                                                                                    |

## If something is wrong with this repo

Do not patch around it locally. Create a branch, fix it, run `make test` and
`make lint`, and open a PR (ready for review) against `main` describing the
symptom, the cause, and the fix. CI must be green to merge.

## Done when

- [ ] `make check` prints `in sync`
- [ ] Theme row shows `Dark 2026`
- [ ] `zsh -ilc` exits 0
- [ ] JetBrainsMono Nerd Font installed
- [ ] D confirmed the look and the Bypass permissions mode
