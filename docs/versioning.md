# Client versions and 0.3 migration

The unreleased native and web application candidate is `0.3.0-dev.0`. A breaking change in a `0.y.z` client increments the minor version. The workspace and two application pubspecs carry this candidate identity; the compatible `poker_contract` and `poker_game` packages retain `0.2.0-dev.0`, and the unchanged browser bridge remains version 1. Native numeric build numbers, OCI digests and chart versions are separate identities. No tag or release is created by a source update.

The former `pokerClient status`, `python -m pokerclient`, import package and wheel/sdist are removed. Use `make run` for the native application and its explicit unavailable/preview states. There is no replacement diagnostic CLI because it offered no server connection. Use `make install`, `make coverage` and the Dart export/verify tool for development. No uv, pip or project Python environment is needed.

Copier answers, source lock, Python packaging/tooling and template recovery metadata are removed. Future client updates are reviewed Dart/Flutter changes. Engineering forms and naming checks are client-owned; there is no active parent-template synchronization or recovery command. Backend templates, the Python SDK and engine reference applications retain their separate owners and compatibility policies.

Each source or build input change requires fresh verification and a new full-commit artifact identity. pokerWeb and platformInfra must pin the new client commit, manifest and immutable image digest; an old artifact is never relabelled as new. Recover using an earlier verified commit and its matching artifact pins, without overwriting published history.
