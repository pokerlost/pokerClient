import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:poker_client_workspace/src/web_artifact.dart';

Map<String, Object?> readJson(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>);
void writeJson(String path, Object value) => File(
  path,
).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(value)}\n');
String hash(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

Future<Map<String, String>> versions() async {
  // Pub owns YAML/workspace interpretation; no second pubspec parser or version file.
  final data = jsonDecode(
    await command('dart', ['pub', 'deps', '--json']),
  ) as Map<String, Object?>;
  final result = <String, String>{};
  for (final value in data['packages']! as List<Object?>) {
    final package = value! as Map<String, Object?>;
    if (package['kind'] == 'root') {
      result[package['name']! as String] = package['version']! as String;
    }
  }
  if (!result.containsKey('poker_game_web') || result.length != 6) {
    throw const FormatException(
      'Expected the complete six-member pub workspace',
    );
  }
  return result;
}

String get bundleName =>
    Platform.environment['BUNDLE_NAME'] ?? 'poker-game-web';
String get bundle => '/artifacts/$bundleName';
Future<void> releaseCheck() async {
  final source = readJson('coverage/source.json');
  if (source['dirty'] != false) {
    throw const FormatException(
      'Release readiness requires clean reviewed source',
    );
  }
  final expected = await versions();
  await verifyBundle(Directory(bundle), source['commit']! as String);
  final built = readJson('$bundle/version.json');
  if (built['version'] != expected['poker_game_web'] ||
      built['app_name'] != 'poker_game_web') {
    throw const FormatException('Flutter built application version mismatch');
  }
  stdout.writeln(
    'Pub workspace, Flutter version.json and bridge 1 bundle agree.',
  );
}

Future<void> receipt(List<String> args) async {
  const path = 'coverage/ci-local.json';
  String option(String key) => args[args.indexOf(key) + 1];
  late Map<String, Object?> report;
  if (args.first == 'init') {
    report = {
      'schemaVersion': 1,
      'source': readJson('coverage/source.json'),
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'status': 'running',
      'checks': <Object?>[],
      'artifacts': <Object?>[],
      'versions': await versions(),
      'tools': {
        'dart': Platform.version,
        'flutter': readJson('toolchain.lock.json')['flutterVersion'],
        'flutterRevision': readJson('toolchain.lock.json')['frameworkRevision'],
      },
    };
  } else {
    report = readJson(path);
    if (args.first == 'record') {
      final code = int.parse(option('--exit-code'));
      (report['checks']! as List<Object?>).add({
        'name': option('--name'),
        'command': option('--command'),
        'status': code == 0 ? 'passed' : 'failed',
        'exitCode': code,
      });
    } else if (args.first == 'finish') {
      report['status'] = option('--status');
      final checks = report['checks']! as List<Object?>;
      if (report['status'] == 'passed' &&
          (checks.isEmpty ||
              checks.any(
                (entry) => (entry! as Map<String, Object?>)['exitCode'] != 0,
              ))) {
        report['status'] = 'failed';
      }
      if (jsonEncode(report['source']) !=
          jsonEncode(readJson('coverage/source.json'))) {
        report['status'] = 'failed';
      }
      report['finishedAt'] = DateTime.now().toUtc().toIso8601String();
      final version =
          (report['versions']! as Map<String, Object?>)['poker_game_web'];
      final artifacts = <Map<String, Object?>>[];
      for (final name in ['artifact-manifest.json', 'version.json']) {
        if (File('$bundle/$name').existsSync()) {
          artifacts.add({
            'path': 'dist/$bundleName/$name',
            'sha256': hash('$bundle/$name'),
            'version': version,
          });
        }
      }
      report['artifacts'] = artifacts;
      report['coverage'] = {
        'policy': 'advisory',
        'report': 'coverage/dart/source-inventory.json',
        'branches': 'notMeasured',
      };
      File('coverage/checksums.sha256').writeAsStringSync(
        artifacts
            .map((entry) => "${entry['sha256']}  ${entry['path']}\n")
            .join(),
      );
      final source = report['source']! as Map<String, Object?>;
      File('coverage/ci-local-summary.md').writeAsStringSync(
        "# Local CI: ${report['status']}\n\nSource: ${source['commit']}; dirty: ${source['dirty']}.\n\n"
        '${(report['checks']! as List<Object?>).map((entry) {
          final check = entry! as Map<String, Object?>;
          return "- ${check['name']}: ${check['status']} (${check['exitCode']})";
        }).join('\n')}\n',
      );
    } else {
      throw const FormatException('Unknown receipt operation');
    }
  }
  writeJson(path, report);
  if (args.first == 'finish' && report['status'] != option('--status')) {
    throw const FormatException('Source changed during local CI');
  }
}

Future<void> runMetadata(List<String> args) async {
  switch (args.first) {
    case 'version':
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(await versions()),
      );
    case 'release-check':
      await releaseCheck();
    case 'receipt':
      await receipt(args.sublist(1));
    default:
      throw const FormatException('Expected version, release-check or receipt');
  }
}
