import 'dart:io';

import 'package:booklify/app.dart';
import 'package:booklify/data/services/database_service.dart';
import 'package:booklify/presentation/screens/auth/onboarding_screen.dart';
import 'package:booklify/presentation/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

// Launches the real app UI. No API keys are set, so AI features must fail
// gracefully instead of crashing screens.

Future<void> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1179, 2556); // iPhone 15
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(const ProviderScope(child: BooklifyApp()));
    // Let SQLite / SharedPreferences (real async I/O) finish.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump(const Duration(milliseconds: 100));
}

/// Unmount while real async I/O can still complete, so no DB timers leak.
Future<void> _unmount(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const SizedBox());
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
}

/// Fails on real exceptions. Layout overflows are ignored: the test font draws
/// every glyph as a full-width square, so text is far wider than on a device.
void _expectNoCrash(WidgetTester tester, {String? reason}) {
  final e = tester.takeException();
  if (e is FlutterError && e.toString().contains('overflowed')) return;
  expect(e, isNull, reason: reason);
}

Future<void> _settleIo(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('booklify_widget_test');
    await databaseFactory.setDatabasesPath(dir.path);
    dotenv.loadFromString(envString: 'ANTHROPIC_API_KEY=\nOPENAI_API_KEY=\nGEMINI_API_KEY=');
  });

  testWidgets('logged-out user sees onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _launch(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    _expectNoCrash(tester);
    await _unmount(tester);
  });

  testWidgets('logged-in user sees the main screen and every tab opens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() => DatabaseService()
        .signUp(email: '${const Uuid().v4()}@t.dev', password: 'pw123456', displayName: 'Tester'));

    await _launch(tester);
    expect(find.byType(MainScreen), findsOneWidget);

    for (final tab in ['Books', 'Insights', 'Profile', 'Learn']) {
      await tester.tap(find.text(tab).last);
      await _settleIo(tester);
      _expectNoCrash(tester, reason: 'tab "$tab" threw');
    }
    await _unmount(tester);
  });

  testWidgets('saved Russian language is applied to the navigation', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    await tester.runAsync(() => DatabaseService()
        .signUp(email: '${const Uuid().v4()}@t.dev', password: 'pw123456', displayName: 'Tester'));
    await _launch(tester);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Учёба'), findsWidgets);
    expect(find.text('Книги'), findsWidgets);
    expect(find.text('Learn'), findsNothing);
    _expectNoCrash(tester);
    await _unmount(tester);
  });
}
