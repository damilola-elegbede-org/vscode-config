.DEFAULT_GOAL := help

.PHONY: help bootstrap apply plan prune capture check test lint

help:
	@printf "Targets:\n"
	@printf "  bootstrap  Fresh Mac: brew-install VS Code, font, shfmt, then apply\n"
	@printf "  apply      Repo -> VS Code (keeps machine-local keys, backs up first)\n"
	@printf "  plan       Dry run of apply; writes nothing\n"
	@printf "  prune      apply, and uninstall extensions not in extensions.txt\n"
	@printf "  capture    VS Code -> repo (drops local/secret keys); then review git diff\n"
	@printf "  check      Report drift between repo and VS Code\n"
	@printf "  test       Run the hermetic test suite\n"
	@printf "  lint       ShellCheck (+ actionlint if installed)\n"

bootstrap:
	@./scripts/bootstrap.sh

apply:
	@./scripts/apply.sh

plan:
	@./scripts/apply.sh --dry-run

prune:
	@./scripts/apply.sh --prune

capture:
	@./scripts/capture.sh

check:
	@./scripts/check.sh

test:
	@./tests/test.sh

lint:
	@shellcheck -x scripts/*.sh tests/*.sh
	@if command -v actionlint >/dev/null; then actionlint; else echo "actionlint not installed; skipped"; fi
