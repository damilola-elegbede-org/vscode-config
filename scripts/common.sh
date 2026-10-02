#!/usr/bin/env bash
# Shared paths. Override VSCODE_USER_DIR / CODE_BIN / REPO_CONFIG_DIR for tests or non-default installs.
# shellcheck disable=SC2034  # consumed by the scripts that source this file
set -euo pipefail
export LC_ALL=C
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_CONFIG_DIR="${REPO_CONFIG_DIR:-$REPO_ROOT/system-configs}"
VSCODE_USER_DIR="${VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"
CODE_BIN="${CODE_BIN:-code}"
HELPER="$REPO_ROOT/scripts/vsconfig.py"
REPO_USER_DIR="$REPO_CONFIG_DIR/Code/User"
EXTENSIONS_FILE="$REPO_CONFIG_DIR/extensions.txt"

# Extension IDs from the repo list: lowercase, no CR, no blanks or comments, sorted.
repo_extensions() { tr -d '\r' < "$EXTENSIONS_FILE" | tr '[:upper:]' '[:lower:]' | grep -v -e '^[[:space:]]*$' -e '^#' | sort -u; }
live_extensions() { "$CODE_BIN" --list-extensions | tr -d '\r' | tr '[:upper:]' '[:lower:]' | sort -u; }
have_code() { command -v "$CODE_BIN" >/dev/null 2>&1; }
