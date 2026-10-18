import 'dart:convert';
import 'dart:io';

// LCOV is an executable-line metric. Keep uninstrumented source explicit rather
// than treating every physical source line as executable or silently omitting it.
void main() {
  final measurements = <String, Map<int, int>>{};
  for (final name in ['contract', 'game', 'native', 'tool']) {
    String? source;
    for (final line in File('coverage/$name/lcov.info').readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        source = File(line.substring(3)).absolute.path;
        measurements.putIfAbsent(source, () => {});
      } else if (source != null && line.startsWith('DA:')) {
        final pair = line.substring(3).split(',').map(int.parse).toList();
        measurements[source]!.update(
          pair[0],
          (old) => old + pair[1],
          ifAbsent: () => pair[1],
        );
      }
    }
  }
  final inventory = <Map<String, Object>>[];
  for (final directory in [
    'lib',
    'tool',
    'packages/poker_contract/lib',
    'packages/poker_game/lib',
    'apps/poker_client/lib',
    'apps/poker_game_web/lib',
  ]) {
    for (final file
        in Directory(directory)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final hits = measurements[file.absolute.path] ?? {};
      inventory.add({
        'source': file.path,
        'measurement': hits.isEmpty ? 'notInstrumented' : 'lcov',
        'linesFound': hits.length,
        'linesHit': hits.values.where((count) => count > 0).length,
        'missingLines': hits.entries
            .where((entry) => entry.value == 0)
            .map((entry) => entry.key)
            .toList(),
      });
    }
  }
  inventory.sort(
    (a, b) => (a['source'] as String).compareTo(b['source'] as String),
  );
  final report = {'branchCoverage': 'notMeasured', 'files': inventory};
  Directory('coverage/dart').createSync(recursive: true);
  File('coverage/dart/source-inventory.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
