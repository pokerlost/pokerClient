# Contributing to pokerClient

Use the pinned native pub workspace and preserve the shared gameplay module. From this root, `make install lint typecheck coverage` checks Dart/Flutter and the typed artifact tool. `make test` adds a real Linux integration launch; `make build-web` creates the module used by pokerWeb. See [testing](docs/testing.md) and [toolchain](docs/flutter-toolchain.md) for target limitations.

Use `type/shortCamelCase` for new branches and `type(scope): intent` for PR titles. Production transport/auth require actual server contracts, not synthetic success. Preview must remain labelled. Add behavior tests at the matching boundary and verify source/artifact identity. Do not copy widgets or game state into TypeScript, compute authoritative rules in the client, or restore the removed Python scaffold.

Use the current branch and a focused PR with compatibility, actual language coverage, target/build results, version and recovery notes. No credentials, user data or signing keys belong in source or artifacts. Commit/push/release/deployment permissions come from the current task.
