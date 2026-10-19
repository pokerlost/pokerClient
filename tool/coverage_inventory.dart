import 'dart:convert';
import 'dart:io';

// LCOV is an executable-line metric. Keep uninstrumented source explicit rather
// than treating every physical source line as executable or silently omitting it.
void main() {
  final measurements = <String, Map<int, int>>{};
  for (final name in ['contract', 'game', 'native', 'tool']) {
    final report = File('coverage/$name/lcov.info');
    final started = File('coverage/.started');
    if (report.lastModifiedSync().isBefore(started.lastModifiedSync())) {
      throw const FormatException('Stale Dart coverage report');
    }
    String? source;
    var found = 0;
    for (final line in report.readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        source = File(line.substring(3)).absolute.path;
        measurements.putIfAbsent(source, () => {});
      } else if (source != null && line.startsWith('DA:')) {
        final pair = line.substring(3).split(',').map(int.parse).toList();
        if (pair.length != 2 || pair[0] <= 0 || pair[1] < 0) {
          throw const FormatException('Invalid LCOV line counters');
        }
        found++;
        measurements[source]!.update(
          pair[0],
          (old) => old + pair[1],
          ifAbsent: () => pair[1],
        );
      }
    }
    if (found == 0) throw const FormatException('Empty required LCOV report');
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
  final total = measurements.values.fold(0, (sum, hits) => sum + hits.length);
  final covered = measurements.values.fold(
    0,
    (sum, hits) => sum + hits.values.where((count) => count > 0).length,
  );
  if (total == 0) throw const FormatException('No executable Dart lines');
  final percentage = (100 * covered / total).toStringAsFixed(2);
  final uninstrumented = inventory
      .where((file) => file['measurement'] == 'notInstrumented')
      .map((file) => '`${file['source']}`')
      .join(', ');
  final summary =
      '| Metric | Covered / total | Missing | Coverage |\n'
      '| --- | --- | --- | --- |\n'
      '| Dart executable lines | $covered / $total | ${total - covered} | $percentage% |\n'
      '| Dart branches | notMeasured | notMeasured | notMeasured |\n\n'
      'Not instrumented by VM LCOV: $uninstrumented.\n\n'
      'Coverage is advisory. Browser interop is exercised by pokerWeb acceptance.\n';
  File('coverage/summary.md').writeAsStringSync(summary);
  if (covered < total) {
    final message =
        'Dart coverage advisory: $covered/$total lines ($percentage%); '
        '${total - covered} missing.';
    stdout.writeln('WARNING: $message');
    if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
      stdout.writeln('::warning::${message.replaceAll('%', '%25')}');
    }
  }
  stdout.writeln(summary);
}
