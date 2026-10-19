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

## Dart style and resource ownership

The root analyzer config owns strict casts/inference/raw types and the official
`lints` 6.1.0 recommended set. Flutter apps and poker_game add `flutter_lints` 6.0.0
through native ordered includes; poker_contract remains a pure Dart boundary.
One pub workspace lock owns both versions. `dart format` is the only Dart formatter;
there is no conflicting quote rule, Prettier pass or editor requirement.

Use lower_snake_case paths/packages, lowerCamelCase values/functions and UpperCamelCase
types. Choose final/const and null safety deliberately. Widgets render, controllers
own presentation state, and transport boundaries validate external data. Side effects
belong to lifecycle/composition, never build(). Close controllers, subscriptions,
timers and listeners, and check mounted context after await. Wire enums have explicit
codecs; unknown values fail. Flutter owns one poker_game UI for web and retained native
adapters. Follow the [common frontend architecture/documentation checks](https://github.com/pokerlost/pokerWeb/blob/main/docs/development.md)
without importing JavaScript quote/backtick conventions into Dart.
