# Client architecture

The retained native `apps/poker_client` shell owns navigation and local appearance/preview settings. `apps/poker_game_web` is a thin official multi-view entrypoint. Both render `packages/poker_game`; Vue owns the surrounding website. `poker_contract` validates presentation DTOs and the versioned embed context in pure Dart.

The implementation follows Flutter's view/view-model/data separation: GameScreen renders, GameController presents a source stream through ChangeNotifier and owns its cancellation, and a GameSource is the data boundary. Only an explicit PreviewSource produces synthetic snapshots. UnavailableSource reports the missing production contract. There is no network connection, credential storage or client authority to mutate a game.

The projection is derived from the checked engine public/player views, not server_view. It intentionally carries only the display subset; it is not a new realtime wire protocol. References: [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide), [embedding lifecycle](web_flutter_integration.md), [testing](testing.md).

Web is the supported delivery. Android/iOS/macOS/Linux desktop platform checks are deferred; their source runners remain.
