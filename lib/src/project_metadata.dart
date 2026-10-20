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

const requiredChecks = [
  'check',
  'coverage',
  'build',
  'export-web',
  'verify',
  'release-check',
];
String stateFor(int code) => code == 0
    ? 'passed'
    : code == 3
    ? 'blocked'
    : 'failed';
Map<String, String> options(List<String> args, List<String> names) {
  if (args.length != names.length * 2) {
    throw const FormatException('Missing or unexpected receipt options');
  }
  final result = <String, String>{};
  for (var index = 0; index < args.length; index += 2) {
    final key = args[index];
    final value = args[index + 1];
    if (!names.contains(key) ||
        result.containsKey(key) ||
        value.isEmpty ||
        value.startsWith('--')) {
      throw const FormatException('Invalid receipt option');
    }
    result[key] = value;
  }
  return result;
}

void validateSource(Object? value) {
  if (value is! Map<String, Object?> ||
      value.length != 3 ||
      value['dirty'] is! bool ||
      value['commit'] is! String ||
      !RegExp(r'^[a-f0-9]{40,64}$').hasMatch(value['commit']! as String) ||
      value['contentSha256'] is! String ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['contentSha256']! as String)) {
    throw const FormatException('Malformed source identity');
  }
}

Map<String, Object?> plan() {
  final value = readJson('coverage/ci-plan.json');
  final checks = value['checks'];
  if (value.length != 2 ||
      !['full', 'scoped'].contains(value['scope']) ||
      checks is! List<Object?> ||
      checks.isEmpty ||
      checks.toSet().length != checks.length ||
      checks.any((name) => !requiredChecks.contains(name)) ||
      (value['scope'] == 'full' &&
          jsonEncode(checks) != jsonEncode(requiredChecks))) {
    throw const FormatException('Invalid native CI plan');
  }
  return value;
}

void validateReceipt(Map<String, Object?> value) {
  validateSource(value['source']);
  final currentPlan = plan();
  if (value['schemaVersion'] != 1 ||
      value['status'] != 'running' ||
      value['scope'] != currentPlan['scope'] ||
      jsonEncode(value['plannedChecks']) != jsonEncode(currentPlan['checks']) ||
      value['checks'] is! List<Object?> ||
      value['artifacts'] is! List<Object?> ||
      value['versions'] is! Map<String, Object?>) {
    throw const FormatException('Malformed, finished or changed receipt');
  }
  final names = <String>[];
  for (final raw in value['checks']! as List<Object?>) {
    if (raw is! Map<String, Object?> ||
        raw.length != 4 ||
        raw['name'] is! String ||
        raw['command'] is! String ||
        (raw['command']! as String).isEmpty ||
        raw['exitCode'] is! int) {
      throw const FormatException('Malformed native check');
    }
    final name = raw['name']! as String;
    final code = raw['exitCode']! as int;
    if (code < 0 ||
        code > 255 ||
        raw['status'] != stateFor(code) ||
        names.contains(name) ||
        (name == 'offline-preflight' && names.isNotEmpty)) {
      throw const FormatException('Duplicate or malformed native check');
    }
    names.add(name);
  }
  final native = names.where((name) => name != 'offline-preflight').toList();
  final expected = value['plannedChecks']! as List<Object?>;
  if (native.length > expected.length ||
      jsonEncode(native) != jsonEncode(expected.take(native.length).toList())) {
    throw const FormatException('Native checks do not match the declared plan');
  }
}

List<Map<String, Object?>> artifactRecords(
  Object? version, {
  required bool required,
}) {
  final artifacts = <Map<String, Object?>>[];
  for (final name in ['artifact-manifest.json', 'version.json']) {
    if (!File('$bundle/$name').existsSync()) {
      if (required) {
        throw const FormatException('Missing required built artifact');
      }
      continue;
    }
    if (version is! String || version.isEmpty) {
      throw const FormatException('Missing artifact version');
    }
    artifacts.add({
      'path': 'dist/$bundleName/$name',
      'sha256': hash('$bundle/$name'),
      'version': version,
    });
  }
  return artifacts;
}

