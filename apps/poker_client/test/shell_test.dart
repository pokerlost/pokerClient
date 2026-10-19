import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/main.dart' as app;

void main() {
  testWidgets('native navigation, settings, unavailable and explicit preview', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open table'));
    await tester.pumpAndSettle();
    expect(find.text('Game service unavailable'), findsOneWidget);
    await tester.tap(find.byTooltip('Return'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview with synthetic data'));
    await tester.tap(find.text('Dark appearance'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Pokerlost'))).brightness,
      Brightness.light,
    );
    await tester.tap(find.text('Open preview table'));
    await tester.pumpAndSettle();
    expect(find.text('Preview · synthetic data'), findsOneWidget);
    expect(find.text('North'), findsOneWidget);
    await tester.tap(find.byTooltip('Return'));
    await tester.pumpAndSettle();
    expect(find.text('Open preview table'), findsOneWidget);
  });
}
