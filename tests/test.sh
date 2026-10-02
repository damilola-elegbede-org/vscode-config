#!/usr/bin/env bash
# Hermetic tests: fake `code` CLI, temp VS Code user dir, temp repo config copy.
# shellcheck disable=SC2015  # ok/bad always return 0
set -euo pipefail
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { echo "ok   - $1"; pass=$((pass+1)); }
bad() { echo "FAIL - $1"; fail=$((fail+1)); }
edit_live() {  # edit_live 'python expression on d'
  python3 - "$T/user/settings.json" "$1" <<'PY'
import json, sys
p, expr = sys.argv[1], sys.argv[2]
d = json.load(open(p)); exec(expr); json.dump(d, open(p, "w"), indent=2)
PY
}

# Fake code CLI backed by a state file. FAKE_CODE_FAIL=1 makes it exit 1 with no output.
mkdir -p "$T/bin"; : > "$T/installed"
cat > "$T/bin/code" <<STUB
#!/usr/bin/env bash
[[ -n "\${FAKE_CODE_FAIL:-}" ]] && exit 1
case "\$1" in
  --list-extensions) cat "$T/installed" ;;
  --install-extension) echo "\$2" >> "$T/installed"; echo "install \$2" >> "$T/calls" ;;
  --uninstall-extension) grep -vx "\$2" "$T/installed" > "$T/i2" || true; mv "$T/i2" "$T/installed" ;;
esac
STUB
chmod +x "$T/bin/code"
export CODE_BIN="$T/bin/code" VSCODE_USER_DIR="$T/user" REPO_CONFIG_DIR="$T/repo"
cp -R "$ROOT/system-configs" "$T/repo"

# 1. Repo files are strict JSON and extensions.txt is sorted, lowercase, unique.
python3 "$ROOT/scripts/vsconfig.py" validate "$ROOT"/system-configs/Code/User/*.json && ok "repo JSON is strict" || bad "repo JSON is strict"
e="$ROOT/system-configs/extensions.txt"
if diff -q "$e" <(tr '[:upper:]' '[:lower:]' < "$e" | sort -u) >/dev/null; then ok "extensions.txt sorted/lowercase/unique"; else bad "extensions.txt sorted/lowercase/unique"; fi

# 2. Dry run writes nothing, and works before VS Code is installed (no code on PATH).
CODE_BIN="$T/bin/nonexistent" "$ROOT/scripts/apply.sh" --dry-run >/dev/null 2>&1 && ok "plan works without code installed" || bad "plan works without code installed"
if [[ ! -e "$T/user" && ! -s "$T/installed" ]]; then ok "dry run writes nothing"; else bad "dry run writes nothing"; fi

# 3. Apply installs files + every extension.
"$ROOT/scripts/apply.sh" >/dev/null
python3 "$ROOT/scripts/vsconfig.py" same-json "$T/repo/Code/User/settings.json" "$T/user/settings.json" && ok "apply writes settings" || bad "apply writes settings"
diff -q <(sort "$T/installed") "$T/repo/extensions.txt" >/dev/null && ok "apply installs all extensions" || bad "apply installs all extensions"
"$ROOT/scripts/check.sh" >/dev/null && ok "check: in sync after apply" || bad "check: in sync after apply"

# 4. Second apply backs up the previous file.
"$ROOT/scripts/apply.sh" >/dev/null
ls "$T/user/.vscode-config-backups"/*/settings.json >/dev/null 2>&1 && ok "apply backs up existing files" || bad "apply backs up existing files"

# 5. Round trip: capture right after apply leaves repo unchanged.
cp -R "$T/repo" "$T/repo.before"
"$ROOT/scripts/capture.sh" >/dev/null
diff -r "$T/repo.before" "$T/repo" >/dev/null && ok "apply -> capture round trip is identity" || bad "apply -> capture round trip is identity"

# 6. Machine-local and secret keys: kept live by apply, ignored by check, never captured.
edit_live 'd["window.zoomLevel"]=2; d["security.workspace.trust.enabled"]=False; d["rest-client.environmentVariables"]={"prod":{"token":"x"}}'
"$ROOT/scripts/apply.sh" >/dev/null
grep -q '"window.zoomLevel": 2' "$T/user/settings.json" && grep -q 'rest-client.environmentVariables' "$T/user/settings.json" \
  && ok "apply keeps machine-local and secret keys" || bad "apply keeps machine-local and secret keys"
"$ROOT/scripts/check.sh" >/dev/null && ok "check ignores machine keys" || bad "check ignores machine keys"
"$ROOT/scripts/capture.sh" >/dev/null
grep -q 'zoomLevel\|workspace.trust\|rest-client' "$T/repo/Code/User/settings.json" && bad "capture drops local/secret keys" || ok "capture drops local/secret keys"

# 7. Real change is detected and captured.
edit_live 'd["editor.fontSize"]=15'
"$ROOT/scripts/check.sh" >/dev/null && bad "check detects drift" || ok "check detects drift"
"$ROOT/scripts/capture.sh" >/dev/null
grep -q '"editor.fontSize": 15' "$T/repo/Code/User/settings.json" && ok "capture keeps real changes" || bad "capture keeps real changes"

