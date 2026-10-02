#!/usr/bin/env bash
# Fresh Mac: install VS Code, font, shfmt via Homebrew, then apply.
set -euo pipefail
command -v brew >/dev/null || { echo "error: install Homebrew first: https://brew.sh"; exit 1; }
brew list --cask visual-studio-code >/dev/null 2>&1 || brew install --cask visual-studio-code
brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1 || brew install --cask font-jetbrains-mono-nerd-font
brew list shfmt >/dev/null 2>&1 || brew install shfmt
exec "$(dirname "$0")/apply.sh" "$@"
