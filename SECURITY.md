# Security

This repository is public. It must never contain secrets, tokens, email
addresses, or machine-specific paths.

- `make capture` drops secret-bearing settings (see
  `scripts/capture-blocklist.json`) and refuses files containing machine paths
  or API-token shapes, in settings, keybindings and snippets. A refused
  capture leaves the repo untouched and never prints the matched value.
- If a secret is ever committed: rotate it first, then remove it from history.
- Report issues privately to the repository owner rather than in a public issue.
