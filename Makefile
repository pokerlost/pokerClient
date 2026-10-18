.DEFAULT_GOAL := help
FLUTTER ?= flutter
DART ?= dart
UV ?= uv
export CI ?= true
export FLUTTER_SUPPRESS_ANALYTICS := true
export XDG_CONFIG_HOME ?= $(CURDIR)/.local/config
export ANALYZER_STATE_LOCATION_OVERRIDE ?= $(CURDIR)/.local/analyzer

.PHONY: help install lint typecheck test-unit test build build-web build-linux legacy-test legacy-build export-web run
help:
	@echo "install lint typecheck test-unit test build export-web run"
install:
	$(FLUTTER) pub get --enforce-lockfile
	$(UV) sync --locked
lint:
	$(DART) format --output=none --set-exit-if-changed packages apps/poker_client/lib apps/poker_client/test apps/poker_client/integration_test apps/poker_game_web/lib
	$(UV) run --locked ruff check src tools tests
	$(UV) run --locked ruff format --check src tools tests
typecheck:
	$(FLUTTER) analyze --no-pub
	$(UV) run --locked mypy
test-unit:
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/contract/lcov.info packages/poker_contract/test
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/game/lcov.info packages/poker_game/test
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/native/lcov.info apps/poker_client/test
	$(MAKE) legacy-test
legacy-test:
	$(UV) run --locked pytest --cov --cov-report=term-missing --cov-report=json --cov-report=xml
legacy-build:
	$(UV) build --no-build-isolation
build: build-web build-linux
build-web:
	cd apps/poker_game_web && $(FLUTTER) build web --release --no-pub --base-href /game/ --no-web-resources-cdn --csp
build-linux:
	cd apps/poker_client && $(FLUTTER) build linux --debug --no-pub
test: test-unit
	cd apps/poker_client && $(FLUTTER) test --no-pub integration_test/app_test.dart -d linux
export-web:
	$(UV) run --locked python tools/export_web.py apps/poker_game_web/build/web "$(ARTIFACT_OUTPUT)"
run:
	cd apps/poker_client && $(FLUTTER) run -d linux
