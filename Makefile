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
	$(DART) run tool/coverage_inventory.dart
build: build-web build-linux
build-web:
	cd apps/poker_game_web && $(FLUTTER) build web --release --no-pub --base-href /game/ --no-web-resources-cdn --csp
build-linux:
	cd apps/poker_client && $(FLUTTER) build linux --debug --no-pub
test: test-unit
	cd apps/poker_client && $(FLUTTER) test --no-pub integration_test/app_test.dart -d linux
export-web: build-web
	$(DART) run tool/web_artifact.dart export-web apps/poker_game_web/build/web "$(ARTIFACT_OUTPUT)" "$(FLUTTER)"
run:
	cd apps/poker_client && $(FLUTTER) run -d linux

# Source-owned toolchain lock is the only ref passed to the public SDK build.
FLUTTER_VERSION := $(shell $(DART) tool/toolchain.dart flutterVersion)
FLUTTER_REVISION := $(shell $(DART) tool/toolchain.dart frameworkRevision)
.PHONY: docker-artifacts docker-native-test
docker-artifacts:
	docker buildx build --build-arg FLUTTER_REVISION=$(FLUTTER_REVISION) --build-arg FLUTTER_VERSION=$(FLUTTER_VERSION) --target web-artifacts --output type=local,dest=dist/docker-web .
	docker buildx build --build-arg FLUTTER_REVISION=$(FLUTTER_REVISION) --build-arg FLUTTER_VERSION=$(FLUTTER_VERSION) --target native-artifacts --output type=local,dest=dist/linux .
docker-native-test:
	docker buildx build --build-arg FLUTTER_REVISION=$(FLUTTER_REVISION) --build-arg FLUTTER_VERSION=$(FLUTTER_VERSION) --target native-test --load --tag pokerclient:native-test .
	docker run --init --rm --network none pokerclient:native-test

.PHONY: build-android coverage
build-android:
	@test -n "$$ANDROID_HOME" && test -s "$$ANDROID_HOME/licenses/android-sdk-license"
	cd apps/poker_client && $(FLUTTER) build apk --debug --no-pub --target-platform android-arm64
coverage: test-unit
	mkdir -p coverage/dart
	lcov --add-tracefile coverage/contract/lcov.info --add-tracefile coverage/game/lcov.info --add-tracefile coverage/native/lcov.info --add-tracefile coverage/tool/lcov.info --output-file coverage/dart/lcov.info
	lcov --summary coverage/dart/lcov.info --fail-under-lines 100
