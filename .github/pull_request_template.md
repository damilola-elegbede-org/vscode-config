## What changed

<!-- settings / keybindings / extensions / scripts / docs -->

## How it was produced

- [ ] `make capture` from a live VS Code (paste `git diff --stat`), or
- [ ] hand edit to `system-configs/`, then `make apply` + `make check`

## Checks

- [ ] `make test` passes
- [ ] No secrets, tokens, or `/Users/<name>` paths (repo is public)
- [ ] New extension IDs were installed successfully with `code --install-extension`
