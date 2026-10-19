import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Map<String, String> toolchain(Object? value) {
  if (value is! Map<String, Object?> ||
      value.length != 3 ||
      !RegExp(r'^\d+\.\d+\.\d+$').hasMatch('${value['flutterVersion']}') ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch('${value['frameworkRevision']}') ||
      !RegExp(r'^\d+\.\d+\.\d+$').hasMatch('${value['dartSdkVersion']}')) {
    throw const FormatException('Invalid pinned toolchain');
  }
  return value.cast<String, String>();
}

void fullRevision(String revision) {
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
    throw const FormatException('Expected a full client commit');
  }
}

Future<Map<String, String>> inventory(Directory directory) async {
  if (FileSystemEntity.typeSync(directory.path, followLinks: false) !=
          FileSystemEntityType.directory ||
      !File(p.join(directory.path, 'flutter_bootstrap.js')).existsSync()) {
    throw const FormatException('A built Flutter bundle is required');
  }
  final files = <String, String>{};
  final entries = await directory
      .list(recursive: true, followLinks: false)
      .toList();
  entries.sort((a, b) => a.path.compareTo(b.path));
  for (final entry in entries) {
    if (entry is Link) {
      throw const FormatException('Bundle symlinks are forbidden');
    }
    if (entry is File) {
      final name = p.posix.joinAll(
        p.split(p.relative(entry.path, from: directory.path)),
      );
      if (name != 'artifact-manifest.json') {
        files[name] = sha256.convert(await entry.readAsBytes()).toString();
      }
    }
  }
  return files;
}

Future<Map<String, Object>> exportBundle(
  Directory bundle,
  Directory destination,
  String revision,
  Map<String, String> versions,
) async {
  fullRevision(revision);
  toolchain(versions);
  final files = await inventory(bundle);
  final source = bundle.resolveSymbolicLinksSync();
  var ancestor = destination.absolute;
  final suffix = <String>[];
  while (!ancestor.existsSync()) {
    suffix.insert(0, p.basename(ancestor.path));
    ancestor = ancestor.parent;
  }
  final target = p.normalize(
    p.joinAll([ancestor.resolveSymbolicLinksSync(), ...suffix]),
  );
  if (p.equals(source, target) || p.isWithin(source, target)) {
    throw const FormatException(
      'Artifact destination must be outside the bundle',
    );
  }
  if (FileSystemEntity.typeSync(destination.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw const FormatException('Use a fresh artifact destination');
  }
  if (File(p.join(bundle.path, 'artifact-manifest.json')).existsSync()) {
    throw const FormatException(
      'Export the raw build, not a previous artifact',
    );
  }
  final manifest = <String, Object>{
    'bridgeVersion': 1,
    'clientCommit': revision,
    'files': files,
    'toolchain': versions,
  };
  await destination.create(recursive: true);
  for (final name in files.keys) {
    final output = File(p.join(destination.path, name));
    await output.parent.create(recursive: true);
    await File(p.join(bundle.path, name)).copy(output.path);
  }
  await File(
    p.join(destination.path, 'artifact-manifest.json'),
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  await verifyBundle(destination, revision);
  return manifest;
}

Future<void> verifyBundle(Directory bundle, String revision) async {
  fullRevision(revision);
  final value = jsonDecode(
    await File(p.join(bundle.path, 'artifact-manifest.json')).readAsString(),
  );
  if (value is! Map<String, Object?> ||
      value.length != 4 ||
      value['clientCommit'] != revision ||
      value['bridgeVersion'] != 1) {
    throw const FormatException('Artifact identity mismatch');
  }
  toolchain(value['toolchain']);
  final expected = value['files'];
  final actual = await inventory(bundle);
  if (expected is! Map<String, Object?> ||
      expected.length != actual.length ||
      !actual.entries.every((entry) => expected[entry.key] == entry.value)) {
    throw const FormatException('Artifact inventory or checksum mismatch');
  }
}

Future<String> command(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
  return '${result.stdout}'.trim();
}

Future<void> exportCleanCommit(
  Directory bundle,
  Directory destination,
  String flutter,
) async {
  final root = Directory.current.resolveSymbolicLinksSync();
  if (await command('git', ['rev-parse', '--show-toplevel']) != root) {
    throw const FormatException('Run from the exact client Git root');
  }
  if ((await command('git', ['status', '--porcelain'])).isNotEmpty) {
    throw const FormatException(
      'Commit and verify the client source before exporting',
    );
  }
  final revision = await command('git', ['rev-parse', 'HEAD']);
  final expected = toolchain(
    jsonDecode(await File('toolchain.lock.json').readAsString()),
  );
  final actual = jsonDecode(
    await command(flutter, ['--version', '--machine']),
  ) as Map<String, Object?>;
  if (!expected.entries.every((entry) => actual[entry.key] == entry.value)) {
    throw const FormatException('Flutter toolchain mismatch');
  }
  await exportBundle(bundle, destination, revision, expected);
}
