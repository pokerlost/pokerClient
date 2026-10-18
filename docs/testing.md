# Client testing and artifacts

Contract tests validate bounded values, phase mapping, private-card rejection and embed settings. Shared controller/widget tests exercise loading, unavailable, disconnect/error, reconnect, source replacement, cancellation, disposal and synthetic rendering. Native shell tests cover navigation and appearance/preview settings. The Linux integration test launches that same shell and module on a real target. The web browser acceptance belongs to pokerWeb and uses the actual exported release bundle.

Flutter LCOV reports executable line hits separately for contract, game and native shell. This pinned toolchain does not emit BRDA branch counters in these runs: branch coverage is `notMeasured`, not 100%. Native widget tests do not measure browser-only dart:js_interop code. Browser integration checks that lifecycle separately; no C++ or TypeScript percentage is inferred from Dart lines. Keep uncovered paths visible and the PR Draft while required acceptance remains incomplete.

Python pytest/coverage includes the original diagnostic package and artifact tooling, including unimported modules and subprocess entrypoints. Its strict 100% statement/branch gate is separate from Dart coverage. `make legacy-build` uses the locked build backend. Immutable manifest/checksum tests exercise real temporary Git commits and reject dirty source, symlinks, missing builds and recursive destinations.

Local Docker builds use isolated caches and standard Flutter/Node tooling; a cache hit never substitutes for fresh unit, browser or native integration runs. Android licenses/signing and Apple runners have separate acceptance status. See [toolchain](flutter-toolchain.md) and [bridge](web_flutter_integration.md).
