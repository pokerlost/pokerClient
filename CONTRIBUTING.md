# Contributing to pokerClient

Use the pinned pub workspace and preserve the shared gameplay module. Git, Make and Docker
suffice from this exact root: `make check` runs formatting, analysis and all VM/widget/tool
tests once; `make coverage` reports that fresh result. `make build` exports release web files;
`make export-web verify` creates and checks a fresh exact-SHA bundle from a clean commit.
Coverage below 100% warns. Missing/stale reports, assertions, types and builds fail. Native
platform delivery is deferred and source runners are retained. See [testing](docs/testing.md)
and [toolchain](docs/flutter-toolchain.md).

Use `type/shortCamelCase` for new branches and `type(scope): intent` for PR titles. Production transport/auth require actual server contracts, not synthetic success. Preview must remain labelled. Add behavior tests at the matching boundary and verify source/artifact identity. Do not copy widgets or game state into TypeScript, compute authoritative rules in the client, or restore the removed Python scaffold.

Use the current branch and a focused PR with compatibility, actual language coverage, target/build results, version and recovery notes. No credentials, user data or signing keys belong in source or artifacts. Commit/push/release/deployment permissions come from the current task.
