import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress.dart';
import '../../data/models/book.dart';
import '../../widgets/garden/tree_painter.dart';
import 'user_stats_provider.dart';

// ─── Progress derived from real UserStats ────────────────────────────────────

final progressProvider = Provider<Progress?>((ref) {
  final stats = ref.watch(userStatsProvider).valueOrNull;
  if (stats == null) return null;
  // Show "empty garden" state even with no sessions so the tree paints
  return Progress(
    id: 'global',
    userId: '',
    bookId: '',
    currentDay: stats.totalSessionsCompleted,
    totalDays: stats.totalBooksStarted > 0 ? stats.totalBooksStarted * 7 : 7,
    completedDays: stats.sessionDates,
    xp: stats.xp,
    level: stats.level,
    streakDays: stats.streakDays,
    lastSessionDate: stats.lastSessionDate != null
        ? DateTime.tryParse(stats.lastSessionDate!)
        : null,
  );
});

// ─── Current book (used by garden to preview today's reading) ────────────────

final currentBookProvider = StateProvider<Book?>((ref) => null);

// ─── Garden weather based on last session date ───────────────────────────────

final gardenWeatherProvider = Provider<GardenWeather>((ref) {
  final stats = ref.watch(userStatsProvider).valueOrNull;
  if (stats == null || stats.lastSessionDate == null) return GardenWeather.cloudy;

  final lastDate = DateTime.tryParse(stats.lastSessionDate!);
  if (lastDate == null) return GardenWeather.cloudy;

  final days = DateTime.now().difference(lastDate).inDays;
  if (days == 0) return GardenWeather.sunny;
  if (days <= 1) return GardenWeather.cloudy;
  return GardenWeather.stormy;
});

// ─── Legacy notifiers (kept for backward compat — not used for persistence) ──

class ProgressNotifier extends StateNotifier<Progress?> {
  ProgressNotifier() : super(null);
  void updateProgress(Progress p) => state = p;
  void completeDay(Progress p) => state = p.completeDay();
}

class BookNotifier extends StateNotifier<Book?> {
  BookNotifier() : super(null);
  void setCurrentBook(Book b) => state = b;
  void updateBook(Book b) => state = b;
}

final progressNotifierProvider =
    StateNotifierProvider<ProgressNotifier, Progress?>(
        (ref) => ProgressNotifier());

final bookNotifierProvider =
    StateNotifierProvider<BookNotifier, Book?>(
        (ref) => BookNotifier());
