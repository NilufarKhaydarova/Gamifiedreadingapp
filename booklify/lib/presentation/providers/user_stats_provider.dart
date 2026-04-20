import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class UserStats {
  final int xp;
  final int level;
  final int streakDays;
  final int totalSessionsCompleted;
  final int totalBooksStarted;
  final int totalBooksFinished;
  final String? lastSessionDate; // "YYYY-MM-DD"
  final List<String> sessionDates; // all unique dates with sessions
  final List<String> earnedAchievementIds;

  // ── Daily XP cap fields ──────────────────────────────────────────────────
  final int xpEarnedToday; // resets each new calendar day
  final String? lastXPDate; // "YYYY-MM-DD" of last XP grant

  const UserStats({
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.totalSessionsCompleted = 0,
    this.totalBooksStarted = 0,
    this.totalBooksFinished = 0,
    this.lastSessionDate,
    this.sessionDates = const [],
    this.earnedAchievementIds = const [],
    this.xpEarnedToday = 0,
    this.lastXPDate,
  });

  int get xpToNextLevel => level * 100;
  double get levelProgress =>
      xp > 0 ? ((xp % 100) / 100.0).clamp(0.0, 1.0) : 0.0;

  UserStats copyWith({
    int? xp,
    int? level,
    int? streakDays,
    int? totalSessionsCompleted,
    int? totalBooksStarted,
    int? totalBooksFinished,
    String? lastSessionDate,
    List<String>? sessionDates,
    List<String>? earnedAchievementIds,
    int? xpEarnedToday,
    String? lastXPDate,
  }) =>
      UserStats(
        xp: xp ?? this.xp,
        level: level ?? this.level,
        streakDays: streakDays ?? this.streakDays,
        totalSessionsCompleted:
            totalSessionsCompleted ?? this.totalSessionsCompleted,
        totalBooksStarted: totalBooksStarted ?? this.totalBooksStarted,
        totalBooksFinished: totalBooksFinished ?? this.totalBooksFinished,
        lastSessionDate: lastSessionDate ?? this.lastSessionDate,
        sessionDates: sessionDates ?? this.sessionDates,
        earnedAchievementIds:
            earnedAchievementIds ?? this.earnedAchievementIds,
        xpEarnedToday: xpEarnedToday ?? this.xpEarnedToday,
        lastXPDate: lastXPDate ?? this.lastXPDate,
      );

  UserStats withXP(int added) {
    final newXP = xp + added;
    final newLevel = (newXP ~/ 100) + 1;
    return copyWith(xp: newXP, level: newLevel);
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'streakDays': streakDays,
        'totalSessionsCompleted': totalSessionsCompleted,
        'totalBooksStarted': totalBooksStarted,
        'totalBooksFinished': totalBooksFinished,
        'lastSessionDate': lastSessionDate,
        'sessionDates': sessionDates,
        'earnedAchievementIds': earnedAchievementIds,
        'xpEarnedToday': xpEarnedToday,
        'lastXPDate': lastXPDate,
      };

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        xp: j['xp'] as int? ?? 0,
        level: j['level'] as int? ?? 1,
        streakDays: j['streakDays'] as int? ?? 0,
        totalSessionsCompleted: j['totalSessionsCompleted'] as int? ?? 0,
        totalBooksStarted: j['totalBooksStarted'] as int? ?? 0,
        totalBooksFinished: j['totalBooksFinished'] as int? ?? 0,
        lastSessionDate: j['lastSessionDate'] as String?,
        sessionDates: (j['sessionDates'] as List?)?.cast<String>() ?? [],
        earnedAchievementIds:
            (j['earnedAchievementIds'] as List?)?.cast<String>() ?? [],
        xpEarnedToday: j['xpEarnedToday'] as int? ?? 0,
        lastXPDate: j['lastXPDate'] as String?,
      );
}

// ─── All achievement definitions ─────────────────────────────────────────────

class AchievementDef {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int xpReward;
  final String category; // streak | sessions | level | books | xp

  const AchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.category,
  });
}

