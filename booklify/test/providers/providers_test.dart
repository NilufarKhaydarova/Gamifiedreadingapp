import 'dart:convert';
import 'dart:io';

import 'package:booklify/data/models/book.dart';
import 'package:booklify/presentation/providers/auth_provider.dart';
import 'package:booklify/presentation/providers/garden_provider.dart';
import 'package:booklify/presentation/providers/locale_provider.dart';
import 'package:booklify/presentation/providers/user_stats_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

String _day(int offset) =>
    DateTime.now().add(Duration(days: offset)).toIso8601String().split('T')[0];

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('booklify_provider_test');
    await databaseFactory.setDatabasesPath(dir.path);
  });

  group('UserStatsNotifier (XP, streaks, achievements)', () {
    Future<ProviderContainer> containerWith([Map<String, Object> stats = const {}]) async {
      SharedPreferences.setMockInitialValues(
          stats.isEmpty ? {} : {'booklify_user_stats_v2': jsonEncode(stats)});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(userStatsProvider.future);
      return c;
    }

    test('first session: XP, level, streak 1 and First Steps achievement', () async {
      final c = await containerWith();
      final unlocked = await c.read(userStatsProvider.notifier).completeSession(xpEarned: 60);
      final s = c.read(userStatsProvider).value!;
      expect(s.xp, 85); // 60 for the session + 25 First Steps reward
      expect(s.level, 1);
      expect(s.streakDays, 1);
      expect(s.totalSessionsCompleted, 1);
      expect(unlocked, contains('first_session'));
    });

    test('session XP is capped at 200 per day; achievement rewards are not', () async {
      final c = await containerWith();
      final n = c.read(userStatsProvider.notifier);
      await n.completeSession(xpEarned: 150);
      await n.completeSession(xpEarned: 150);
      await n.completeSession(xpEarned: 150);
      final s = c.read(userStatsProvider).value!;
      expect(s.xpEarnedToday, 200);
      expect(s.xp, 225); // 200 capped session XP + 25 First Steps reward
      expect(s.level, 3);
    });

    test('unlocking an achievement adds its XP reward once', () async {
      final c = await containerWith({'totalSessionsCompleted': 4, 'earnedAchievementIds': ['first_session']});
      final unlocked = await c.read(userStatsProvider.notifier).completeSession(xpEarned: 10);
      expect(unlocked, ['sessions_5']);
      expect(c.read(userStatsProvider).value!.xp, 10 + achievementReward('sessions_5'));
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 10);
      expect(c.read(userStatsProvider).value!.xp, 20 + achievementReward('sessions_5'));
    });

    test('a reward that pushes XP over a threshold unlocks that achievement too', () async {
      final c = await containerWith({'xp': 480, 'level': 5, 'earnedAchievementIds': ['first_session', 'level_5']});
      final unlocked = await c.read(userStatsProvider.notifier).recordBookStarted();
      expect(unlocked, ['first_book', 'xp_500']);
      expect(c.read(userStatsProvider).value!.xp, 480 + 25 + 50);
    });

    test('the daily cap resets on a new day', () async {
      final c = await containerWith({'xp': 200, 'level': 3, 'xpEarnedToday': 200, 'lastXPDate': _day(-1)});
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 80);
      expect(c.read(userStatsProvider).value!.xp, 200 + 80 + 25); // + First Steps reward
    });

    test('reading on consecutive days grows the streak', () async {
      final c = await containerWith({'streakDays': 2, 'lastSessionDate': _day(-1)});
      final unlocked = await c.read(userStatsProvider.notifier).completeSession(xpEarned: 10);
      expect(c.read(userStatsProvider).value!.streakDays, 3);
      expect(unlocked, contains('streak_3'));
      expect(c.read(userStatsProvider).value!.xp, 10 + 25 + 75); // + First Steps + 3-day streak
    });

    test('a second session on the same day does not grow the streak', () async {
      final c = await containerWith({'streakDays': 4, 'lastSessionDate': _day(0)});
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 10);
      expect(c.read(userStatsProvider).value!.streakDays, 4);
    });

    test('missing a day resets the streak to 1', () async {
      final c = await containerWith({'streakDays': 9, 'lastSessionDate': _day(-2)});
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 10);
      expect(c.read(userStatsProvider).value!.streakDays, 1);
    });

    test('achievements are only awarded once', () async {
      final c = await containerWith();
      final n = c.read(userStatsProvider.notifier);
      expect(await n.completeSession(xpEarned: 10), contains('first_session'));
      expect(await n.completeSession(xpEarned: 10), isNot(contains('first_session')));
    });

    test('starting and finishing books', () async {
      final c = await containerWith();
      final n = c.read(userStatsProvider.notifier);
      await n.recordBookStarted();
      await n.recordBookFinished();
      final s = c.read(userStatsProvider).value!;
      expect(s.totalBooksStarted, 1);
      expect(s.totalBooksFinished, 1);
      // 25 (First Book) + 200 finish bonus + 200 (Book Finished) = 425 → level 5,
      // which unlocks Level 5 (+100) → 525 → Knowledge Seeker (+50) → 575.
      expect(s.xp, 575);
      expect(s.earnedAchievementIds, containsAll(['first_book', 'book_finished', 'level_5', 'xp_500']));
    });

    test('stats persist across app restarts', () async {
      final c = await containerWith();
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 40);
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect((await c2.read(userStatsProvider.future)).xp, 40 + 25); // + First Steps reward
    });

    test('corrupt saved stats fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({'booklify_user_stats_v2': '{not json'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect((await c.read(userStatsProvider.future)).xp, 0);
    });

    test('every achievement the notifier can award has a definition', () {
      const awarded = [
        'first_session', 'sessions_5', 'sessions_10', 'sessions_25', 'streak_3', 'streak_7',
        'streak_14', 'level_5', 'level_10', 'first_book', 'books_3', 'book_finished', 'xp_500', 'xp_1000',
      ];
      final defined = kAllAchievements.map((a) => a.id).toSet();
      expect(defined, containsAll(awarded));
    });
  });

  group('AuthNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<ProviderContainer> start() async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(authProvider, (_, __) {});
      await _settle();
      return c;
    }

    test('starts unauthenticated with no saved user', () async {
      final c = await start();
      expect(c.read(authStatusProvider), AuthStatus.unauthenticated);
    });

    test('sign up → authenticated, sign out → unauthenticated, sign in → authenticated', () async {
      final c = await start();
      final email = '${const Uuid().v4()}@t.dev';
      final n = c.read(authProvider.notifier);

      await n.signUp(email: email, password: 'pw123456', displayName: 'Ann');
      expect(c.read(authStatusProvider), AuthStatus.authenticated);
      expect(c.read(authUserProvider)?.displayName, 'Ann');

      await n.signOut();
      expect(c.read(authStatusProvider), AuthStatus.unauthenticated);
      expect(c.read(authUserProvider), isNull);

      await n.signIn(email: email, password: 'pw123456');
      expect(c.read(isAuthenticatedProvider), isTrue);
    });

    test('a saved session is restored on app start', () async {
      final c = await start();
      await c.read(authProvider.notifier)
          .signUp(email: '${const Uuid().v4()}@t.dev', password: 'pw', displayName: 'Bo');
      final c2 = await start();
      expect(c2.read(authStatusProvider), AuthStatus.authenticated);
      expect(c2.read(authUserProvider)?.displayName, 'Bo');
    });

    test('bad credentials give an error state with a message', () async {
      final c = await start();
      await c.read(authProvider.notifier).signIn(email: 'nobody@t.dev', password: 'x');
      expect(c.read(authStatusProvider), AuthStatus.error);
      expect(c.read(authProvider).errorMessage, contains('Invalid email or password'));
    });

    test('clearError() clears the error message', () async {
      final c = await start();
      final n = c.read(authProvider.notifier);
      await n.signIn(email: 'nobody@t.dev', password: 'x');
      n.clearError();
      expect(c.read(authProvider).errorMessage, isNull);
    });

    test('error messages are shown without the "Exception:" prefix', () async {
      final c = await start();
      await c.read(authProvider.notifier).signIn(email: 'nobody@t.dev', password: 'x');
      expect(c.read(authProvider).errorMessage, 'Invalid email or password.');
    });

    test('a successful sign-in after a failure clears the old error', () async {
      final c = await start();
      final email = '${const Uuid().v4()}@t.dev';
      final n = c.read(authProvider.notifier);
      await n.signUp(email: email, password: 'pw123456', displayName: 'Ann');
      await n.signOut();
      await n.signIn(email: email, password: 'wrong');
      await n.signIn(email: email, password: 'pw123456');
      expect(c.read(authStatusProvider), AuthStatus.authenticated);
      expect(c.read(authProvider).errorMessage, isNull);
    });
  });

  group('Library feeds reading achievements', () {
    BookChunk day(int n) => BookChunk(
          id: 'day-$n',
          dayNumber: n,
          episodeTitle: 'Day $n',
          keyIdea: '',
          preview: '',
          difficulty: Difficulty.light,
          estimatedMinutes: 5,
          startOffset: 0,
          endOffset: 0,
        );

    test('adding a book counts as started; finishing its last day counts once', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(authProvider, (_, __) {});
      await _settle();
      await c.read(authProvider.notifier)
          .signUp(email: '${const Uuid().v4()}@t.dev', password: 'pw123456', displayName: 'Ann');
      await c.read(userStatsProvider.future);

      final book = Book(
        id: const Uuid().v4(),
        title: 'Dune',
        author: 'Frank Herbert',
        totalPages: 10,
        content: 'text',
        uploadDate: DateTime.now(),
        chunks: [day(1), day(2)],
      );
      final books = c.read(booksProvider.notifier);
      await books.addBook(book);
      expect(c.read(userStatsProvider).value!.totalBooksStarted, 1);
      expect(c.read(userStatsProvider).value!.earnedAchievementIds, contains('first_book'));

      await c.read(booksProvider.future);
      expect(await books.markChunkComplete(book.id, 'day-1'), isEmpty);
      expect(c.read(userStatsProvider).value!.totalBooksFinished, 0);

      await c.read(booksProvider.future);
      expect(await books.markChunkComplete(book.id, 'day-2'), contains('book_finished'));
      expect(c.read(userStatsProvider).value!.totalBooksFinished, 1);

      await c.read(booksProvider.future);
      await books.markChunkComplete(book.id, 'day-2'); // re-reading the last day
      expect(c.read(userStatsProvider).value!.totalBooksFinished, 1);
    });
  });

  group('LocaleNotifier', () {
    test('defaults to English', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(localeProvider), const Locale('en'));
    });

    test('setLocale switches language and persists it', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(localeProvider.notifier).setLocale(const Locale('uz'));
      expect(c.read(localeProvider), const Locale('uz'));

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(localeProvider);
      await _settle();
      expect(c2.read(localeProvider), const Locale('uz'));
    });

    test('offers en, ru and uz', () {
      expect(supportedAppLocales.map((l) => l.locale.languageCode), ['en', 'ru', 'uz']);
    });
  });
}
