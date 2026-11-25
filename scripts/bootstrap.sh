#!/usr/bin/env bash
# Fresh Mac: install VS Code, font, shfmt via Homebrew, then apply. Safe to re-run.
set -euo pipefail
command -v brew >/dev/null || { echo "error: install Homebrew first: https://brew.sh"; exit 1; }
xcode-select -p >/dev/null 2>&1 || echo "note: Xcode Command Line Tools missing (xcode-select --install); Swift formatting needs Xcode."
brew list --cask visual-studio-code >/dev/null 2>&1 || brew install --cask visual-studio-code
brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1 || brew install --cask font-jetbrains-mono-nerd-font
brew list shfmt >/dev/null 2>&1 || brew install shfmt
command -v docker >/dev/null || echo "note: docker not installed; its VS Code integration stays idle until it is."
exec "$(dirname "$0")/apply.sh" "$@"
