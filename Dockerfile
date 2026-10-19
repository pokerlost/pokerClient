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
    && flutter precache --web

RUN cp -a /root/.pub-cache /opt/flutter-tool-pub-cache \
    && PUB_CACHE=/opt/flutter-tool-pub-cache dart pub --directory /opt/flutter/packages/flutter_tools get --offline

FROM sdk AS dependencies
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY packages/poker_http/pubspec.yaml packages/poker_http/pubspec.yaml
COPY packages/poker_contract/pubspec.yaml packages/poker_contract/pubspec.yaml
COPY packages/poker_game/pubspec.yaml packages/poker_game/pubspec.yaml
COPY apps/poker_client/pubspec.yaml apps/poker_client/pubspec.yaml
COPY apps/poker_game_web/pubspec.yaml apps/poker_game_web/pubspec.yaml
RUN --mount=type=cache,id=pokerclient-pub-3.47-linux-amd64,target=/root/.pub-cache,sharing=locked \
    flutter pub get --enforce-lockfile \
    && mkdir -p /opt/pub-cache && cp -a /root/.pub-cache/. /opt/pub-cache/
COPY --chmod=0444 LICENSE THIRD_PARTY_NOTICES.md /licenses/
COPY --chmod=u=rwX,go=rX LICENSES/ /licenses/third-party/
COPY --chmod=0444 packages/poker_http/LICENSE packages/poker_http/LICENSE
COPY --chmod=0444 packages/poker_contract/LICENSE packages/poker_contract/LICENSE
COPY --chmod=0444 packages/poker_game/LICENSE packages/poker_game/LICENSE
COPY --chmod=0444 apps/poker_client/LICENSE apps/poker_client/LICENSE
COPY --chmod=0444 apps/poker_game_web/LICENSE apps/poker_game_web/LICENSE
ENV PUB_CACHE=/opt/pub-cache
RUN flutter pub get --offline --enforce-lockfile
COPY packages/poker_http/lib packages/poker_http/lib
COPY packages/poker_contract/lib packages/poker_contract/lib
COPY packages/poker_game/lib packages/poker_game/lib

FROM dependencies AS web-build
COPY apps/poker_game_web/lib apps/poker_game_web/lib
COPY apps/poker_game_web/web apps/poker_game_web/web
COPY apps/poker_game_web/.metadata apps/poker_game_web/.metadata
WORKDIR /app/apps/poker_game_web
RUN --network=none flutter build web --release --no-pub --base-href /game/ --no-web-resources-cdn --csp

COPY --from=dependencies /licenses/ /app/apps/poker_game_web/build/web/licenses/

FROM scratch AS web-artifacts
COPY --from=web-build /app/apps/poker_game_web/build/web/ /

FROM dependencies AS quality
RUN apt-get update && apt-get install -y --no-install-recommends make && rm -rf /var/lib/apt/lists/*
COPY --chmod=u=rwX,go=rX . ./
RUN flutter pub get --offline --enforce-lockfile && chmod -R a+rwX /opt/flutter/bin/cache
ENV CONTAINERIZED=1
ENTRYPOINT ["/bin/sh", "/app/docker/quality-entrypoint.sh"]
CMD ["make", "check"]
