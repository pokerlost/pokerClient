# Reviewed client delivery

[Home](../README.md) · [Development](flutter-toolchain.md) · [Versions](versioning.md)

Review compatibility first: Pub APIs, the browser bridge, minimum Flutter/Dart
versions and the existing exported-manifest contract. Follow the native version
owners and 0.x policy in the version guide; dependency locks and Git commits are
separate identities. Update the changelog when behavior or compatibility changes.

Commit the reviewed source before artifact verification. From this exact root:

```bash
make version
make ci-local GAME_BUNDLE="$PWD/dist/review-$(git rev-parse --short=12 HEAD)"
```

Local CI runs format/analyzer, the VM/widget/tool suites, coverage, the Flutter web
build, immutable export, bundle verification and release identity checks. Inspect
`coverage/ci-local.json`: full scope, clean matching source, every planned check
passed and artifact hashes verified. Coverage below 100% warns. A missing check,
failed test, corrupt report or mismatched bundle blocks readiness. Preserve earlier
bundle directories; select a new destination after a source change.

Review the PR and require its hosted checks on the exact source. A billing-blocked
check keeps the PR and branch open. After a clean commit is integrated into `main`
and mandatory checks succeed, explicit task authority may permit its annotated
application or component tag under the version guide's naming rules. Inspect tag
workflow triggers first and verify the specific remote tag; never replace a tag.

Publication is a separate owner action through the existing manual reviewed web
artifact delivery workflow. It requires the exact reviewed SHA and its successful
CI run and promotes those verified assets to the existing approved private package.
Local CI and tags do not publish a bundle, create a GitHub Release or deploy it.
Consumers advance the client commit, manifest checksum and real immutable registry
digest together through review; a local image ID is not a registry digest.

Only web delivery is accepted. Native platform builds, signing and store release
remain deferred. Recover by selecting a prior verified source and matching bundle;
keep source refs, artifacts and the existing access unchanged.
