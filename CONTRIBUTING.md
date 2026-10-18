# Contributing to pokerClient

Use the pinned native pub workspace and preserve the shared gameplay module. `make install lint typecheck test-unit` checks Dart, Flutter and the Python diagnostic/artifact tooling independently. `make test` adds a real Linux integration launch; `make build-web` creates the module used by pokerWeb. See [testing](docs/testing.md) and [toolchain](docs/flutter-toolchain.md) for target limitations.

Keep published Python command/import compatibility explicit. Production transport/auth require actual server contracts, not synthetic success. Preview must remain labelled. Add behavior tests at the matching boundary and verify source/artifact identity. Do not copy widgets or game state into TypeScript, and do not compute authoritative rules in the client.

Use the current work branch and a focused PR with compatibility, actual language-specific coverage, target/build results, version and recovery notes. No credentials, user data or signing keys belong in source or artifacts. Commit/push/release/deployment permissions come from the current task, not this document.
