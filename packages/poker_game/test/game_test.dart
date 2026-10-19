import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_game/poker_game.dart';

final class ControlledSource implements GameSource {
  final stream = StreamController<GameFrame>();
  @override
  Stream<GameFrame> watch() => stream.stream;
  Future<void> close() => stream.close();
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('production has an honest unavailable state', () async {
    final controller = GameController();
    await controller.connect(const UnavailableSource());
    await flush();
    expect(controller.frame.status, GameStatus.unavailable);
    controller.dispose();
    await controller.connect(const PreviewSource());
    expect(controller.frame.status, GameStatus.unavailable);
  });
  test(
    'preview source is public, synthetic and has no opponent cards',
    () async {
      final frame = await const PreviewSource().watch().single;
      expect(frame.status, GameStatus.preview);
      expect(frame.snapshot!.players.every((p) => p.cards == null), isTrue);
      expect(frame.snapshot!.board, ['Ah', '7c', '2d']);
    },
  );
  test(
    'errors, empty connection and reconnection preserve lifecycle',
    () async {
      final source = ControlledSource();
      final controller = GameController();
      await controller.connect(source);
      source.stream.addError(StateError('synthetic private detail'));
      await flush();
      expect(controller.frame.status, GameStatus.error);
      await source.close();
      final empty = ControlledSource();
      await controller.connect(empty);
      await empty.close();
      await flush();
      expect(controller.frame.status, GameStatus.disconnected);
      await controller.connect(const PreviewSource());
      await flush();
      expect(controller.frame.status, GameStatus.preview);
      controller.dispose();
    },
  );
  test('cancellation prevents old updates and releases listeners', () async {
    final old = ControlledSource();
    final controller = GameController();
    await controller.connect(old);
    expect(old.stream.hasListener, isTrue);
    final first = controller.connect(const PreviewSource());
    final second = controller.connect(const UnavailableSource());
    await Future.wait([first, second]);
    old.stream.add(const GameFrame(GameStatus.error));
    await flush();
    expect(controller.frame.status, GameStatus.unavailable);
    expect(old.stream.hasListener, isFalse);
    controller.dispose();
    await old.close();
  });
  test(
    'dispose during subscription cancellation prevents a new connection',
    () async {
      final source = ControlledSource();
      final gate = Completer<void>();
      source.stream.onCancel = () => gate.future;
      final controller = GameController();
      await controller.connect(source);
      final pending = controller.connect(const PreviewSource());
      controller.dispose();
      gate.complete();
      await pending;
      expect(controller.frame.status, GameStatus.loading);
      await source.close();
    },
  );
  testWidgets(
    'the shared table displays preview, private redaction and return',
    (tester) async {
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            source: const PreviewSource(),
            onReturn: () => returned = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Preview · synthetic data'), findsOneWidget);
      expect(find.text('Ah'), findsOneWidget);
      expect(find.text('Hidden cards'), findsNWidgets(2));
      await tester.runAsync(() async {
        await tester.tap(find.text('Reconnect'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.text('North'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join('|'),
      );
      await tester.tap(find.byTooltip('Return'));
      expect(returned, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'source updates show actual unavailable/error/disconnected states',
    (tester) async {
      final source = ControlledSource();
      final key = GlobalKey();
      Widget screen(GameSource source) => MaterialApp(
        home: GameScreen(key: key, source: source, onReturn: () {}),
      );
      await tester.pumpWidget(screen(source));
      expect(find.text('Loading table'), findsOneWidget);
      source.stream.add(const GameFrame(GameStatus.disconnected));
      await tester.pump();
      expect(find.text('Disconnected'), findsOneWidget);
      source.stream.addError(Exception('private detail'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Unable to load table'), findsOneWidget);
      expect(find.textContaining('private detail'), findsNothing);
      await tester.pumpWidget(screen(const UnavailableSource()));
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(
        find.text('Game service unavailable'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join('|'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.close);
    },
  );
}
