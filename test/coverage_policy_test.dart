import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory fixture;
  setUp(() {
    fixture = Directory.systemTemp.createTempSync('dart-coverage-policy-');
    File('tool/coverage_inventory.dart')
        .copySync('${fixture.path}/report.dart');
    for (final directory in [
      'lib',
      'tool',
      'packages/poker_http/lib',
      'packages/poker_contract/lib',
      'packages/poker_game/lib',
      'apps/poker_client/lib',
      'apps/poker_game_web/lib',
    ]) {
      Directory('${fixture.path}/$directory').createSync(recursive: true);
    }
    Directory('${fixture.path}/coverage').createSync();
    File('${fixture.path}/coverage/.started').writeAsStringSync('');
    for (final name in ['http', 'contract', 'game', 'native', 'tool']) {
      final report = File('${fixture.path}/coverage/$name/lcov.info');
      report.parent.createSync(recursive: true);
      report.writeAsStringSync(
        'SF:lib/example.dart\nDA:1,1\nDA:2,1\nDA:3,0\nend_of_record\n',
      );
    }
    File('${fixture.path}/lib/example.dart').writeAsStringSync('// fixture\n');
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  Future<ProcessResult> run() => Process.run(
    Platform.environment['DART'] ?? 'dart',
    ['report.dart'],
    workingDirectory: fixture.path,
  );

  test(
    'incomplete measured lines succeed and branches stay notMeasured',
    () async {
      final result = await run();
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('WARNING: Dart coverage advisory'));
      expect(result.stdout, contains('66.67%'));
      expect(result.stdout, contains('notMeasured'));
    },
  );

  test('missing or corrupt required LCOV fails', () async {
    final report = File('${fixture.path}/coverage/game/lcov.info');
    report.deleteSync();
    expect((await run()).exitCode, isNonZero);
    report.writeAsStringSync('broken');
    expect((await run()).exitCode, isNonZero);
  });

  test('stale required LCOV fails', () async {
    File('${fixture.path}/coverage/game/lcov.info')
        .setLastModifiedSync(DateTime.fromMillisecondsSinceEpoch(1000));
    expect((await run()).exitCode, isNonZero);
  });
}
