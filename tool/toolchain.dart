import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final expected = jsonDecode(
    File('toolchain.lock.json').readAsStringSync(),
  ) as Map<String, Object?>;
  if (args case ['verify', final file]) {
    final actual =
        jsonDecode(File(file).readAsStringSync()) as Map<String, Object?>;
    if (!expected.entries.every((entry) => actual[entry.key] == entry.value)) {
      throw const FormatException('Flutter/Dart toolchain mismatch');
    }
  } else if (args case [final key] when expected[key] is String) {
    stdout.writeln(expected[key]);
  } else {
    throw const FormatException('Use a toolchain key or verify FILE');
  }
}
