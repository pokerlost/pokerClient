# Flutter toolchain

Flutter 3.47.0 at `4cf24164269a5ebf0c16a028a00727d0e77bbb05` and bundled Dart 3.13.0
are pinned by `toolchain.lock.json`. One pub workspace and root `pubspec.lock` own dependencies.
The Docker SDK stage fetches the exact public tag, verifies the full commit and precaches web.
It preserves SDK tool-package cache bytes in a readable container path; application pub cache
and source layers remain separate. Main commands need only Git, Make and Docker on the host.

`Dockerfile` separates SDK, pub metadata/locks, VM quality checks and release web artifacts.
Source, test and documentation changes reuse dependency layers. Fresh test commands run after
cache restoration; cached RUN steps are not test evidence. Client tests use a private writable
scratch copy inside each disposable unprivileged container because Flutter maintains SDK/tool
state. The source checkout is never writable through a test mount. Outputs use a separate bind
directory owned by the caller. No host HOME, credentials or Docker socket is mounted.

Only web delivery is active. Android/iOS/macOS/Linux desktop source adapters are retained;
platform builds, devices, desktop launch and signing/store acceptance are deferred and absent
from required CI. No platform license, runner quota or signing key is requested for this phase.

The private `poker-game-web` package remains linked to pokerClient. pokerWeb additionally needs
Read under Manage Actions access. Publication requires a successful CI run, exact full reviewed
SHA and owner manual dispatch; it is a development artifact, never a release or deployment.
See [tests](testing.md) and the [browser integration contract](web_flutter_integration.md).
