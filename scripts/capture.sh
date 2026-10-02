#!/usr/bin/env bash
# VS Code -> repo. Drops machine-local and secret-bearing keys, refuses paths/tokens. Review `git diff` before committing.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
[[ -f "$VSCODE_USER_DIR/settings.json" ]] || { echo "error: no settings at $VSCODE_USER_DIR"; exit 1; }
have_code || { echo "error: '$CODE_BIN' not on PATH"; exit 1; }
mkdir -p "$REPO_USER_DIR"

# Stage everything first so a failure leaves the repo untouched.
stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT
python3 "$HELPER" capture-settings "$VSCODE_USER_DIR/settings.json" "$stage/settings.json"
if [[ -f "$VSCODE_USER_DIR/keybindings.json" ]]; then
  python3 "$HELPER" capture-json "$VSCODE_USER_DIR/keybindings.json" "$stage/keybindings.json"
fi
if [[ -d "$VSCODE_USER_DIR/snippets" ]] && [[ -n "$(ls -A "$VSCODE_USER_DIR/snippets")" ]]; then
  find "$VSCODE_USER_DIR/snippets" -type f -print0 | xargs -0 python3 "$HELPER" scan-text
  cp -R "$VSCODE_USER_DIR/snippets" "$stage/snippets"
fi
live_extensions > "$stage/extensions.txt"
[[ -s "$stage/extensions.txt" ]] || { echo "error: '$CODE_BIN --list-extensions' returned nothing; repo untouched"; exit 1; }

mv "$stage/settings.json" "$REPO_USER_DIR/settings.json"
[[ -f "$stage/keybindings.json" ]] && mv "$stage/keybindings.json" "$REPO_USER_DIR/keybindings.json"
# Snippets are a set: deletions in VS Code propagate.
if [[ -d "$REPO_USER_DIR/snippets" ]]; then mv "$REPO_USER_DIR/snippets" "$stage/old-snippets"; fi
if [[ -d "$stage/snippets" ]]; then mv "$stage/snippets" "$REPO_USER_DIR/snippets"; fi
mv "$stage/extensions.txt" "$EXTENSIONS_FILE"
echo "captured into $REPO_CONFIG_DIR — review with: git diff"
