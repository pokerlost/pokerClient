# Client testing and web artifacts

The supported client delivery is web only. Contract, shared controller/widget, retained shell
widget and Dart artifact tests run on the Linux VM test engine in Docker. They do not build
or accept a Linux desktop application. Android/iOS/macOS/Linux desktop runners remain as
source and their platform build/device acceptance is deferred.

## Commands

| Command | Actual responsibility |
| --- | --- |
| `make help` | Offline read-only command list |
| `make install` | Cached exact Flutter SDK and locked pub workspace image |
| `make lint typecheck` | Dart format and Flutter analyze inside Docker |
| `make test` | Fresh HTTP/contract/game/shell-widget/tool suites once |
| `make coverage` | Existing LCOV and complete inventory; no test rerun |
| `make check` | Static checks and one fresh suite |
| `make build` | Release web bundle under `dist/docker-web` |
| `make export-web verify` | Clean full-SHA manifest, checksums and independent verification |
| `make image` | Local verified asset OCI candidate; no publication |

Git, Make and Docker are the standard contributor tools; host Flutter, Node, Python and LCOV
are not required. The pinned SDK is configured only inside disposable containers. VM/tool
tests use independent temporary Git roots and synthetic inputs. The artifact tool rejects
dirty/wrong roots, symlinks, malformed identities, wrong SDK versions and tampered inventories.

## Coverage evidence

LCOV reports measured executable lines for HTTP, contract, game, retained shell widgets and Dart
artifact code independently. `tool/coverage_inventory.dart` validates each required report
against the run-start marker and writes `coverage/dart/source-inventory.json` and
`coverage/summary.md`. Every owned library/tool/application Dart file is inventoried, including
uninstrumented browser interop and subprocess wrappers. This toolchain emits no BRDA counters:
Dart branches are `notMeasured`, never inferred from TypeScript or C++ coverage.

Below 100% produces an advisory warning and exit 0 when mandatory checks pass. Failed tests,
builds, analysis, empty/corrupt/missing/stale reports still fail. A previous success receipt
does not make a newly failed test run successful. Technical policy fixtures exercise incomplete
LCOV success and missing/corrupt/stale failures in real Dart subprocesses. JSON/LCOV reports and
the numeric table are retained by CI; coverage alone is not a reason to keep a PR Draft.

## Web acceptance and delivery

pokerWeb owns browser acceptance of the real release bundle under Nginx and the platform
gateway. It covers embedding, route/lifecycle, bridge validation, failures and browser errors.
Private package read access must pass in the actual consuming Actions job; a local artifact
copy cannot prove its package ACL. This repository's CI exports the exact successful head.
The separate owner-dispatched delivery workflow accepts only a successful same-repository CI
run for the reviewed full SHA, verifies downloaded assets with Dart, and publishes only the
previously approved private development OCI package. It never rebuilds Flutter at publication,
creates a release or deploys. Native platform and store delivery remain deferred.

Recovery uses the previous verified source commit plus its matching web artifact and consumer
pins. Preserve history and storage; remove only task-owned generated output after backing it up.
