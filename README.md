# pokerClient

The supported delivery is Flutter Web embedded by the Vue/TypeScript pokerWeb site. One
`packages/poker_game` module renders gameplay; `poker_contract` owns pure Dart presentation
validation. Loading, disconnected, unavailable/error and explicit synthetic preview states
are implemented. Production transport and login remain unavailable pending server contracts.

From this exact Git root, Git, Make and Docker suffice:

```bash
make help
make check
make coverage
make build
make export-web verify
```

`check` runs Dart formatting, analysis and all VM/widget/tool tests in a fresh container.
`coverage` reports that result without rerunning tests; percentages warn, while missing/stale
reports and real test/build/type errors fail. `build` exports `dist/docker-web`; `export-web`
requires a clean committed source and a fresh `dist/poker-game-web` destination, records the
full SHA, toolchain and every file checksum, and `verify` checks that bundle.

Android, iOS, macOS and Linux desktop builds/acceptance are deferred. Their source runners and
shared widget tests remain; they are not required CI gates. There is no Python client, CLI,
wheel, tooling or scaffold restoration dependency. See [architecture](docs/architecture.md),
[toolchain](docs/flutter-toolchain.md), [testing](docs/testing.md),
[bridge](docs/web_flutter_integration.md), [versions](docs/versioning.md) and
[contributing](CONTRIBUTING.md).

## 📄 License

Original source/documentation uses [MIT](LICENSE). Preserve the
[third-party notices](THIRD_PARTY_NOTICES.md); upstream assets, distributions and
private data retain their own terms and access boundaries.
