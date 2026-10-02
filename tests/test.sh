#!/usr/bin/env bash
# Hermetic tests: fake `code` CLI, temp VS Code user dir, temp repo config copy.
# shellcheck disable=SC2015  # ok/bad always return 0
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { echo "ok   - $1"; pass=$((pass+1)); }
bad() { echo "FAIL - $1"; fail=$((fail+1)); }

# Fake code CLI backed by a state file.
mkdir -p "$T/bin"; : > "$T/installed"
cat > "$T/bin/code" <<STUB
#!/usr/bin/env bash
case "\$1" in
  --list-extensions) cat "$T/installed" ;;
  --install-extension) echo "\$2" >> "$T/installed" ;;
esac
STUB
chmod +x "$T/bin/code"
export CODE_BIN="$T/bin/code" VSCODE_USER_DIR="$T/user" REPO_CONFIG_DIR="$T/repo"
cp -R "$ROOT/system-configs" "$T/repo"

# 1. Repo files are strict JSON and extensions.txt is sorted, lowercase, unique.
python3 "$ROOT/scripts/vsconfig.py" validate "$ROOT"/system-configs/Code/User/*.json && ok "repo JSON is strict" || bad "repo JSON is strict"
e="$ROOT/system-configs/extensions.txt"
if diff -q "$e" <(tr '[:upper:]' '[:lower:]' < "$e" | sort -u) >/dev/null; then ok "extensions.txt sorted/lowercase/unique"; else bad "extensions.txt sorted/lowercase/unique"; fi

# 2. Dry run writes nothing.
"$ROOT/scripts/apply.sh" --dry-run >/dev/null
if [[ ! -e "$T/user" && ! -s "$T/installed" ]]; then ok "dry run writes nothing"; else bad "dry run writes nothing"; fi

# 3. Apply installs files + every extension.
"$ROOT/scripts/apply.sh" >/dev/null
cmp -s "$T/repo/Code/User/settings.json" "$T/user/settings.json" && ok "apply copies settings" || bad "apply copies settings"
diff -q <(sort "$T/installed") "$T/repo/extensions.txt" >/dev/null && ok "apply installs all extensions" || bad "apply installs all extensions"
"$ROOT/scripts/check.sh" >/dev/null && ok "check: in sync after apply" || bad "check: in sync after apply"

# 4. Second apply backs up the previous file.
"$ROOT/scripts/apply.sh" >/dev/null
ls "$T/user/.vscode-config-backups"/*/settings.json >/dev/null 2>&1 && ok "apply backs up existing files" || bad "apply backs up existing files"

# 5. Round trip: capture right after apply leaves repo unchanged.
cp -R "$T/repo" "$T/repo.before"
"$ROOT/scripts/capture.sh" >/dev/null
diff -r "$T/repo.before" "$T/repo" >/dev/null && ok "apply -> capture round trip is identity" || bad "apply -> capture round trip is identity"

# 6. Capture strips blocklisted machine keys; check ignores them.
python3 - "$T/user/settings.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["window.zoomLevel"]=2; d["security.workspace.trust.enabled"]=False; json.dump(d,open(p,"w"),indent=2)
PY
"$ROOT/scripts/check.sh" >/dev/null && ok "check ignores machine keys" || bad "check ignores machine keys"
"$ROOT/scripts/capture.sh" >/dev/null
grep -q 'zoomLevel\|workspace.trust' "$T/repo/Code/User/settings.json" && bad "capture strips machine keys" || ok "capture strips machine keys"

# 7. Real change is detected and captured.
python3 - "$T/user/settings.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["editor.fontSize"]=15; json.dump(d,open(p,"w"),indent=2)
PY
"$ROOT/scripts/check.sh" >/dev/null && bad "check detects drift" || ok "check detects drift"
"$ROOT/scripts/capture.sh" >/dev/null
grep -q '"editor.fontSize": 15' "$T/repo/Code/User/settings.json" && ok "capture keeps real changes" || bad "capture keeps real changes"

# 8. Capture refuses machine paths (public-repo leak guard).
python3 - "$T/user/settings.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["foo.path"]="/Users/someone/x"; json.dump(d,open(p,"w"),indent=2)
PY
if "$ROOT/scripts/capture.sh" >/dev/null 2>&1; then bad "capture refuses /Users/ paths"; else ok "capture refuses /Users/ paths"; fi

# 9. Capture refuses JSONC with a clear error.
printf '// comment\n{"a": 1}\n' > "$T/user/settings.json"
out="$("$ROOT/scripts/capture.sh" 2>&1 || true)"
grep -q "not strict JSON" <<<"$out" && ok "capture rejects JSONC clearly" || bad "capture rejects JSONC clearly"

# 10. Formatter coverage: every per-language formatter is an installed extension, and every
#     known formatter extension in the list is wired to at least one language.
if python3 - "$ROOT/system-configs" <<'PY2'
import json, sys
root = sys.argv[1]
d = json.load(open(f"{root}/Code/User/settings.json"))
exts = set(open(f"{root}/extensions.txt").read().split())
used = {v["editor.defaultFormatter"] for k, v in d.items()
        if k.startswith("[") and isinstance(v, dict) and "editor.defaultFormatter" in v}
FORMATTERS = {"esbenp.prettier-vscode", "charliermarsh.ruff", "mkhl.shfmt", "redhat.vscode-yaml",
              "hashicorp.terraform", "tamasfe.even-better-toml", "swiftlang.swift-vscode", "mtxr.sqltools"}
missing = used - exts
unwired = (FORMATTERS & exts) - used
if missing or unwired:
    print("formatter not installed:", sorted(missing), "| installed but unwired:", sorted(unwired))
    sys.exit(1)
PY2
then ok "formatter coverage"; else bad "formatter coverage"; fi

echo "$pass passed, $fail failed"
(( fail == 0 ))
