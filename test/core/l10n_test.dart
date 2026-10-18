import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readArb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('Turkish translates every English message and nothing else', () {
    final en = messageKeys(readArb('en'));
    final tr = messageKeys(readArb('tr'));
    expect(en.difference(tr), isEmpty, reason: 'missing in app_tr.arb');
    expect(tr.difference(en), isEmpty, reason: 'unknown keys in app_tr.arb');
  });

  test('translations keep every placeholder', () {
    final en = readArb('en');
    final tr = readArb('tr');
    final placeholder = RegExp(r'\{(\w+)');
    for (final key in messageKeys(en)) {
      final expected = placeholder
          .allMatches(en[key] as String)
          .map((m) => m.group(1))
          .toSet();
      final actual = placeholder
          .allMatches(tr[key] as String)
          .map((m) => m.group(1))
          .toSet();
      expect(actual, expected, reason: 'placeholders differ for "$key"');
    }
  });
}
