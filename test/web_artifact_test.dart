import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:poker_client_workspace/src/web_artifact.dart';

const revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const versions = {
  'flutterVersion': '3.47.0',
  'frameworkRevision': '4cf24164269a5ebf0c16a028a00727d0e77bbb05',
  'dartSdkVersion': '3.13.0',
};

void main() {
  late Directory temporary;
  late Directory bundle;
  late Directory output;
  setUp(() {
    temporary = Directory.systemTemp.createTempSync('client-artifact-test-');
    bundle = Directory(p.join(temporary.path, 'bundle'))..createSync();
    File(p.join(bundle.path, 'flutter_bootstrap.js'))
        .writeAsStringSync('synthetic loader');
    Directory(p.join(bundle.path, 'assets')).createSync();
    File(p.join(bundle.path, 'assets/data'))
        .writeAsStringSync('public synthetic data');
    output = Directory(p.join(temporary.path, 'output'));
  });
  tearDown(() => temporary.deleteSync(recursive: true));

  test(
    'export preserves all bytes and produces a deterministic full manifest',
    () async {
      final first = await exportBundle(bundle, output, revision, versions);
      expect(first['clientCommit'], revision);
      expect(first['bridgeVersion'], 1);
      expect(
        (first['files'] as Map)['assets/data'],
        sha256.convert(utf8.encode('public synthetic data')).toString(),
      );
      final second = Directory(p.join(temporary.path, 'second'));
      await exportBundle(bundle, second, revision, versions);
      expect(
        File(p.join(output.path, 'artifact-manifest.json')).readAsStringSync(),
        File(p.join(second.path, 'artifact-manifest.json')).readAsStringSync(),
      );
      expect(
        File(p.join(output.path, 'assets/data')).readAsStringSync(),
        'public synthetic data',
      );
      File(p.join(bundle.path, 'assets/data'))
          .writeAsStringSync('changed bytes');
      final changed = await exportBundle(
        bundle,
        Directory(p.join(temporary.path, 'changed')),
        revision,
        versions,
      );
      expect(changed['files'], isNot(first['files']));
    },
  );

  test('revision and toolchain inputs are validated', () async {
    for (final invalid in ['main', 'a' * 39, 'z' * 40]) {
      await expectLater(
        exportBundle(bundle, output, invalid, versions),
        throwsFormatException,
      );
    }
    for (final invalid in [
      null,
      <String, Object?>{},
      {...versions, 'extra': 'key'},
      {...versions, 'flutterVersion': 'main'},
      {...versions, 'frameworkRevision': 'tag'},
      {...versions, 'dartSdkVersion': false},
    ]) {
      expect(() => toolchain(invalid), throwsFormatException);
    }
  });

  test('missing builds, recursive/existing destinations and symlinks fail before writing', () async {
    for (final invalid in [
      Directory(p.join(temporary.path, 'missing')),
      Directory(p.join(bundle.path, 'assets')),
    ]) {
      await expectLater(
        exportBundle(invalid, output, revision, versions),
        throwsFormatException,
      );
    }
    for (final destination in [
      bundle,
      Directory(p.join(bundle.path, 'nested')),
      temporary,
    ]) {
      await expectLater(
        exportBundle(bundle, destination, revision, versions),
        throwsFormatException,
      );
    }
    final alias = Link(p.join(temporary.path, 'alias'))
      ..createSync(bundle.path);
    await expectLater(
      exportBundle(
        Directory(p.join(alias.path, 'nested')),
        output,
        revision,
        versions,
      ),
      throwsFormatException,
    );
    await expectLater(
      exportBundle(
        bundle,
        Directory(p.join(alias.path, 'nested')),
        revision,
        versions,
      ),
      throwsFormatException,
    );
    Link(p.join(bundle.path, 'link'))
        .createSync(p.join(bundle.path, 'assets/data'));
    await expectLater(
      exportBundle(bundle, output, revision, versions),
      throwsFormatException,
    );
    expect(output.existsSync(), isFalse);
  });

  test('an existing export cannot be used as a raw build', () async {
    await exportBundle(bundle, output, revision, versions);
    await expectLater(
      exportBundle(
        output,
        Directory(p.join(temporary.path, 'again')),
        revision,
        versions,
      ),
      throwsFormatException,
    );
  });

  test('verification rejects wrong identities, changed/missing/extra files and traversal', () async {
    final manifest = await exportBundle(bundle, output, revision, versions);
    final file = File(p.join(output.path, 'artifact-manifest.json'));
    for (final invalid in [
      <Object?>[],
      {...manifest, 'clientCommit': 'b' * 40},
      {...manifest, 'bridgeVersion': 2},
      {...manifest, 'extra': true},
      {...manifest, 'toolchain': <String, Object?>{}},
      {...manifest, 'files': null},
      {
        ...manifest,
        'files': {'../outside': '0' * 64, 'flutter_bootstrap.js': '0' * 64},
      },
    ]) {
      file.writeAsStringSync(jsonEncode(invalid));
      await expectLater(verifyBundle(output, revision), throwsFormatException);
    }
    file.writeAsStringSync(jsonEncode(manifest));
    final data = File(p.join(output.path, 'assets/data'));
    data.writeAsStringSync('tampered');
    await expectLater(verifyBundle(output, revision), throwsFormatException);
    data.writeAsStringSync('public synthetic data');
    final extra = File(p.join(output.path, 'unexpected'))
      ..writeAsStringSync('extra');
    await expectLater(verifyBundle(output, revision), throwsFormatException);
    extra.deleteSync();
    data.deleteSync();
    await expectLater(verifyBundle(output, revision), throwsFormatException);
  });

  test(
    'clean Git identity and the actual SDK are mandatory for export',
    () async {
      final original = Directory.current;
      final repo = Directory(p.join(temporary.path, 'repo'))..createSync();
      Future<String> git(List<String> args) async {
        final result = await Process.run(
          'git',
          args,
          workingDirectory: repo.path,
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        return '${result.stdout}'.trim();
      }

      // Every synthetic repository is explicitly initialized, never inherited.
      await git(['init', '--quiet']);
      File(p.join(repo.path, 'toolchain.lock.json'))
          .writeAsStringSync(jsonEncode(versions));
      await git(['add', 'toolchain.lock.json']);
      await git([
        '-c',
        'user.name=Artifact Test',
        '-c',
        'user.email=artifact@example.invalid',
        'commit',
        '--quiet',
        '-m',
        'fixture',
      ]);
      final flutter = File(p.join(temporary.path, 'flutter'));
      flutter.writeAsStringSync(
        "#!/bin/sh\nprintf '%s\\n' '${jsonEncode(versions)}'\n",
      );
      await Process.run('chmod', ['700', flutter.path]);
      try {
        Directory.current = repo;
        await exportCleanCommit(bundle, output, flutter.path);
        await verifyBundle(output, await git(['rev-parse', 'HEAD']));
        flutter.writeAsStringSync("#!/bin/sh\nprintf '%s\\n' '{}'\n");
        await expectLater(
          exportCleanCommit(
            bundle,
            Directory(p.join(temporary.path, 'wrong')),
            flutter.path,
          ),
          throwsFormatException,
        );
        File('dirty').writeAsStringSync('uncommitted');
        await expectLater(
          exportCleanCommit(
            bundle,
            Directory(p.join(temporary.path, 'dirty-output')),
            flutter.path,
          ),
          throwsFormatException,
        );
        Directory.current = Directory(p.join(repo.path, 'child'))..createSync();
        await expectLater(
          exportCleanCommit(bundle, output, flutter.path),
          throwsFormatException,
        );
      } finally {
        Directory.current = original;
      }
      await expectLater(
        command('git', ['not-a-real-command']),
        throwsA(isA<ProcessException>()),
      );
    },
  );

  test(
    'Dart command help, errors and bundle verification run as actual processes',
    () async {
      final dart = Platform.environment['DART'] ?? 'dart';
      final help = await Process.run(dart, [
        'run',
        'tool/web_artifact.dart',
        '--help',
      ]);
      expect(help.exitCode, 0, reason: '${help.stderr}');
      expect(help.stdout, contains('export-web BUNDLE'));
      final invalid = await Process.run(dart, [
        'run',
        'tool/web_artifact.dart',
      ]);
      expect(invalid.exitCode, 1);
      await exportBundle(bundle, output, revision, versions);
      final verified = await Process.run(dart, [
        'run',
        'tool/web_artifact.dart',
        'verify',
        output.path,
        revision,
      ]);
      expect(verified.exitCode, 0, reason: '${verified.stderr}');
    },
  );
}
