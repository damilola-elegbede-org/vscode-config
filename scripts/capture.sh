#!/usr/bin/env bash
# VS Code -> repo. Strips machine keys, refuses absolute paths. Review `git diff` before committing.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
[[ -f "$VSCODE_USER_DIR/settings.json" ]] || { echo "error: no settings at $VSCODE_USER_DIR"; exit 1; }
mkdir -p "$REPO_USER_DIR"
python3 "$HELPER" capture-settings "$VSCODE_USER_DIR/settings.json" "$REPO_USER_DIR/settings.json"
if [[ -f "$VSCODE_USER_DIR/keybindings.json" ]]; then
  python3 "$HELPER" capture-json "$VSCODE_USER_DIR/keybindings.json" "$REPO_USER_DIR/keybindings.json"
fi
if [[ -d "$VSCODE_USER_DIR/snippets" ]] && [[ -n "$(ls -A "$VSCODE_USER_DIR/snippets")" ]]; then
  if grep -rEq '/(Users|home)/' "$VSCODE_USER_DIR/snippets"; then echo "error: snippets contain a machine path"; exit 1; fi
  rm -rf "$REPO_USER_DIR/snippets"; cp -R "$VSCODE_USER_DIR/snippets" "$REPO_USER_DIR/snippets"
fi
live_extensions > "$EXTENSIONS_FILE"
echo "captured into $REPO_CONFIG_DIR — review with: git diff"
