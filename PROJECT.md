# pokerClient project

Dart and Flutter own the web gameplay client. Web is the supported delivery; native source runners are retained and platform acceptance is deferred. The native shell and embedded-web entrypoint both depend on `packages/poker_game`; that package depends on pure Dart `poker_contract` presentation validation. GameController owns one source subscription, cancellation and presentation states. There is one simple ChangeNotifier state model, no mirrored game rules or ledger.

The public/player-view projection follows the actual engine reference fields, without adopting its unauthenticated TCP/NDJSON transport as a production protocol. Only an authorized player's cards may appear; opponent private cards and trusted server fields are rejected. Preview is explicit and synthetic. Production transport/auth remain unavailable until server contracts exist.

The client is a Dart/Flutter workspace with no Python package, CLI or template-update mechanism. Artifact export and verification use the small typed Dart tool in `tool/`; Make is a thin command interface. The engine reference Python examples remain in their owning repository.
