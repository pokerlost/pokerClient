/// Validated presentation values. These are not a production realtime protocol.
library;

/// Explicit wire values stay stable when Dart identifiers are renamed.
enum TablePhase {
  waiting('waiting'),
  ready('ready'),
  betting('betting'),
  showdown('showdown');

  const TablePhase(this.wireValue);
  final String wireValue;

  static TablePhase parse(Object? value) => switch (value) {
    'waiting' => waiting,
    'ready' => ready,
    'betting' => betting,
    'showdown' => showdown,
    _ => throw const FormatException('Unknown engine phase'),
  };
}

enum BridgeTheme {
  light('light'),
  dark('dark');

  const BridgeTheme(this.wireValue);
  final String wireValue;

  static BridgeTheme parse(Object? value) => switch (value) {
    'light' => light,
    'dark' => dark,
    _ => throw const FormatException('Invalid bridge theme'),
  };
}

enum BridgeEventKind {
  ready('ready'),
  error('error'),
  returnToHost('return');

  const BridgeEventKind(this.wireValue);
  final String wireValue;

  static BridgeEventKind parse(Object? value) => switch (value) {
    'ready' => ready,
    'error' => error,
    'return' => returnToHost,
    _ => throw const FormatException('Invalid bridge event kind'),
  };
}

const bridgeContextEventName = 'poker-context';
const bridgeGameEventName = 'poker-event';
const bridgeCapabilities = ['preview', 'theme', 'return'];

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
  final TablePhase phase;
  final int pot;
  final List<String> board;
  final List<PlayerSnapshot> players;

  factory TableSnapshot.parse(Object? value, {String? viewerId}) {
    final data = object(value, {'version', 'phase', 'pot', 'board', 'players'});
    final phase = TablePhase.parse(data['phase']);
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
  final BridgeTheme theme;
  final String locale;
  final bool preview;

  Map<String, Object?> toJson() => {
    'version': version,
    'instance': instance,
    'theme': theme.wireValue,
    'locale': locale,
    'preview': preview,
  };

  Map<String, Object?> event(int viewId, BridgeEventKind kind) => {
    'version': version,
    'instance': instance,
    'viewId': integer(viewId),
    'kind': kind.wireValue,
    'capabilities': bridgeCapabilities,
  };

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
        data['locale'] != 'en' ||
        data['preview'] is! bool) {
      throw const FormatException('Invalid bridge context');
    }
    return BridgeContext._(
      instance,
      BridgeTheme.parse(data['theme']),
      data['locale']! as String,
      data['preview']! as bool,
    );
  }
}