# 8. Capture refuses machine paths and tokens, and leaves the repo untouched.
cp "$T/repo/Code/User/settings.json" "$T/before.json"
for bad_value in '/Users/someone/x' 'ghp_abcdefghijklmnopqrstuvwxyz0123' 'sk-ant-api03-abcdefghij'; do
  edit_live "d['foo.value']='$bad_value'"
  if "$ROOT/scripts/capture.sh" >/dev/null 2>&1; then bad "capture refuses $bad_value"; else ok "capture refuses ${bad_value:0:8}..."; fi
done
cmp -s "$T/before.json" "$T/repo/Code/User/settings.json" && ok "refused capture leaves repo untouched" || bad "refused capture leaves repo untouched"
edit_live 'd.pop("foo.value")'

# 9. Capture never truncates extensions.txt when code fails.
cp "$T/repo/extensions.txt" "$T/ext.before"
FAKE_CODE_FAIL=1 "$ROOT/scripts/capture.sh" >/dev/null 2>&1 || true
cmp -s "$T/ext.before" "$T/repo/extensions.txt" && ok "failed capture keeps extensions.txt" || bad "failed capture keeps extensions.txt"

# 10. CRLF in extensions.txt does not trigger reinstalls or drift.
: > "$T/calls"; sed 's/$/\r/' "$T/ext.before" > "$T/repo/extensions.txt"
"$ROOT/scripts/apply.sh" >/dev/null
[[ ! -s "$T/calls" ]] && ok "CRLF list: no reinstalls" || bad "CRLF list: no reinstalls"
cp "$T/ext.before" "$T/repo/extensions.txt"

# 11. --prune uninstalls extras; plain apply leaves them.
echo "someone.extra-ext" >> "$T/installed"
"$ROOT/scripts/apply.sh" >/dev/null; grep -qx someone.extra-ext "$T/installed" && ok "apply leaves extras" || bad "apply leaves extras"
"$ROOT/scripts/apply.sh" --prune >/dev/null; grep -qx someone.extra-ext "$T/installed" && bad "prune removes extras" || ok "prune removes extras"

# 12. check reports a missing live file instead of crashing.
mv "$T/user/keybindings.json" "$T/kb.json"
out="$("$ROOT/scripts/check.sh" 2>&1 || true)"
grep -q "keybindings.json missing" <<<"$out" && ! grep -q Traceback <<<"$out" && ok "check reports missing file" || bad "check reports missing file"
mv "$T/kb.json" "$T/user/keybindings.json"

# 13. Capture refuses JSONC with a clear error.
printf '// comment\n{"a": 1}\n' > "$T/user/settings.json"
out="$("$ROOT/scripts/capture.sh" 2>&1 || true)"
grep -q "not strict JSON" <<<"$out" && ok "capture rejects JSONC clearly" || bad "capture rejects JSONC clearly"

# 14. Formatter coverage: every per-language formatter is installed (built-ins exempt), and every
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
missing = {f for f in used - exts if not f.startswith("vscode.")}
unwired = (FORMATTERS & exts) - used
if missing or unwired:
    print("formatter not installed:", sorted(missing), "| installed but unwired:", sorted(unwired))
    sys.exit(1)
PY2
then ok "formatter coverage"; else bad "formatter coverage"; fi

# 15. Snippets are a set: check sees drift, apply mirrors the repo (old set kept in backup),
#     capture propagates deletions.
cp "$T/repo/Code/User/settings.json" "$T/user/settings.json"  # undo test 13's JSONC file
"$ROOT/scripts/check.sh" >/dev/null && ok "baseline in sync before snippet tests" || bad "baseline in sync before snippet tests"
mkdir -p "$T/repo/Code/User/snippets"; printf '{"a":{"prefix":"a","body":"a"}}\n' > "$T/repo/Code/User/snippets/a.json"
"$ROOT/scripts/check.sh" >/dev/null 2>&1 && bad "check sees snippet drift" || ok "check sees snippet drift"
"$ROOT/scripts/apply.sh" >/dev/null
printf '{}\n' > "$T/user/snippets/stray.json"
"$ROOT/scripts/apply.sh" >/dev/null
[[ -f "$T/user/snippets/a.json" && ! -e "$T/user/snippets/stray.json" ]] && ok "apply mirrors snippet set" || bad "apply mirrors snippet set"
ls "$T/user/.vscode-config-backups"/*/snippets/stray.json >/dev/null 2>&1 && ok "apply backs up replaced snippets" || bad "apply backs up replaced snippets"
mv "$T/user/snippets" "$T/snippets.gone"
"$ROOT/scripts/capture.sh" >/dev/null
[[ ! -e "$T/repo/Code/User/snippets" ]] && ok "capture propagates snippet deletion" || bad "capture propagates snippet deletion"

# 16. Two applies in the same second get distinct backups.
before="$(find "$T/user/.vscode-config-backups" -mindepth 1 -maxdepth 1 -type d | wc -l)"
"$ROOT/scripts/apply.sh" >/dev/null; "$ROOT/scripts/apply.sh" >/dev/null
after="$(find "$T/user/.vscode-config-backups" -mindepth 1 -maxdepth 1 -type d | wc -l)"
(( after - before == 2 )) && ok "each apply gets its own backup" || bad "each apply gets its own backup"

echo "$pass passed, $fail failed"
(( fail == 0 ))
