import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client_workspace/src/project_metadata.dart';

void main() {
  late Directory original;
  late Directory temporary;
  const source = {
    'commit': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    'dirty': false,
    'contentSha256':
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  };
  setUp(() {
    original = Directory.current;
    temporary = Directory.systemTemp.createTempSync('client-ci-receipt-');
    Directory.current = temporary;
    Directory('coverage').createSync();
    writeJson('coverage/source.json', source);
    writeJson('coverage/ci-local.json', {
      'schemaVersion': 1,
      'source': source,
      'status': 'running',
      'checks': <Object?>[],
      'versions': {'poker_game_web': '0.3.0-dev.0'},
    });
  });
  tearDown(() {
    Directory.current = original;
    temporary.deleteSync(recursive: true);
  });
  test('a failed native check cannot become a successful receipt', () async {
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '1',
    ]);
    await expectLater(
      receipt(['finish', '--status', 'passed']),
      throwsFormatException,
    );
    expect(readJson('coverage/ci-local.json')['status'], 'failed');
  });
  test('source changes invalidate receipt completion', () async {
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '0',
    ]);
    writeJson('coverage/source.json', {...source, 'dirty': true});
    await expectLater(
      receipt(['finish', '--status', 'passed']),
      throwsFormatException,
    );
    expect(
      jsonDecode(File('coverage/ci-local.json').readAsStringSync()),
      containsPair('status', 'failed'),
    );
  });
}