Future<void> receipt(List<String> args) async {
  const path = 'coverage/ci-local.json';
  if (args.isEmpty) throw const FormatException('Missing receipt operation');
  final operation = args.first;
  final rest = args.sublist(1);
  late Map<String, Object?> report;
  Object? failure;
  if (operation == 'init') {
    options(rest, []);
    final currentPlan = plan();
    final source = readJson('coverage/source.json');
    validateSource(source);
    report = {
      'schemaVersion': 1,
      'source': source,
      'scope': currentPlan['scope'],
      'plannedChecks': currentPlan['checks'],
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
    validateReceipt(report);
    if (operation == 'record') {
      final fields = options(rest, ['--name', '--command', '--exit-code']);
      final code = int.tryParse(fields['--exit-code']!);
      if (code == null || !RegExp(r'^\d+$').hasMatch(fields['--exit-code']!)) {
        throw const FormatException('Invalid check exit code');
      }
      (report['checks']! as List<Object?>).add({
        'name': fields['--name'],
        'command': fields['--command'],
        'status': stateFor(code),
        'exitCode': code,
      });
      validateReceipt(report);
    } else if (operation == 'finish') {
      final requested = options(rest, ['--status'])['--status']!;
      if (!['passed', 'failed', 'blocked'].contains(requested)) {
        throw const FormatException('Invalid receipt status');
      }
      report['status'] = requested;
      try {
        final currentSource = readJson('coverage/source.json');
        validateSource(currentSource);
        if (jsonEncode(report['source']) != jsonEncode(currentSource)) {
          throw const FormatException('Source changed during local CI');
        }
        final checks = (report['checks']! as List<Object?>)
            .cast<Map<String, Object?>>();
        if (checks.any((check) => check['status'] == 'failed')) {
          report['status'] = 'failed';
        } else if (checks.any((check) => check['status'] == 'blocked')) {
          report['status'] = 'blocked';
        }
        if (requested == 'passed' && report['status'] == 'blocked') {
          failure = const FormatException('Blocked check cannot produce PASS');
        } else if (requested == 'passed') {
          if (report['status'] != 'passed') {
            throw const FormatException(
              'Non-passing check cannot produce PASS',
            );
          }
          final names = checks
              .where((check) => check['name'] != 'offline-preflight')
              .map((check) => check['name'])
              .toList();
          if (jsonEncode(names) != jsonEncode(report['plannedChecks'])) {
            throw const FormatException('Required checks were not executed');
          }
        }
        report['artifacts'] = report['scope'] == 'full'
            ? artifactRecords(
                (report['versions']! as Map<String, Object?>)['poker_game_web'],
                required: report['status'] == 'passed',
              )
            : <Object?>[];
      } on Object catch (error) {
        failure = error;
        report['status'] = 'failed';
        report['artifacts'] = <Object?>[];
      }
      report['finishedAt'] = DateTime.now().toUtc().toIso8601String();
      report['coverage'] = {
        'policy': 'advisory',
        'report': 'coverage/dart/source-inventory.json',
        'branches': 'notMeasured',
      };
      final artifacts = (report['artifacts']! as List<Object?>)
          .cast<Map<String, Object?>>();
      File('coverage/checksums.sha256').writeAsStringSync(
        artifacts
            .map((entry) => "${entry['sha256']}  ${entry['path']}\n")
            .join(),
      );
      final source = report['source']! as Map<String, Object?>;
      File('coverage/ci-local-summary.md').writeAsStringSync(
        "# Local CI (${report['scope']}): ${report['status']}\n\nSource: ${source['commit']}; dirty: ${source['dirty']}.\n\n"
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
  if (failure != null) throw FormatException(failure.toString());
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
