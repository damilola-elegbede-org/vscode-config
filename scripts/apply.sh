#!/usr/bin/env bash
# Repo -> VS Code. Keeps the live machine's local keys (see capture-blocklist.json) and backs up first.
#   --dry-run  print the plan, write nothing (works before VS Code is installed)
#   --prune    also uninstall extensions that are not in extensions.txt
#   --force    apply even if this checkout is behind origin/main
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"
DRY=0; PRUNE=0; FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --prune) PRUNE=1 ;;
    --force) FORCE=1 ;;
    *) echo "error: unknown option $arg"; exit 2 ;;
  esac
done
run() { if (( DRY )); then echo "would: $*"; else "$@"; fi; }

python3 "$HELPER" validate "$REPO_USER_DIR/settings.json" "$REPO_USER_DIR/keybindings.json"

# Refuse a stale checkout on main: applying it would roll VS Code back.
if (( ! FORCE )) && git -C "$REPO_ROOT" rev-parse --verify -q origin/main >/dev/null; then
  if [[ "$(git -C "$REPO_ROOT" branch --show-current)" == "main" ]] \
     && [[ "$(git -C "$REPO_ROOT" rev-list --count HEAD..origin/main)" != "0" ]]; then
    echo "error: this checkout is behind origin/main. Run 'git pull' first, or pass --force."; exit 1
  fi
fi

if (( ! DRY )) && ! have_code; then echo "error: '$CODE_BIN' not on PATH (run make bootstrap)"; exit 1; fi

backup="$VSCODE_USER_DIR/.vscode-config-backups/$(date +%Y%m%d-%H%M%S)"
run mkdir -p "$VSCODE_USER_DIR"
for f in settings.json keybindings.json; do
  if [[ -f "$VSCODE_USER_DIR/$f" ]]; then run mkdir -p "$backup"; run cp "$VSCODE_USER_DIR/$f" "$backup/$f"; fi
done
if (( DRY )); then
  echo "would: write settings.json (repo keys + this machine's local keys)"
else
  tmp="$(mktemp)"
  python3 "$HELPER" apply-settings "$REPO_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json" "$tmp"
  mv "$tmp" "$VSCODE_USER_DIR/settings.json"
fi
run cp "$REPO_USER_DIR/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
if [[ -d "$REPO_USER_DIR/snippets" ]]; then
  if [[ -d "$VSCODE_USER_DIR/snippets" ]]; then run mkdir -p "$backup"; run cp -R "$VSCODE_USER_DIR/snippets" "$backup/"; fi
  run mkdir -p "$VSCODE_USER_DIR/snippets"
  run cp -R "$REPO_USER_DIR/snippets/." "$VSCODE_USER_DIR/snippets/"
fi

wanted="$(repo_extensions)"
installed=""; have_code && installed="$(live_extensions)"
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  grep -Fqx "$ext" <<<"$installed" || run "$CODE_BIN" --install-extension "$ext"
done <<<"$wanted"

extra="$(comm -13 <(echo "$wanted") <(echo "$installed") | grep -v '^$' || true)"
if [[ -n "$extra" ]]; then
  if (( PRUNE )); then
    while IFS= read -r ext; do run "$CODE_BIN" --uninstall-extension "$ext"; done <<<"$extra"
  else
    printf 'note: installed but not in repo (left alone; use --prune to remove):\n%s\n' "$extra"
  fi
fi
if (( DRY )); then echo "dry run: nothing written"; else echo "applied. backups (if any): $backup"; fi
