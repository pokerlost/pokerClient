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
    writeJson('coverage/ci-plan.json', {
      'scope': 'full',
      'checks': requiredChecks,
    });
    writeJson('coverage/ci-local.json', {
      'schemaVersion': 1,
      'source': source,
      'status': 'running',
      'scope': 'full',
      'plannedChecks': requiredChecks,
      'artifacts': <Object?>[],
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
  test('a successful prefix cannot stand for the full check graph', () async {
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '0',
    ]);
    await expectLater(
      receipt(['finish', '--status', 'passed']),
      throwsFormatException,
    );
    expect(readJson('coverage/ci-local.json')['status'], 'failed');
  });
  test(
    'all built artifacts are mandatory after a complete check graph',
    () async {
      for (final name in requiredChecks) {
        await receipt([
          'record',
          '--name',
          name,
          '--command',
          'make $name',
          '--exit-code',
          '0',
        ]);
      }
      await expectLater(
        receipt(['finish', '--status', 'passed']),
        throwsFormatException,
      );
    },
  );
  test(
    'duplicate checks and incomplete or invalid options are rejected',
    () async {
      await expectLater(
        receipt(['record', '--name', 'check', '--command', 'make check']),
        throwsFormatException,
      );
      await receipt([
        'record',
        '--name',
        'check',
        '--command',
        'make check',
        '--exit-code',
        '0',
      ]);
      await expectLater(
        receipt([
          'record',
          '--name',
          'check',
          '--command',
          'make check',
          '--exit-code',
          '0',
        ]),
        throwsFormatException,
      );
      await expectLater(
        receipt(['finish', '--status', 'success']),
        throwsFormatException,
      );
    },
  );
  test('finished and malformed receipts reject further writes', () async {
    await receipt(['finish', '--status', 'failed']);
    await expectLater(
      receipt([
        'record',
        '--name',
        'check',
        '--command',
        'make check',
        '--exit-code',
        '0',
      ]),
      throwsFormatException,
    );
    writeJson('coverage/ci-local.json', {
      'schemaVersion': 1,
      'status': 'running',
      'source': <String, Object?>{},
    });
    await expectLater(
      receipt(['finish', '--status', 'passed']),
      throwsFormatException,
    );
  });
  test('exit code 3 remains blocked and cannot produce PASS', () async {
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '3',
    ]);
    await expectLater(
      receipt(['finish', '--status', 'passed']),
      throwsFormatException,
    );
    expect(readJson('coverage/ci-local.json')['status'], 'blocked');
  });
  test('a scoped plan never claims full artifact acceptance', () async {
    writeJson('coverage/ci-plan.json', {
      'scope': 'scoped',
      'checks': ['check'],
    });
    final report = readJson('coverage/ci-local.json');
    report['scope'] = 'scoped';
    report['plannedChecks'] = ['check'];
    writeJson('coverage/ci-local.json', report);
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '0',
    ]);
    await receipt(['finish', '--status', 'passed']);
    expect(readJson('coverage/ci-local.json'), containsPair('scope', 'scoped'));
    expect(readJson('coverage/ci-local.json')['artifacts'], isEmpty);
  });
  test('source corruption is failed even when execution was blocked', () async {
    await receipt([
      'record',
      '--name',
      'check',
      '--command',
      'make check',
      '--exit-code',
      '3',
    ]);
    writeJson('coverage/source.json', {...source, 'dirty': true});
    await expectLater(
      receipt(['finish', '--status', 'blocked']),
      throwsFormatException,
    );
    expect(readJson('coverage/ci-local.json')['status'], 'failed');
  });
}
