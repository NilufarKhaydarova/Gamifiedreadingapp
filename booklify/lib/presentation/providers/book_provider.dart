import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book.dart';
import '../../data/services/database_service.dart';
import '../../data/services/claude_service.dart';
import 'auth_provider.dart';
import 'user_stats_provider.dart';

// ─── Service Providers ────────────────────────────────────────────────────────

final _claudeServiceProvider =
    Provider<ClaudeService>((ref) => ClaudeService());

// ─── Books Notifier ───────────────────────────────────────────────────────────

class BooksNotifier extends AsyncNotifier<List<Book>> {
  DatabaseService get _db => ref.read(databaseServiceProvider);
  ClaudeService get _claude => ref.read(_claudeServiceProvider);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Book>> build() async {
    final user = ref.watch(authProvider).user;
    if (user == null) return [];
    return _loadBooks(user.id);
  }

  Future<List<Book>> _loadBooks(String userId) async {
    return _db.getBooks(userId);
  }

  // ── Active book ────────────────────────────────────────────────────────────

  /// Returns the book that was most recently interacted with.
  /// Heuristic: the book whose last completed chunk has the most recent
  /// completedDate, or if no chunks are completed, the first book in the list.
  Book? getActiveBook() {
    final books = state.valueOrNull ?? [];
    if (books.isEmpty) return null;

    Book? bestBook;
    DateTime? bestDate;

    for (final book in books) {
      final completed =
          book.chunks.where((c) => c.completed && c.completedDate != null);
      if (completed.isEmpty) {
        // Book has been added but not yet started — eligible as fallback
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

    // If nothing has been completed, return first book with chunks, else first
    return bestBook ??
        books.firstWhere((b) => b.chunks.isNotEmpty,
            orElse: () => books.first);
  }

  // ── prepareForReadingWithGoals ─────────────────────────────────────────────
  // Smart Chunking Engine: uses actual book content + user preferences.

  Future<Book> prepareForReadingWithGoals(
      {required String bookId,
      required String goal,
      required int days,
      required int minutesPerDay}) async {
    final current = state.valueOrNull ?? [];
    final book = current.firstWhere((b) => b.id == bookId);

    List<BookChunk> chunks;
    if (book.content.isNotEmpty) {
      // Use the Smart Chunking Engine with full content
      chunks = await _claude.generateSmartChunks(
        bookTitle: book.title,
        bookAuthor: book.author,
        bookContent: book.content,
        totalDays: days,
        userGoal: goal,
        minutesPerDay: minutesPerDay,
      );
    } else {
      // No text — fall back to knowledge-based reading plan
      chunks = await _claude.generateReadingPlan(
        title: book.title,
        author: book.author,
        totalDays: days,
      );
    }

    await _db.updateBookChunks(bookId, chunks);

    final updatedBook = book.copyWith(chunks: chunks);
    state = AsyncData(
        current.map((b) => b.id == bookId ? updatedBook : b).toList());

    return updatedBook;
  }

  // ── prepareForReading (fallback, no goal params) ───────────────────────────

  /// Returns the book ready to read.
  /// If no content is available, Claude generates an educational 7-day guide.
  Future<Book> prepareForReading(String bookId) async {
    final current = state.valueOrNull ?? [];
    final book = current.firstWhere((b) => b.id == bookId);
    if (book.chunks.isNotEmpty) return book;

    List<BookChunk> chunks;
    if (book.content.isNotEmpty) {
      // User provided real text — split into 7 days (no AI needed)
      chunks = _chunksFromText(book.content, book.title);
    } else {
      // No text — Claude generates an educational 7-day guide
      chunks = await _claude.generateReadingPlan(
        title: book.title,
        author: book.author,
        totalDays: 7,
      );
    }

    await _db.updateBookChunks(bookId, chunks);

    final updatedBook = book.copyWith(chunks: chunks);
    state = AsyncData(
        current.map((b) => b.id == bookId ? updatedBook : b).toList());

    // Record that a book was started (for achievements)
    await ref.read(userStatsProvider.notifier).recordBookStarted();

    return updatedBook;
  }

  /// Creates day-by-day chunks from actual book text without AI.
  List<BookChunk> _chunksFromText(String content, String title,
      {int days = 7}) {
    final paragraphs = content
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      final lines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      return _chunksFromText(lines.join('\n\n'), title, days: days);
    }

    final parasPerDay =
        (paragraphs.length / days).ceil().clamp(1, paragraphs.length);
    final chunks = <BookChunk>[];
    int charOffset = 0;

    for (int day = 0; day < days; day++) {
      final start = day * parasPerDay;
      if (start >= paragraphs.length) break;
      final end =
          (start + parasPerDay).clamp(0, paragraphs.length);
      final dayParas = paragraphs.sublist(start, end);
      final dayText = dayParas.join('\n\n');

      final subChunks = dayParas.asMap().entries.map((e) {
        return SubChunk(
          id: 'sub-${day + 1}-${e.key}',
          content: e.value,
          type: e.value.split(' ').length > 300
              ? ChunkType.chapter
              : ChunkType.section,
          wordCount: e.value.split(' ').length,
        );
      }).toList();

      final firstWords =
          dayParas.first.split(' ').take(6).join(' ').replaceAll('\n', ' ');
      final preview = dayParas.first.length > 120
          ? '${dayParas.first.substring(0, 120)}…'
          : dayParas.first;

      chunks.add(BookChunk(
        id: 'day-${day + 1}',
        dayNumber: day + 1,
        episodeTitle: 'Day ${day + 1} — $firstWords',
        keyIdea: '',
        preview: preview,
        difficulty: Difficulty.moderate,
        estimatedMinutes:
            (dayText.split(' ').length / 220).ceil().clamp(5, 90),
        startOffset: charOffset,
        endOffset: charOffset + dayText.length,
        subChunks: subChunks,
        glossary: const {},
      ));
      charOffset += dayText.length;
    }

    return chunks;
  }

  // ── Chunk progress ─────────────────────────────────────────────────────────

  /// Mark a specific chunk as completed and persist to DB.
  Future<void> markChunkComplete(String bookId, String chunkId) async {
    final current = state.valueOrNull ?? [];
    final bookIndex = current.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return;

    final book = current[bookIndex];
    final updatedChunks = book.chunks.map((c) {
      if (c.id == chunkId && !c.completed) {
        return c.copyWith(
            completed: true, completedDate: DateTime.now());
      }
      return c;
    }).toList();

    await _db.updateBookChunks(bookId, updatedChunks);

    final updatedBook = book.copyWith(chunks: updatedChunks);
    final updatedList = List<Book>.from(current);
    updatedList[bookIndex] = updatedBook;
    state = AsyncData(updatedList);

    // If all chunks are now complete → record book finished
    if (updatedChunks.every((c) => c.completed)) {
      await ref.read(userStatsProvider.notifier).recordBookFinished();
    }
  }

  // ── Library CRUD ───────────────────────────────────────────────────────────

  Future<void> addBook({
    required String userId,
    required String title,
    required String author,
    String? coverUrl,
    String? content,
  }) async {
    final book = Book(
      id: _uuid.v4(),
      title: title,
      author: author,
      totalPages: 210,
      content: content ?? '',
      uploadDate: DateTime.now(),
      coverUrl: coverUrl,
    );
    await _db.saveBook(book, userId);
    final updated = await _loadBooks(userId);
    state = AsyncData(updated);
  }

  Future<void> removeBook(String bookId) async {
    await _db.deleteBook(bookId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((b) => b.id != bookId).toList());
  }

  Future<void> refresh() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadBooks(user.id));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double progressFor(Book book) {
    if (book.chunks.isEmpty) return 0.0;
    return book.chunks.where((c) => c.completed).length /
        book.chunks.length;
  }

  BookChunk? currentChunkFor(Book book) {
    if (book.chunks.isEmpty) return null;
    return book.chunks.firstWhere(
      (c) => !c.completed,
      orElse: () => book.chunks.last,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final booksProvider =
    AsyncNotifierProvider<BooksNotifier, List<Book>>(() => BooksNotifier());

final userBooksProvider = Provider<List<Book>>(
    (ref) => ref.watch(booksProvider).valueOrNull ?? []);