const kAllAchievements = [
  AchievementDef(
    id: 'first_session',
    emoji: '🌱',
    title: 'First Steps',
    description: 'Complete your first reading session',
    xpReward: 25,
    category: 'sessions',
  ),
  AchievementDef(
    id: 'sessions_5',
    emoji: '📖',
    title: 'Page Turner',
    description: 'Complete 5 reading sessions',
    xpReward: 50,
    category: 'sessions',
  ),
  AchievementDef(
    id: 'sessions_10',
    emoji: '📚',
    title: 'Bookworm',
    description: 'Complete 10 reading sessions',
    xpReward: 100,
    category: 'sessions',
  ),
  AchievementDef(
    id: 'sessions_25',
    emoji: '🎓',
    title: 'Scholar',
    description: 'Complete 25 reading sessions',
    xpReward: 200,
    category: 'sessions',
  ),
  AchievementDef(
    id: 'streak_3',
    emoji: '🔥',
    title: 'On Fire',
    description: 'Read 3 days in a row',
    xpReward: 75,
    category: 'streak',
  ),
  AchievementDef(
    id: 'streak_7',
    emoji: '⚡',
    title: 'Week Warrior',
    description: 'Read 7 days in a row',
    xpReward: 150,
    category: 'streak',
  ),
  AchievementDef(
    id: 'streak_14',
    emoji: '🌟',
    title: 'Fortnight Focus',
    description: 'Read 14 days in a row',
    xpReward: 300,
    category: 'streak',
  ),
  AchievementDef(
    id: 'level_5',
    emoji: '🏅',
    title: 'Rising Reader',
    description: 'Reach Level 5',
    xpReward: 100,
    category: 'level',
  ),
  AchievementDef(
    id: 'level_10',
    emoji: '💎',
    title: 'Diamond Mind',
    description: 'Reach Level 10',
    xpReward: 250,
    category: 'level',
  ),
  AchievementDef(
    id: 'first_book',
    emoji: '📕',
    title: 'Collector',
    description: 'Add your first book to the library',
    xpReward: 25,
    category: 'books',
  ),
  AchievementDef(
    id: 'books_3',
    emoji: '🗃️',
    title: 'Curator',
    description: 'Add 3 books to your library',
    xpReward: 75,
    category: 'books',
  ),
  AchievementDef(
    id: 'book_finished',
    emoji: '🏆',
    title: 'Finisher',
    description: 'Complete all chapters of a book',
    xpReward: 200,
    category: 'books',
  ),
  AchievementDef(
    id: 'xp_500',
    emoji: '✨',
    title: 'Knowledge Seeker',
    description: 'Earn 500 total XP',
    xpReward: 50,
    category: 'xp',
  ),
  AchievementDef(
    id: 'xp_1000',
    emoji: '👑',
    title: 'Master Reader',
    description: 'Earn 1000 total XP',
    xpReward: 100,
    category: 'xp',
  ),
];

// ─── Notifier ─────────────────────────────────────────────────────────────────

class UserStatsNotifier extends AsyncNotifier<UserStats> {
  static const _prefsKey = 'booklify_user_stats_v2';

  /// Maximum XP that can be earned in a single calendar day.
  static const int kDailyXPCap = 200;

