import 'dart:convert';

import 'package:booklify/presentation/providers/user_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _day(int ago) => DateTime.now()
    .subtract(Duration(days: ago))
    .toIso8601String()
    .split('T')
    .first;

Future<ProviderContainer> _container([UserStats? initial]) async {
  SharedPreferences.setMockInitialValues({
    if (initial != null)
      'booklify_user_stats_v2': jsonEncode(initial.toJson()),
  });
  final c = ProviderContainer();
  addTearDown(c.dispose);
  await c.read(userStatsProvider.future);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStatsNotifier', () {
    test('first session: XP, streak 1, first_session achievement', () async {
      final c = await _container();
      final ids = await c
          .read(userStatsProvider.notifier)
          .completeSession(xpEarned: 30);
      final s = c.read(userStatsProvider).value!;
      expect(s.xp, 30);
      expect(s.streakDays, 1);
      expect(s.totalSessionsCompleted, 1);
      expect(ids, ['first_session']);
    });

    test('daily XP is capped at 200', () async {
      final c = await _container();
      final n = c.read(userStatsProvider.notifier);
      await n.completeSession(xpEarned: 150);
      await n.completeSession(xpEarned: 150);
      await n.completeSession(xpEarned: 150);
      final s = c.read(userStatsProvider).value!;
      expect(s.xp, UserStatsNotifier.kDailyXPCap);
      expect(s.xpEarnedToday, 200);
    });

    test('cap resets on a new day', () async {
      final c = await _container(UserStats(
          xp: 200, level: 3, xpEarnedToday: 200, lastXPDate: _day(1)));
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 50);
      expect(c.read(userStatsProvider).value!.xp, 250);
    });

    test('streak continues from yesterday, resets after a gap, '
        'is unchanged on the same day', () async {
      var c = await _container(
          UserStats(streakDays: 2, lastSessionDate: _day(1)));
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 1);
      expect(c.read(userStatsProvider).value!.streakDays, 3);
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 1);
      expect(c.read(userStatsProvider).value!.streakDays, 3);

      c = await _container(
          UserStats(streakDays: 9, lastSessionDate: _day(3)));
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 1);
      expect(c.read(userStatsProvider).value!.streakDays, 1);
    });

    test('streak_3 unlocks on the third consecutive day', () async {
      final c = await _container(UserStats(
          streakDays: 2, lastSessionDate: _day(1),
          totalSessionsCompleted: 2, earnedAchievementIds: ['first_session']));
      final ids = await c
          .read(userStatsProvider.notifier)
          .completeSession(xpEarned: 10);
      expect(ids, contains('streak_3'));
      expect(ids, isNot(contains('first_session')));
    });

    test('book started / finished counters and achievements', () async {
      final c = await _container();
      final n = c.read(userStatsProvider.notifier);
      await n.recordBookStarted();
      await n.recordBookFinished();
      final s = c.read(userStatsProvider).value!;
      expect(s.totalBooksStarted, 1);
      expect(s.totalBooksFinished, 1);
      expect(s.xp, 200);
      expect(s.earnedAchievementIds, containsAll(['first_book',
          'book_finished']));
    });

    test('stats persist across app restarts', () async {
      final c = await _container();
      await c.read(userStatsProvider.notifier).completeSession(xpEarned: 40);
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect((await c2.read(userStatsProvider.future)).xp, 40);
    });

    test('corrupt stored stats fall back to defaults', () async {
      SharedPreferences.setMockInitialValues(
          {'booklify_user_stats_v2': '{oops'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect((await c.read(userStatsProvider.future)).xp, 0);
    });

    test('every achievement id checked has a definition', () {
      final ids = kAllAchievements.map((a) => a.id).toSet();
      expect(ids.length, kAllAchievements.length);
      expect(ids, containsAll(['first_session', 'streak_3', 'level_5',
          'first_book', 'book_finished', 'xp_1000']));
    });
  });
}
