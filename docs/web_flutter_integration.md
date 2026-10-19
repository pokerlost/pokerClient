# Web Flutter integration

The web entrypoint uses Flutter 3.47.0's official `runWidget`, ViewCollection and `ui_web.views` with JavaScript `addView` / `removeView`. The Vue host creates one lazy engine promise and at most one active view, passes initialData, then removes the view on route exit. There is no invented engine-destroy API.

Version 1 context contains exactly version, instance, theme, locale and preview. The supported locale is currently English. Updates and events are validated at runtime in both languages; late instance/view messages are ignored. Context travels as a direct same-origin CustomEvent on the specific host element, never wildcard postMessage. It contains no tokens, credentials, financial authority or per-frame game-state bus. Same-origin JavaScript is not isolated by this bridge.

The exporter requires a clean client Git revision and includes commit, pinned Flutter/Dart versions, bridge version and every asset checksum. The website pins its manifest SHA256 and commit. A Flutter/game change requires a new bundle identity and browser compatibility checks. Vue-only changes reuse the pinned bundle. Source maps and credentials are not a secret-distribution mechanism; no credential is compiled here.

See the [official embedding guide](https://docs.flutter.dev/platform-integration/web/embedding-flutter-web), [architecture](architecture.md) and [testing](testing.md).
