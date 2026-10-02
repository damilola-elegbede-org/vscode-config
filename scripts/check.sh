#!/usr/bin/env bash
# Report drift between repo and live VS Code. Exit 1 on any drift.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
drift=0
python3 "$HELPER" validate "$VSCODE_USER_DIR/settings.json" "$VSCODE_USER_DIR/keybindings.json"
python3 "$HELPER" same-settings "$REPO_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json" \
  || { echo "drift: settings.json"; drift=1; }
python3 "$HELPER" same-json "$REPO_USER_DIR/keybindings.json" "$VSCODE_USER_DIR/keybindings.json" \
  || { echo "drift: keybindings.json"; drift=1; }
ext_diff="$(diff "$EXTENSIONS_FILE" <(live_extensions) || true)"
[[ -n "$ext_diff" ]] && { echo "drift: extensions"; echo "$ext_diff"; drift=1; }
(( drift )) && { echo "run 'make apply' (repo wins) or 'make capture' (VS Code wins)"; exit 1; }
echo "in sync"
