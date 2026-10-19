import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_contract/poker_contract.dart';

void main() {
  final corpus = jsonDecode(
    File('contracts/bridge-v1-fixtures.json').readAsStringSync(),
  ) as Map<String, Object?>;
  test(
    'shared bridge corpus preserves contexts and explicit event wire values',
    () {
      final contexts = corpus['validContexts']! as List<Object?>;
      for (final value in contexts) {
        expect(BridgeContext.parse(value).toJson(), value);
      }
      final context = BridgeContext.parse(contexts.first);
      for (final value in corpus['events']! as List<Object?>) {
        final event = value! as Map<String, Object?>;
        expect(context.event(7, BridgeEventKind.parse(event['kind'])), event);
      }
    },
  );
  test('shared negative corpus fails closed', () {
    for (final value in corpus['invalidContexts']! as List<Object?>) {
      expect(() => BridgeContext.parse(value), throwsFormatException);
    }
  });
}
