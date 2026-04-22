import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress.dart';
import '../../data/models/book.dart';
import '../../widgets/garden/tree_painter.dart';
import 'auth_provider.dart';

// ─── Current Book Provider ────────────────────────────────────────────────────
// Set by LibraryScreen when user picks a book.

class CurrentBookNotifier extends Notifier<Book?> {
  @override
  Book? build() => null;

  void setBook(Book? book) => state = book;
}

final currentBookProvider =
    NotifierProvider<CurrentBookNotifier, Book?>(() => CurrentBookNotifier());

// ─── Books List Provider ──────────────────────────────────────────────────────

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final user = ref.watch(authUserProvider);
    if (user == null) return [];
    final db = ref.read(databaseServiceProvider);
    return await db.getBooks(user.id);
  }

  Future<void> addBook(Book book) async {
    final user = ref.read(authUserProvider);
    if (user == null) return;
    final db = ref.read(databaseServiceProvider);
    await db.saveBook(book, user.id);
    ref.invalidateSelf();
  }

  Future<void> updateChunks(String bookId, List<BookChunk> chunks) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateBookChunks(bookId, chunks);
    ref.invalidateSelf();
  }

  Future<void> deleteBook(String bookId) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteBook(bookId);
    ref.invalidateSelf();
  }

  Book? getActiveBook() {
    final books = state.value ?? [];
    if (books.isEmpty) return null;
    Book? bestBook;
    DateTime? bestDate;
    for (final book in books) {
      final completed =
          book.chunks.where((c) => c.completed && c.completedDate != null);
      if (completed.isEmpty) {
        bestBook ??= book;
        continue;
      }
      final latest = completed
          .map((c) => c.completedDate!)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (bestDate == null || latest.isAfter(bestDate)) {
        bestDate = latest;
        bestBook = book;
      }
    }
    return bestBook ??
        books.firstWhere((b) => b.chunks.isNotEmpty,
            orElse: () => books.first);
  }

  Future<void> markChunkComplete(String bookId, String chunkId) async {
    final books = state.value ?? [];
    final bookIndex = books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return;

    final book = books[bookIndex];
    final updatedChunks = book.chunks.map((c) {
      if (c.id == chunkId && !c.completed) {
        return c.copyWith(completed: true, completedDate: DateTime.now());
      }
      return c;
    }).toList();

    final db = ref.read(databaseServiceProvider);
    await db.updateBookChunks(bookId, updatedChunks);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final booksProvider =
    AsyncNotifierProvider<BooksNotifier, List<Book>>(() => BooksNotifier());

// ─── Progress Provider ────────────────────────────────────────────────────────

class ProgressNotifier extends AsyncNotifier<Progress?> {
  @override
  Future<Progress?> build() async {
    final user = ref.watch(authUserProvider);
    final book = ref.watch(currentBookProvider);
    if (user == null || book == null) return null;
    final db = ref.read(databaseServiceProvider);
    return await db.getOrCreateProgress(user.id, book.id,
        totalDays: book.chunks.isNotEmpty ? book.chunks.length : 30);
  }

  Future<void> completeDay() async {
    final current = state.value;
    if (current == null) return;

    final updated = current.completeDay();
    final db = ref.read(databaseServiceProvider);
    await db.saveProgress(updated);
    state = AsyncData(updated);

    // Check achievements
    final user = ref.read(authUserProvider);
    if (user != null) {
      await db.checkAndUnlockAchievements(user.id, updated);
    }
  }

  Future<void> addXP(int amount) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.addXP(amount);
    final db = ref.read(databaseServiceProvider);
    await db.saveProgress(updated);
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, Progress?>(() => ProgressNotifier());

// ─── Garden Weather Provider ──────────────────────────────────────────────────

final gardenWeatherProvider = Provider<GardenWeather>((ref) {
  final progressAsync = ref.watch(progressProvider);

  return progressAsync.when(
    data: (progress) {
      if (progress == null || progress.completedDays.isEmpty) {
        return GardenWeather.cloudy;
      }
      final lastReadDate =
          DateTime.tryParse(progress.completedDays.last);
      if (lastReadDate == null) return GardenWeather.cloudy;

      final daysSince = DateTime.now().difference(lastReadDate).inDays;
      if (daysSince == 0) return GardenWeather.sunny;
      if (daysSince == 1) return GardenWeather.cloudy;
      return GardenWeather.stormy;
    },
    loading: () => GardenWeather.cloudy,
    error: (_, __) => GardenWeather.cloudy,
  );
});

// ─── Daily Challenge Provider ─────────────────────────────────────────────────

final dailyChallengeProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return {};
  final db = ref.read(databaseServiceProvider);
  return await db.getDailyChallenge(user.id);
});
