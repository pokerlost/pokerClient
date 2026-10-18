import 'package:flutter_test/flutter_test.dart';
import 'package:poker_contract/poker_contract.dart';

Map<String, Object?> snapshot() => {
  'version': 1,
  'phase': 'betting',
  'pot': 40,
  'board': ['Ah', 'Kd', '2c'],
  'players': [
    {
      'player_id': 'self',
      'seat': 0,
      'stack': 100,
      'cards': ['Qs', 'Qh'],
    },
    {'player_id': 'other', 'seat': 1, 'stack': 200, 'cards': null},
  ],
};
Map<String, Object?> bridge() => {
  'version': 1,
  'instance': 'test_1',
  'theme': 'dark',
  'locale': 'en',
  'preview': true,
};

void main() {
  test('engine projection is immutable and permits only own private cards', () {
    final input = snapshot();
    final table = TableSnapshot.parse(input, viewerId: 'self');
    expect(table.version, 1);
    expect(table.phase, 'betting');
    expect(table.pot, 40);
    expect(table.players.first.cards, ['Qs', 'Qh']);
    expect(table.players.last.cards, isNull);
    expect(() => table.board.add('Ac'), throwsUnsupportedError);
    expect(() => table.players.clear(), throwsUnsupportedError);
    expect(() => table.players.first.cards!.clear(), throwsUnsupportedError);
    expect(() => TableSnapshot.parse(input), throwsFormatException);
  });
  for (final invalid in [null, false, -1, 1.5, '1', 9007199254740992]) {
    test('safe integer rejects $invalid', () {
      expect(() => integer(invalid), throwsFormatException);
    });
  }
  test('safe integer exact bounds', () {
    expect(integer(0), 0);
    expect(integer(9007199254740991), 9007199254740991);
  });
  for (final invalid in [null, 1, '', 'a' * 65]) {
    test('bounded text rejects $invalid', () {
      expect(() => text(invalid), throwsFormatException);
    });
  }
  test('bounded text and object validation', () {
    expect(text('a' * 64), 'a' * 64);
    expect(object(<String, Object?>{}, {}), isEmpty);
    expect(object(<Object?, Object?>{'value': 1}, {'value'}), {'value': 1});
    expect(
      () => object(<Object?, Object?>{1: 'value'}, {'value'}),
      throwsFormatException,
    );
    expect(() => object(null, {}), throwsFormatException);
    expect(() => object({'token': 'synthetic'}, {}), throwsFormatException);
    expect(() => array({}, 5), throwsFormatException);
    expect(() => array(List.filled(6, 0), 5), throwsFormatException);
    expect(() => parseCards(['ZZ'], 5), throwsFormatException);
  });
  for (final phase in ['waiting', 'ready', 'betting', 'showdown']) {
    test('engine phase $phase', () {
      final raw = snapshot()..['phase'] = phase;
      expect(TableSnapshot.parse(raw, viewerId: 'self').phase, phase);
    });
  }
  test('unknown phase and duplicated player/seat fail closed', () {
    expect(
      () => TableSnapshot.parse(snapshot()..['phase'] = 'settled'),
      throwsFormatException,
    );
    final duplicate = snapshot()
      ..['players'] = [
        {'player_id': 'one', 'seat': 0, 'stack': 10, 'cards': null},
        {'player_id': 'one', 'seat': 1, 'stack': 20, 'cards': null},
      ];
    expect(() => TableSnapshot.parse(duplicate), throwsFormatException);
    duplicate['players'] = [
      {'player_id': 'one', 'seat': 0, 'stack': 10, 'cards': null},
      {'player_id': 'two', 'seat': 0, 'stack': 20, 'cards': null},
    ];
    expect(() => TableSnapshot.parse(duplicate), throwsFormatException);
    expect(
      () => TableSnapshot.parse(snapshot()..['server_view'] = {}),
      throwsFormatException,
    );
  });
  test('bridge accepts explicit non-secret configuration', () {
    final context = BridgeContext.parse(bridge());
    expect(context.instance, 'test_1');
    expect(context.theme, 'dark');
    expect(context.locale, 'en');
    expect(context.preview, isTrue);
  });
  for (final field in {
    'version': [0, 2, null, '1'],
    'instance': ['bad id', '', null],
    'theme': ['system', null],
    'locale': ['unknown', null],
    'preview': ['true', null],
    'access_token': ['synthetic'],
  }.entries) {
    for (final invalid in field.value) {
      test('bridge rejects ${field.key}=$invalid', () {
        expect(
          () => BridgeContext.parse(bridge()..[field.key] = invalid),
          throwsFormatException,
        );
      });
    }
  }
}
