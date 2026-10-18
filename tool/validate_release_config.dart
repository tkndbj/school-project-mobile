import 'dart:convert';
import 'dart:io';
import 'package:school_platform/src/core/config/production_values.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/validate_release_config.dart env/prod.json',
    );
    exitCode = 1;
    return;
  }
  try {
    final data =
        jsonDecode(File(args.single).readAsStringSync())
            as Map<String, dynamic>;
    final values = data.map((key, value) => MapEntry(key, value as String));
    final problems = validateProductionValues(values);
    if (problems.isNotEmpty) {
      problems.forEach(stderr.writeln);
      exitCode = 1;
      return;
    }
    stdout.writeln('Production public configuration is valid.');
  } on Object {
    stderr.writeln(
      'Release configuration file is missing or invalid. No values printed.',
    );
    exitCode = 1;
  }
}
