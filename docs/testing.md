# Client testing and artifacts

Contract tests validate bounded values, phase mapping, private-card rejection and embed settings. Shared controller/widget tests exercise loading, unavailable, disconnect/error, reconnect, source replacement, cancellation, disposal and synthetic rendering. Native shell tests cover navigation and appearance/preview settings. The Linux integration test launches that same shell and module on a real target. The web browser acceptance belongs to pokerWeb and uses the actual exported release bundle.

Flutter LCOV reports executable line hits separately for contract, game and native shell. This pinned toolchain does not emit BRDA branch counters in these runs: branch coverage is `notMeasured`, not 100%. Native widget tests do not measure browser-only dart:js_interop code. Browser integration checks that lifecycle separately; no C++ or TypeScript percentage is inferred from Dart lines. Keep uncovered paths visible and the PR Draft while required acceptance remains incomplete.

`make test-unit` runs contract, shared gameplay, native widget and Dart artifact tests, then writes `coverage/dart/source-inventory.json`. This lists every owned Dart source under application/package libraries and `lib/`/`tool/`, including files not instrumented by native LCOV. `make coverage` merges measured LCOV and enforces its existing 100% line gate. This is not whole-source or branch coverage: browser interop and subprocess command wrappers are separately identified. Before this migration, 186/186 measured application lines excluded browser interop; the deleted Python report is not added to Dart totals.

The Dart exporter tests preserve deterministic manifests, all checksums, dirty/exact Git-root rejection, actual SDK identity, symlink/path/inventory checks and tamper detection. Tests use disposable explicitly initialized Git roots and public synthetic fixtures. Removed CLI and wheel tests have no current client contract to test.

Run these commands from the client root with the pinned SDK on PATH:

| Command | Checks or output |
| --- | --- |
| `make install` | One locked pub workspace; no sibling template or project environment |
| `make lint typecheck` | Dart formatting and Flutter analysis |
| `make coverage` | Unit/widget/tool tests, LCOV and full source inventory |
| `make test` | Unit tests then a real Linux integration launch; use Xvfb on a headless host |
| `make build-web build-linux` | Embedded release bundle and native debug build |
| `make docker-artifacts docker-native-test` | Isolated compilation and a fresh Xvfb integration process |
| `make build-android` | Unsigned arm64 APK; existing SDK license required |
| `make export-web ARTIFACT_OUTPUT=/absolute/fresh/output` | Build and export a clean-commit artifact |
| `dart run tool/web_artifact.dart verify /absolute/bundle FULL_CLIENT_SHA` | Verify identity and complete file inventory |
| `make run` | Native preview; select synthetic preview explicitly |

For Vue browser acceptance, export the clean bundle, update its manifest/source pin in pokerWeb, then use its documented build/browser commands with `GAME_ARTIFACT=/absolute/bundle`. Its production image tests use actual Flutter and distinct scenarios; they do not supply Dart branch counters. Private package ACL and Apple acceptance remain separate gates.

Local Docker builds use isolated caches and standard Flutter/Node tooling; a cache hit never substitutes for fresh unit, browser or native integration runs. Android licenses/signing and Apple runners have separate acceptance status. See [toolchain](flutter-toolchain.md) and [bridge](web_flutter_integration.md).
