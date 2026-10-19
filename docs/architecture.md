# Client architecture

The retained native `apps/poker_client` shell owns navigation and local appearance/preview settings. `apps/poker_game_web` is a thin official multi-view entrypoint. Both render `packages/poker_game`; Vue owns the surrounding website. `poker_contract` validates presentation DTOs and the versioned embed context in pure Dart.

The implementation follows Flutter's view/view-model/data separation: GameScreen renders, GameController presents a source stream through ChangeNotifier and owns its cancellation, and a GameSource is the data boundary. Only an explicit PreviewSource produces synthetic snapshots. UnavailableSource reports the missing production contract. There is no production gameplay network connection, credential storage or client authority to mutate a game.

The projection is derived from the checked engine public/player views, not server_view. It intentionally carries only the display subset; it is not a new realtime wire protocol. References: [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide), [embedding lifecycle](web_flutter_integration.md), [testing](testing.md).

Web is the supported delivery. Android/iOS/macOS/Linux desktop platform checks are deferred; their source runners remain.

## Explicit HTTP adapter

The pure Dart poker_http package uses package:http 1.6.0 on web/native. Its exact typed ServiceId snapshot comes from SDK main c4d8327e8318eab6769b3f05c4a7d848c75afb0b; update it only after owner enum review. Calls use one operation path, x-pokerlost-serviceId and the existing payload/response envelopes. Bearer authentication is explicit and separate. The owner closes the adapter; standard AbortableRequest handles cancellation/timeout. No automatic retries or arbitrary caller headers are exposed. Browser cookie behavior follows package:http; backend authentication remains explicit Bearer. This capability does not make the existing unavailable GameSource a multiplayer transport. Browser WebSocket constructors cannot set this custom HTTP header; production realtime remains unimplemented.
