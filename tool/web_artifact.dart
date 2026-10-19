import 'dart:io';

import 'package:poker_client_workspace/src/web_artifact.dart';

Future<void> main(List<String> args) async {
  if (args.length == 1 && args.single == '--help') {
    stdout.writeln(
      'export-web BUNDLE DESTINATION [FLUTTER] | verify BUNDLE FULL_SHA',
    );
    return;
  }
  try {
    switch (args) {
      case ['export-web', final bundle, final destination]:
        await exportCleanCommit(
          Directory(bundle),
          Directory(destination),
          'flutter',
        );
      case ['export-web', final bundle, final destination, final flutter]:
        await exportCleanCommit(
          Directory(bundle),
          Directory(destination),
          flutter,
        );
      case ['verify', final bundle, final revision]:
        await verifyBundle(Directory(bundle), revision);
      default:
        throw const FormatException('Use --help for artifact commands');
    }
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
