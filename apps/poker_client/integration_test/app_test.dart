import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:poker_client/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('launch native shell and shared table on a real target', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview with synthetic data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open preview table'));
    await tester.pumpAndSettle();
    expect(find.text('Preview · synthetic data'), findsOneWidget);
    expect(find.text('Ah'), findsOneWidget);
    await tester.tap(find.byTooltip('Return'));
    await tester.pumpAndSettle();
    expect(find.text('Open preview table'), findsOneWidget);
  });
}
