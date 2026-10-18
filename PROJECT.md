# pokerClient project

Dart and Flutter own the primary native client. The native shell and embedded-web entrypoint both depend on `packages/poker_game`; that package depends on pure Dart `poker_contract` presentation validation. GameController owns one source subscription, cancellation and presentation states. There is one simple ChangeNotifier state model, no mirrored game rules or ledger.

The public/player-view projection follows the actual engine reference fields, without adopting its unauthenticated TCP/NDJSON transport as a production protocol. Only an authorized player's cards may appear; opponent private cards and trusted server fields are rejected. Preview is explicit and synthetic. Production transport/auth remain unavailable until server contracts exist.

The Python status command is retained as a diagnostic compatibility tool. It is not used to render, authenticate or run the Flutter application. The engine reference Python examples remain in their owning repository.
