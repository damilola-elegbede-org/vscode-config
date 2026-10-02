.DEFAULT_GOAL := help

.PHONY: help bootstrap apply plan capture check test

help:
	@printf "Targets:\n"
	@printf "  bootstrap  Fresh Mac: brew-install VS Code, font, shfmt, then apply\n"
	@printf "  apply      Repo -> VS Code (backs up current files)\n"
	@printf "  plan       Dry run of apply; writes nothing\n"
	@printf "  capture    VS Code -> repo (strips machine keys); then review git diff\n"
	@printf "  check      Report drift between repo and VS Code\n"
	@printf "  test       Run the test suite\n"

bootstrap:
	@./scripts/bootstrap.sh

apply:
	@./scripts/apply.sh

plan:
	@./scripts/apply.sh --dry-run

capture:
	@./scripts/capture.sh

check:
	@./scripts/check.sh

test:
	@./tests/test.sh
