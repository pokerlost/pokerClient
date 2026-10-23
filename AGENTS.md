# pokerClient

Read selected [baseRules](https://raw.githubusercontent.com/serrja/baseRules/bafcb63ed94b9769a0ca098e5db4b33c55dbc1b9/docs/engineering.md), then [Pokerlost norms](https://raw.githubusercontent.com/pokerlost/projectRules/904c65a3daab88802fb5e414cdaccc7ad2b555a8/docs/project.md) before the local contract below.
These full-SHA links are reading sources, not automatic loaders or grants. Review
the source diff, update the explicit pin and run docs checks for a rules refresh.
Local overrides apply only to this repository's stated ownership boundary.

This project owns its implementation and public behavior. Read `PROJECT.md` before changing contracts. Preserve user changes and secrets. Follow Dart naming and formatting. Run README commands and add focused regression tests. Repository instructions do not grant commit, publish or deployment permissions.

Dart/Flutter own the client; one native pub workspace contains the native shell and shared web module. Keep `poker_contract` pure Dart, presentation separate from subscriptions and native/web on the same widgets. This repository has no Python runtime, tooling or template-update dependency. Read the toolchain, architecture, testing and versioning pages before platform/build changes. Do not accept Android licenses, generate signing keys or claim Apple execution from Linux.

Daily work uses `dev` and lint only. `main` and `test` stay unchanged until an
explicit promotion. Full acceptance, template render/update checks, builds and
releases are manual; a dev snapshot is not a verified release.
