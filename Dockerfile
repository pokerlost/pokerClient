# syntax=docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
FROM ubuntu:24.04@sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac AS sdk
ARG FLUTTER_REVISION
ARG FLUTTER_VERSION
ENV DEBIAN_FRONTEND=noninteractive CI=true FLUTTER_SUPPRESS_ANALYTICS=true \
    PATH="/opt/flutter/bin:$PATH" \
    XDG_CONFIG_HOME=/tmp/flutter-config ANALYZER_STATE_LOCATION_OVERRIDE=/tmp/analyzer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN test "${#FLUTTER_REVISION}" -eq 40 \
    && test -z "$(printf '%s' "$FLUTTER_REVISION" | tr -d '0-9a-f')" \
    && git init --quiet /opt/flutter \
    && git -C /opt/flutter remote add origin https://github.com/flutter/flutter.git \
    && git -C /opt/flutter fetch --depth=1 origin "refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION" \
    && git -C /opt/flutter checkout --detach "$FLUTTER_REVISION" \
    && test "$(git -C /opt/flutter rev-parse HEAD)" = "$FLUTTER_REVISION" \
    && flutter precache --linux --web

FROM sdk AS dependencies
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY packages/poker_contract/pubspec.yaml packages/poker_contract/pubspec.yaml
COPY packages/poker_game/pubspec.yaml packages/poker_game/pubspec.yaml
COPY apps/poker_client/pubspec.yaml apps/poker_client/pubspec.yaml
COPY apps/poker_game_web/pubspec.yaml apps/poker_game_web/pubspec.yaml
RUN --mount=type=cache,id=pokerclient-pub-3.47-linux-amd64,target=/root/.pub-cache,sharing=locked \
    flutter pub get --enforce-lockfile \
    && mkdir -p /opt/pub-cache && cp -a /root/.pub-cache/. /opt/pub-cache/
ENV PUB_CACHE=/opt/pub-cache
RUN flutter pub get --offline --enforce-lockfile
COPY packages/poker_contract/lib packages/poker_contract/lib
COPY packages/poker_game/lib packages/poker_game/lib

FROM dependencies AS web-build
COPY apps/poker_game_web/lib apps/poker_game_web/lib
COPY apps/poker_game_web/web apps/poker_game_web/web
COPY apps/poker_game_web/.metadata apps/poker_game_web/.metadata
WORKDIR /app/apps/poker_game_web
RUN --network=none flutter build web --release --no-pub --base-href /game/ --no-web-resources-cdn --csp

FROM scratch AS web-artifacts
COPY --from=web-build /app/apps/poker_game_web/build/web/ /

FROM dependencies AS native-build
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev xvfb lcov \
    && rm -rf /var/lib/apt/lists/*
COPY apps/poker_client/lib apps/poker_client/lib
COPY apps/poker_client/linux apps/poker_client/linux
COPY apps/poker_client/.metadata apps/poker_client/.metadata
WORKDIR /app/apps/poker_client
RUN --network=none flutter build linux --debug --no-pub

FROM scratch AS native-artifacts
COPY --from=native-build /app/apps/poker_client/build/linux/x64/debug/bundle/ /

FROM native-build AS native-test
COPY packages/poker_contract/test /app/packages/poker_contract/test
COPY packages/poker_game/test /app/packages/poker_game/test
COPY apps/poker_client/test /app/apps/poker_client/test
COPY apps/poker_client/integration_test /app/apps/poker_client/integration_test
# The dependency layer retains locked package bytes across fresh BuildKit workers.
CMD ["xvfb-run", "-a", "flutter", "test", "--no-pub", "integration_test/app_test.dart", "-d", "linux"]
