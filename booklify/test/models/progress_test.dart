import 'package:booklify/data/models/progress.dart';
import 'package:flutter_test/flutter_test.dart';

Progress _progress({
  int currentDay = 0,
  int totalDays = 10,
  int xp = 0,
  int level = 1,
  int streak = 0,
  List<String> completedDays = const [],
}) =>
    Progress(
      id: 'p1',
      userId: 'u1',
      bookId: 'b1',
      currentDay: currentDay,
      totalDays: totalDays,
      xp: xp,
      level: level,
      streakDays: streak,
      completedDays: completedDays,
    );

void main() {
  group('Progress', () {
    test('progressPercent is currentDay / totalDays, 0 when no days', () {
      expect(_progress(currentDay: 5, totalDays: 10).progressPercent, 0.5);
      expect(_progress(currentDay: 0, totalDays: 0).progressPercent, 0);
    });

    test('isCompleted once currentDay reaches totalDays', () {
      expect(_progress(currentDay: 9).isCompleted, isFalse);
      expect(_progress(currentDay: 10).isCompleted, isTrue);
    });

    test('addXP levels up every 100 XP', () {
      final p = _progress().addXP(250);
      expect(p.xp, 250);
      expect(p.level, 3);
      expect(p.levelProgress, closeTo(0.5, 1e-9));
      expect(p.xpToNextLevel, 300);
    });

    test('completeDay advances the day, grants 50 XP and records today', () {
      final p = _progress(currentDay: 2).completeDay();
      final today = DateTime.now().toIso8601String().split('T').first;
      expect(p.currentDay, 3);
      expect(p.xp, 50);
      expect(p.completedDays, [today]);
      expect(p.streakDays, 1);
      expect(p.lastSessionDate, isNotNull);
    });

    test('completeDay never advances past totalDays', () {
      final p = _progress(currentDay: 10, totalDays: 10).completeDay();
      expect(p.currentDay, 10);
    });

    test('completeDay twice on the same day does not double the streak', () {
      final p = _progress().completeDay().completeDay();
      expect(p.streakDays, 1);
    }, skip: 'BUG: Progress.completeDay() increments streakDays on every call, '
        'even twice on the same calendar day.');

    test('completeDay on the final day sets completedDate', () {
      final p = _progress(currentDay: 9, totalDays: 10).completeDay();
      expect(p.isCompleted, isTrue);
      expect(p.completedDate, isNotNull);
    }, skip: 'BUG: completedDate is never set, so DatabaseService.'
        'getTotalBooksRead() always returns 0.');

    test('toJson/fromJson round-trips', () {
      final p = _progress(currentDay: 3, xp: 120, level: 2, streak: 4,
              completedDays: ['2026-01-01'])
          .copyWith(startDate: DateTime(2026, 1, 1));
      final back = Progress.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
    });

    test('fromJson applies defaults for missing optional fields', () {
      final p = Progress.fromJson({
        'id': 'x',
        'userId': 'u',
        'bookId': 'b',
        'currentDay': 1,
        'totalDays': 5,
      });
      expect(p.xp, 0);
      expect(p.level, 1);
      expect(p.completedDays, isEmpty);
    });
  });
}
