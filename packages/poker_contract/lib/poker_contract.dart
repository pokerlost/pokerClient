/// Validated presentation values. These are not a production realtime protocol.
library;

Map<String, Object?> object(Object? value, Set<String> keys) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String || !keys.contains(key))) {
    throw const FormatException('Unexpected object shape');
  }
  return value.cast<String, Object?>();
}

String text(Object? value) {
  if (value is! String || value.isEmpty || value.length > 64) {
    throw const FormatException('Expected bounded text');
  }
  return value;
}

int integer(Object? value, {int max = 9007199254740991}) {
  if (value is! int || value < 0 || value > max) {
    throw const FormatException('Expected nonnegative safe integer');
  }
  return value;
}

List<Object?> array(Object? value, int max) {
  if (value is! List<Object?> || value.length > max) {
    throw const FormatException('Expected bounded array');
  }
  return value;
}

List<String> parseCards(Object? value, int max) => List.unmodifiable(
  array(value, max).map((value) {
    final card = text(value);
    if (!RegExp(r'^[2-9TJQKA][cdhs]$').hasMatch(card)) {
      throw const FormatException('Invalid card');
    }
    return card;
  }),
);

final class PlayerSnapshot {
  PlayerSnapshot._(this.id, this.seat, this.stack, this.cards);
  final String id;
  final int seat;
  final int stack;
  final List<String>? cards;

  factory PlayerSnapshot.parse(Object? value, String? viewerId) {
    final data = object(value, {'player_id', 'seat', 'stack', 'cards'});
    final id = text(data['player_id']);
    final privateCards = data['cards'];
    if (privateCards != null && id != viewerId) {
      throw const FormatException('Opponent private cards are forbidden');
    }
    return PlayerSnapshot._(
      id,
      integer(data['seat'], max: 21),
      integer(data['stack']),
      privateCards == null ? null : parseCards(privateCards, 2),
    );
  }
}

final class TableSnapshot {
  TableSnapshot._(this.version, this.phase, this.pot, this.board, this.players);
  final int version;
  final String phase;
  final int pot;
  final List<String> board;
  final List<PlayerSnapshot> players;

  factory TableSnapshot.parse(Object? value, {String? viewerId}) {
    final data = object(value, {'version', 'phase', 'pot', 'board', 'players'});
    final phase = text(data['phase']);
    if (!{'waiting', 'ready', 'betting', 'showdown'}.contains(phase)) {
      throw const FormatException('Unknown engine phase');
    }
    final players = array(
      data['players'],
      22,
    ).map((value) => PlayerSnapshot.parse(value, viewerId)).toList();
    if (players.map((p) => p.id).toSet().length != players.length ||
        players.map((p) => p.seat).toSet().length != players.length) {
      throw const FormatException('Duplicate player or seat');
    }
    return TableSnapshot._(
      integer(data['version']),
      phase,
      integer(data['pot']),
      parseCards(data['board'], 5),
      List.unmodifiable(players),
    );
  }
}

/// This small contract controls embedding, never gameplay state or credentials.
final class BridgeContext {
  BridgeContext._(this.instance, this.theme, this.locale, this.preview);
  static const version = 1;
  final String instance;
  final String theme;
  final String locale;
  final bool preview;

  factory BridgeContext.parse(Object? value) {
    final data = object(value, {
      'version',
      'instance',
      'theme',
      'locale',
      'preview',
    });
    if (data['version'] != version) {
      throw const FormatException('Incompatible bridge version');
    }
    final instance = text(data['instance']);
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(instance) ||
        !{'light', 'dark'}.contains(data['theme']) ||
        data['locale'] != 'en' ||
        data['preview'] is! bool) {
      throw const FormatException('Invalid bridge context');
    }
    return BridgeContext._(
      instance,
      data['theme']! as String,
      data['locale']! as String,
      data['preview']! as bool,
    );
  }
}
