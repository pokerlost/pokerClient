# pokerClient

The Dart/Flutter workspace contains the native Android/iOS/Linux/macOS shell and the shared gameplay renderer embedded by pokerWeb. The table shows loading, disconnected, unavailable/error and an explicit synthetic preview. No production game or login adapter exists; the server owns rules, state and balances.

From this exact Git root, use the pinned [Flutter toolchain](docs/flutter-toolchain.md), then `make install lint typecheck coverage`. `make build-web` produces the embedded module; `make build-linux` builds the native shell. `make test` adds a real Linux integration launch. `make run` opens that app; select the labelled synthetic preview to view a table. `make build-android` produces unsigned arm64 debug output and requires an already licensed SDK. Apple targets require an approved macOS runner. No store release or signing keys are created.

`make export-web ARTIFACT_OUTPUT=/absolute/fresh/output` exports a clean-commit bundle and SHA256 manifest. pokerWeb pins this identity and consumes the same module used by the native shell. See [architecture](docs/architecture.md), [bridge](docs/web_flutter_integration.md), [testing commands](docs/testing.md) and [contributing](CONTRIBUTING.md).

The workspace needs Flutter/Dart, Git and Make; merged coverage additionally uses LCOV. Docker supplies Linux build dependencies when needed. One root `pubspec.lock` owns dependency resolution. The former Python CLI/import and wheel are removed on this PR branch; see the [0.3 migration](docs/versioning.md). No compatibility shim or scaffold restoration command remains.
