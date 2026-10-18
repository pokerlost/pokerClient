library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poker_contract/poker_contract.dart';

export 'package:poker_contract/poker_contract.dart' show TableSnapshot;

enum GameStatus { loading, disconnected, unavailable, error, preview }

final class GameFrame {
  const GameFrame(this.status, [this.snapshot]);
  final GameStatus status;
  final TableSnapshot? snapshot;
}

abstract interface class GameSource {
  Stream<GameFrame> watch();
}

final class UnavailableSource implements GameSource {
  const UnavailableSource();
  @override
  Stream<GameFrame> watch() =>
      Stream.value(const GameFrame(GameStatus.unavailable));
}

/// Explicit synthetic public projection; never used by the production source.
final class PreviewSource implements GameSource {
  const PreviewSource();
  @override
  Stream<GameFrame> watch() => Stream.value(
    GameFrame(
      GameStatus.preview,
      TableSnapshot.parse({
        'version': 1,
        'phase': 'betting',
        'pot': 60,
        'board': ['Ah', '7c', '2d'],
        'players': [
          {'player_id': 'North', 'seat': 0, 'stack': 980, 'cards': null},
          {'player_id': 'South', 'seat': 1, 'stack': 960, 'cards': null},
        ],
      }),
    ),
  );
}

/// A subscription belongs to one screen. A replaced source cannot update it.
final class GameController extends ChangeNotifier {
  GameFrame frame = const GameFrame(GameStatus.loading);
  StreamSubscription<GameFrame>? _subscription;
  int _generation = 0;
  bool _disposed = false;

  Future<void> connect(GameSource source) async {
    if (_disposed) return;
    final generation = ++_generation;
    frame = const GameFrame(GameStatus.loading);
    notifyListeners();
    await _subscription?.cancel();
    if (_disposed || generation != _generation) return;
    _subscription = source.watch().listen(
      (value) {
        if (!_disposed && generation == _generation) {
          frame = value;
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!_disposed && generation == _generation) {
          frame = const GameFrame(GameStatus.error);
          notifyListeners();
        }
      },
      onDone: () {
        if (!_disposed &&
            generation == _generation &&
            frame.status == GameStatus.loading) {
          frame = const GameFrame(GameStatus.disconnected);
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.source, required this.onReturn});
  final GameSource source;
  final VoidCallback onReturn;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final controller = GameController();
  @override
  void initState() {
    super.initState();
    unawaited(controller.connect(widget.source));
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      unawaited(controller.connect(widget.source));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      final frame = controller.frame;
      final snapshot = frame.snapshot;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Poker table'),
          leading: IconButton(
            tooltip: 'Return',
            onPressed: widget.onReturn,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(switch (frame.status) {
                  GameStatus.loading => 'Loading table',
                  GameStatus.disconnected => 'Disconnected',
                  GameStatus.unavailable => 'Game service unavailable',
                  GameStatus.error => 'Unable to load table',
                  GameStatus.preview => 'Preview · synthetic data',
                }, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (snapshot != null) ...[
                  Text(
                    'Phase: ${snapshot.phase} · pot: ${snapshot.pot} preview chips',
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final card in snapshot.board)
                        Semantics(
                          label: 'Board card $card',
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                card,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  for (final player in snapshot.players)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(player.id),
                      subtitle: Text(
                        'Seat ${player.seat + 1} · ${player.stack} preview chips',
                      ),
                      trailing: Text(player.cards?.join(' ') ?? 'Hidden cards'),
                    ),
                ] else
                  const Text('No connected game or login API is configured.'),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => unawaited(controller.connect(widget.source)),
                  child: const Text('Reconnect'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
