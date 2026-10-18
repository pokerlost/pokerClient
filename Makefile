# Read the source lock without requiring a host Dart/Flutter installation.
FLUTTER_VERSION := $(shell sed -n 's/.*"flutterVersion": "\([^"]*\)".*/\1/p' toolchain.lock.json)
FLUTTER_REVISION := $(shell sed -n 's/.*"frameworkRevision": "\([^"]*\)".*/\1/p' toolchain.lock.json)
FLUTTER_BUILD_ARGS := --build-arg FLUTTER_REVISION=$(FLUTTER_REVISION) --build-arg FLUTTER_VERSION=$(FLUTTER_VERSION)
override DOCKER_BUILD_ARGS += $(FLUTTER_BUILD_ARGS)
override QUALITY_BUILD_ARGS += $(FLUTTER_BUILD_ARGS)
ifneq ($(CONTAINERIZED),1)
QUALITY_DOCKERFILE := Dockerfile
QUALITY_IMAGE := pokerclient:quality
QUALITY_EXTRA_TARGETS :=
GAME_BUNDLE ?= $(CURDIR)/dist/poker-game-web
CLIENT_SHA = $(shell git rev-parse HEAD)
IMAGE_COMMAND = $(DOCKER) buildx build --file Dockerfile.web-artifact --build-arg CLIENT_COMMIT=$(CLIENT_SHA) --load --tag poker-game-web:candidate dist/poker-game-web
VERIFY_COMMAND = $(DOCKER) run --rm --init --network none --user "$$(id -u):$$(id -g)" --entrypoint /opt/flutter/bin/cache/dart-sdk/bin/dart --mount "type=bind,source=$(GAME_BUNDLE),target=/bundle,readonly" $(QUALITY_IMAGE) --packages=/app/.dart_tool/package_config.json /app/tool/web_artifact.dart verify /bundle $(CLIENT_SHA)
BUILD_COMMAND = $(DOCKER) buildx build $(DOCKER_BUILD_ARGS) --target web-artifacts --output type=local,dest=dist/docker-web .
COVERAGE_COMMAND := dart tool/coverage_inventory.dart
QUALITY_RUN = $(DOCKER) run --init --rm --network none --tmpfs /tmp:rw,exec,mode=1777,size=3g --user "$$(id -u):$$(id -g)" --mount "type=bind,source=$(CURDIR)/coverage,target=/app/coverage" --env GITHUB_ACTIONS --env CONTAINERIZED=1 $(QUALITY_IMAGE)
include docker/quality.mk
.PHONY: toolchain build-web docker-artifacts
toolchain:
	@printf '%s\n' 'FLUTTER_VERSION=$(FLUTTER_VERSION)' 'FLUTTER_REVISION=$(FLUTTER_REVISION)'

build-web docker-artifacts: build
.PHONY: export-web
export-web: build quality-image
	@mkdir -p dist
	$(DOCKER) run --init --rm --network none --user "$$(id -u):$$(id -g)" --entrypoint /bin/sh --workdir /source --mount "type=bind,source=$(CURDIR),target=/source,readonly" --mount "type=bind,source=$(CURDIR)/dist,target=/output" --env GIT_OPTIONAL_LOCKS=0 $(QUALITY_IMAGE) -ec 'export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=/opt/flutter GIT_CONFIG_KEY_1=safe.directory GIT_CONFIG_VALUE_1=/source; exec dart --packages=/app/.dart_tool/package_config.json /app/tool/web_artifact.dart export-web /output/docker-web /output/poker-game-web flutter'
image: export-web
verify: quality-image
else
.DEFAULT_GOAL := help
FLUTTER ?= flutter
DART ?= dart
export CI ?= true
export FLUTTER_SUPPRESS_ANALYTICS := true
export XDG_CONFIG_HOME ?= $(CURDIR)/.local/config
export ANALYZER_STATE_LOCATION_OVERRIDE ?= $(CURDIR)/.local/analyzer

.PHONY: help install lint typecheck test-unit test build build-web build-linux export-web run
help:
	@echo "install lint typecheck test-unit test build export-web run"
install:
	$(FLUTTER) pub get --enforce-lockfile
lint:
	$(DART) format --output=none --set-exit-if-changed lib tool test packages apps/poker_client/lib apps/poker_client/test apps/poker_client/integration_test apps/poker_game_web/lib
typecheck:
	$(FLUTTER) analyze --no-pub
test-unit:
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/contract/lcov.info packages/poker_contract/test
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/game/lcov.info packages/poker_game/test
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/native/lcov.info apps/poker_client/test
	$(FLUTTER) test --no-pub --coverage --coverage-path coverage/tool/lcov.info test
build: build-web
build-web:
	cd apps/poker_game_web && $(FLUTTER) build web --release --no-pub --base-href /game/ --no-web-resources-cdn --csp
build-linux:
	@echo "Linux desktop delivery is deferred; sources are retained." >&2
	@exit 2
test: test-unit
export-web: build-web
	$(DART) run tool/web_artifact.dart export-web apps/poker_game_web/build/web "$(ARTIFACT_OUTPUT)" "$(FLUTTER)"
run:
	cd apps/poker_game_web && $(FLUTTER) run -d web-server --web-hostname 0.0.0.0


check: lint typecheck test

endif
