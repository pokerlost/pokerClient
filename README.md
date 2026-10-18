# pokerClient

The Dart/Flutter workspace contains the native Android/iOS/Linux/macOS shell and the shared gameplay renderer embedded by pokerWeb. The table shows loading, disconnected, unavailable/error and an explicit synthetic preview. No production game or login adapter exists; the server owns rules, state and balances.

Use the pinned [Flutter toolchain](docs/flutter-toolchain.md), then `make install lint typecheck test-unit`. `make build-web` produces the embedded module; `make build-linux` builds the native shell. `make test` adds a real Linux integration launch. Android debug output is unsigned and requires an already licensed SDK. Apple source targets require an approved macOS runner. No store release or signing keys are created.

`make export-web ARTIFACT_OUTPUT=/absolute/fresh/output` exports a clean-commit bundle and SHA256 manifest. pokerWeb pins this identity and consumes the same module used by the native shell. See [architecture](docs/architecture.md), [bridge](docs/web_flutter_integration.md), [testing](docs/testing.md) and [contributing](CONTRIBUTING.md).

## Python compatibility command

The original compact diagnostic package and its history remain. `uv sync --locked` and `uv run --locked pokerClient status` keep the published command/import contract. It reports unavailable transport/login, opens no connection and reads no credentials. It is not the UI foundation. `make legacy-test legacy-build` checks and builds it independently; the Python candidate version is independent from Flutter app/package/bridge versions.
