import 'dart:convert';
import 'dart:io';

import 'package:booklify/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String locale) {
  final json = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
      as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('ru and uz ARB files define every English key', () {
    final en = _keys('en');
    for (final loc in ['ru', 'uz']) {
      final missing = en.difference(_keys(loc));
      expect(missing, isEmpty, reason: '$loc is missing $missing');
    }
  });

  for (final code in ['en', 'ru', 'uz']) {
    testWidgets('AppLocalizations loads for "$code"', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(code),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          l = context.l10n;
          return const SizedBox();
        }),
      ));
      expect(l.navLearn, isNotEmpty);
      expect(l.commonSignOut, isNotEmpty);
    });
  }
}