  @override
  Future<UserStats> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const UserStats();
    try {
      return UserStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserStats();
    }
  }

  /// Called when a reading session is completed.
  /// XP is capped at [kDailyXPCap] per calendar day.
  /// Returns newly unlocked achievement ids so the UI can celebrate.
  Future<List<String>> completeSession({required int xpEarned}) async {
    final current = state.valueOrNull ?? const UserStats();
    final today = _today();

    // ── Daily XP cap ─────────────────────────────────────────────────────
    final int todayAccumulated;
    if (current.lastXPDate == null || current.lastXPDate != today) {
      // New day — reset the daily counter
      todayAccumulated = 0;
    } else {
      todayAccumulated = current.xpEarnedToday;
    }

    final remaining = math.max(0, kDailyXPCap - todayAccumulated);
    final cappedXP = math.min(xpEarned, remaining);

    // ── Session dates & streak ────────────────────────────────────────────
    final dates = List<String>.from(current.sessionDates);
    if (!dates.contains(today)) dates.add(today);

    int streak = current.streakDays;
    if (current.lastSessionDate == null) {
      streak = 1;
    } else if (current.lastSessionDate == today) {
      // Already counted today — don't change streak
    } else if (current.lastSessionDate == _daysAgo(1)) {
      streak = current.streakDays + 1;
    } else {
      streak = 1; // Broken streak — start over
    }

    // ── Apply capped XP ───────────────────────────────────────────────────
    final afterXP = current
        .withXP(cappedXP)
        .copyWith(
          streakDays: streak,
          totalSessionsCompleted: current.totalSessionsCompleted + 1,
          lastSessionDate: today,
          sessionDates: dates,
          xpEarnedToday: todayAccumulated + cappedXP,
          lastXPDate: today,
        );

    final newIds = _checkAchievements(afterXP, current.earnedAchievementIds);
    final saved = afterXP.copyWith(
      earnedAchievementIds: [
        ...current.earnedAchievementIds,
        ...newIds,
      ],
    );

    state = AsyncData(saved);
    await _persist(saved);
    return newIds;
  }

  Future<void> recordBookStarted() async {
    final current = state.valueOrNull ?? const UserStats();
    final updated =
        current.copyWith(totalBooksStarted: current.totalBooksStarted + 1);
    final newIds = _checkAchievements(updated, current.earnedAchievementIds);
    final saved = updated.copyWith(
        earnedAchievementIds: [...current.earnedAchievementIds, ...newIds]);
    state = AsyncData(saved);
    await _persist(saved);
  }

  Future<void> recordBookFinished() async {
    final current = state.valueOrNull ?? const UserStats();
    // Book-finish XP is a bonus — also subject to daily cap
    final today = _today();
    final todayAccumulated = (current.lastXPDate == today)
        ? current.xpEarnedToday
        : 0;
    final remaining = math.max(0, kDailyXPCap - todayAccumulated);
    const bookFinishBonus = 200;
    final cappedBonus = math.min(bookFinishBonus, remaining);

    final updated = current
        .withXP(cappedBonus)
        .copyWith(
          totalBooksFinished: current.totalBooksFinished + 1,
          xpEarnedToday: todayAccumulated + cappedBonus,
          lastXPDate: today,
        );
    final newIds = _checkAchievements(updated, current.earnedAchievementIds);
    final saved = updated.copyWith(
        earnedAchievementIds: [...current.earnedAchievementIds, ...newIds]);
    state = AsyncData(saved);
    await _persist(saved);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  List<String> _checkAchievements(
      UserStats s, List<String> alreadyEarned) {
    final newIds = <String>[];
    void check(String id, bool condition) {
      if (condition && !alreadyEarned.contains(id)) newIds.add(id);
    }

    check('first_session', s.totalSessionsCompleted >= 1);
    check('sessions_5', s.totalSessionsCompleted >= 5);
    check('sessions_10', s.totalSessionsCompleted >= 10);
    check('sessions_25', s.totalSessionsCompleted >= 25);
    check('streak_3', s.streakDays >= 3);
    check('streak_7', s.streakDays >= 7);
    check('streak_14', s.streakDays >= 14);
    check('level_5', s.level >= 5);
    check('level_10', s.level >= 10);
    check('first_book', s.totalBooksStarted >= 1);
    check('books_3', s.totalBooksStarted >= 3);
    check('book_finished', s.totalBooksFinished >= 1);
    check('xp_500', s.xp >= 500);
    check('xp_1000', s.xp >= 1000);
    return newIds;
  }

  Future<void> _persist(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(stats.toJson()));
  }

  static String _today() =>
      DateTime.now().toIso8601String().split('T')[0];

  static String _daysAgo(int n) =>
      DateTime.now()
          .subtract(Duration(days: n))
          .toIso8601String()
          .split('T')[0];
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final userStatsProvider =
    AsyncNotifierProvider<UserStatsNotifier, UserStats>(
        () => UserStatsNotifier());
