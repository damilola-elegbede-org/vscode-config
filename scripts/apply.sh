#!/usr/bin/env bash
# Repo -> VS Code. Backs up existing files first. --dry-run prints the plan and writes nothing.
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
run() { if (( DRY )); then echo "would: $*"; else "$@"; fi; }

python3 "$HELPER" validate "$REPO_USER_DIR/settings.json" "$REPO_USER_DIR/keybindings.json"
command -v "$CODE_BIN" >/dev/null || { echo "error: '$CODE_BIN' not on PATH (run make bootstrap)"; exit 1; }

backup="$VSCODE_USER_DIR/.vscode-config-backups/$(date +%Y%m%d-%H%M%S)"
run mkdir -p "$VSCODE_USER_DIR"
for f in settings.json keybindings.json; do
  if [[ -f "$VSCODE_USER_DIR/$f" ]]; then run mkdir -p "$backup"; run cp "$VSCODE_USER_DIR/$f" "$backup/$f"; fi
  run cp "$REPO_USER_DIR/$f" "$VSCODE_USER_DIR/$f"
done
if [[ -d "$REPO_USER_DIR/snippets" ]]; then
  [[ -d "$VSCODE_USER_DIR/snippets" ]] && { run mkdir -p "$backup"; run cp -R "$VSCODE_USER_DIR/snippets" "$backup/"; }
  run mkdir -p "$VSCODE_USER_DIR/snippets"
  run cp -R "$REPO_USER_DIR/snippets/." "$VSCODE_USER_DIR/snippets/"
fi

installed="$(live_extensions)"
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  grep -qx "$ext" <<<"$installed" || run "$CODE_BIN" --install-extension "$ext"
done < "$EXTENSIONS_FILE"

extra="$(comm -13 "$EXTENSIONS_FILE" <(echo "$installed") || true)"
[[ -n "$extra" ]] && printf 'note: installed but not in repo (left alone):\n%s\n' "$extra"
(( DRY )) && echo "dry run: nothing written" || echo "applied. backups (if any): $backup"
