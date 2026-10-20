# Client versions and 0.3 migration

The unreleased workspace, application, `poker_contract` and `poker_game` candidates are `0.3.0-dev.0`. A breaking change in a `0.y.z` client increments the minor version. The Dart API now exposes `TablePhase` and `BridgeTheme` instead of unbounded phase/theme strings. Read their explicit `wireValue` only at serialization/display boundaries; use enum variants in application code. `BridgeEventKind.returnToHost` still encodes exactly `return`. The browser bridge remains version 1 with unchanged fields and values. Native numeric build numbers, OCI digests and chart versions are separate identities. No tag or release is created by a source update.

The former `pokerClient status`, `python -m pokerclient`, import package and wheel/sdist are removed. Use the pokerWeb host and its explicit unavailable/preview states for the supported web delivery. There is no replacement diagnostic CLI because it offered no server connection. Use `make check`, `make coverage` and the Dart export/verify tool for development. No uv, pip or project Python environment is needed.

Copier answers, source lock, Python packaging/tooling and template recovery metadata are removed. Future client updates are reviewed Dart/Flutter changes. Engineering forms and naming checks are client-owned; there is no active parent-template synchronization or recovery command. Backend templates, the Python SDK and engine reference applications retain their separate owners and compatibility policies.

Each source or build input change requires fresh verification and a new full-commit artifact identity. pokerWeb and platformInfra must pin the new client commit, manifest and immutable image digest; an old artifact is never relabelled as new. Recover using an earlier verified commit and its matching artifact pins, without overwriting published history.

Only web delivery is currently accepted. Native source and version identities are retained; platform builds are deferred and do not block this phase. Coverage percentages are advisory.

## Local verification and release readiness

`make version` reads the native version owners. `make ci-local` executes the
repository's native quality/build/acceptance targets once, then checks artifact
versions. No GitHub token or Actions API is required. Dependency preparation may
need the existing package/image access; `OFFLINE=1` requires prepared inputs and
fails as blocked when they are unavailable. After an online pass on the same clean
source, offline build validates `coverage/web-build.json` against the complete raw
Flutter inventory and source identity; it does not invoke BuildKit. Export and
independent manifest verification still check the existing bundle, and VM/widget
suites run freshly without network. Changed source, missing inputs, extra files,
symlinks or modified bytes invalidate reuse. BuildKit caches online dependency and
build layers. `make coverage` reads the current result and
never reruns the suite. Coverage below 100% is advisory.

`coverage/ci-local.json` records schema 1, source commit/dirty/content SHA-256,
commands and exits, native tool versions, artifact hashes/versions and timestamps.
The declared check plan is recorded as `scope` and `plannedChecks`. Only `full`
PASS covers the complete native graph and required artifact inventory; explicit
`scoped` runs record their checks without claiming full artifact acceptance.
`coverage/ci-local-summary.md` and `coverage/checksums.sha256` are supporting reports;
`coverage/summary.md` remains the coverage report. Ignored build outputs remain in
`dist/`. A source or lock change invalidates previous evidence. A failed or blocked
run must not leave a successful current receipt. Local CI does not replace hosted
mandatory checks or authorize a merge when those checks are billing-blocked.

Choose a version bump from the actual compatibility effect, update its native
metadata/lock/chart relationship and changelog, and run local CI on the exact
reviewed source. Quality/documentation-only work keeps current prerelease versions.
A clean integrated `main` with successful mandatory checks can receive an annotated
`v<application-version>` tag (or `<package>/v<version>` for an independently
versioned pub member),
after inspecting tag-triggered workflows and confirming explicit task authority.
Tags, releases, package publication and deployment are separate operations; the
commands above do none of them. Never retag a published artifact or infer a registry
digest from a local Docker image ID.

`dart pub deps --json` owns workspace interpretation and reports every member's
native `pubspec.yaml` version. The web build's Flutter `version.json` must match
`poker_game_web`; the immutable bundle still uses bridge 1 and the existing manifest
format. Pub's lock is dependency state, not a package version. VM/widget suites
retain native JSON test reports alongside LCOV under `coverage/`; browser coverage
belongs to pokerWeb. No native platform build is claimed.

The exporter preserves an existing bundle, accepting it only after verifying the
same clean commit and identical freshly built file inventory. Other existing
bundles require a fresh destination. For repeated
local work select a fresh basename under this checkout's `dist/`, for example
`make ci-local GAME_BUNDLE="$PWD/dist/reviewed-candidate"`. The default remains
`dist/poker-game-web` for the existing delivery workflow.
