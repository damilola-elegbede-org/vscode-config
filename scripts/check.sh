#!/usr/bin/env bash
# Report drift between repo and live VS Code. Exit 1 on any drift.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
drift=0
compare() {  # compare MODE FILE
  local live="$VSCODE_USER_DIR/$2"
  if [[ ! -f "$live" ]]; then echo "drift: $2 missing in VS Code"; drift=1; return; fi
  python3 "$HELPER" validate "$live"
  python3 "$HELPER" "$1" "$REPO_USER_DIR/$2" "$live" || { echo "drift: $2"; drift=1; }
}
compare same-settings settings.json
compare same-json keybindings.json
empty="$(mktemp -d)"; trap 'rmdir "$empty"' EXIT
r="$REPO_USER_DIR/snippets"; l="$VSCODE_USER_DIR/snippets"
[[ -d "$r" ]] || r="$empty"; [[ -d "$l" ]] || l="$empty"
diff -rq "$r" "$l" >/dev/null || { echo "drift: snippets"; drift=1; }
if have_code; then
  ext_diff="$(diff <(repo_extensions) <(live_extensions) || true)"
  [[ -n "$ext_diff" ]] && { echo "drift: extensions (< repo only, > VS Code only)"; echo "$ext_diff"; drift=1; }
else
  echo "drift: '$CODE_BIN' not on PATH; extensions not checked"; drift=1
fi
if (( drift )); then echo "run 'make apply' (repo wins) or 'make capture' (VS Code wins)"; exit 1; fi
echo "in sync"
