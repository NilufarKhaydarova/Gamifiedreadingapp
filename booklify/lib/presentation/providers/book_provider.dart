import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book.dart';
import '../../data/services/database_service.dart';
import '../../data/services/claude_service.dart';
import 'auth_provider.dart';

// ─── Service Providers ────────────────────────────────────────────────────────
// Note: databaseServiceProvider is defined in auth_provider.dart

final _claudeServiceProvider = Provider<ClaudeService>((ref) {
  return ClaudeService();
});

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
    final rows = await _db.getBooks(userId);
    return rows.map(_rowToBook).toList();
  }

  Book _rowToBook(Map<String, dynamic> row) {
    List<BookChunk> chunks = [];
    final chunksJson = row['chunks_json'] as String?;
    if (chunksJson != null && chunksJson.isNotEmpty) {
      try {
        final list = json.decode(chunksJson) as List;
        chunks = list.map((c) => BookChunk.fromJson(c as Map<String, dynamic>)).toList();
      } catch (e) {
        chunks = [];
      }
    }

    return Book(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String,
      totalPages: (row['total_days'] as int? ?? 7) * 30,
      content: row['content'] as String? ?? '',
      uploadDate: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      coverUrl: row['cover_url'] as String?,
      chunks: chunks,
    );
  }

  /// Open a book for reading. If it has no chunks, Claude generates a reading plan.
  /// Returns the book with chunks populated.
  Future<Book> prepareForReading(String bookId) async {
    final current = state.valueOrNull ?? [];
    final book = current.firstWhere((b) => b.id == bookId);

    if (book.chunks.isNotEmpty) return book;

    // Generate reading plan with Claude
    final chunks = await _claude.generateReadingPlan(
      title: book.title,
      author: book.author,
      totalDays: 7,
    );

    // Persist to DB
    final chunksJson = json.encode(chunks.map((c) => c.toJson()).toList());
    await _db.updateBookChunks(bookId, chunksJson);

    // Update state
    final updatedBook = book.copyWith(chunks: chunks);
    final updatedList = current.map((b) => b.id == bookId ? updatedBook : b).toList();
    state = AsyncData(updatedList);

    return updatedBook;
  }

  /// Add a new book to the library (no content — Claude generates on first open).
  Future<void> addBook({
    required String userId,
    required String title,
    required String author,
    String? coverUrl,
  }) async {
    final id = _uuid.v4();
    await _db.saveBook(
      id: id,
      userId: userId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      totalDays: 7,
    );

    // Refresh list
    final updated = await _loadBooks(userId);
    state = AsyncData(updated);
  }

  /// Remove a book from the library.
  Future<void> removeBook(String bookId) async {
    await _db.deleteBook(bookId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((b) => b.id != bookId).toList());
  }

  /// Refresh books from DB.
  Future<void> refresh() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadBooks(user.id));
  }

  /// Get progress for a book (0.0 – 1.0).
  double progressFor(Book book) {
    if (book.chunks.isEmpty) return 0.0;
    final completed = book.chunks.where((c) => c.completed).length;
    return completed / book.chunks.length;
  }

  /// Get the next unread chunk for a book, or the last one.
  BookChunk? currentChunkFor(Book book) {
    if (book.chunks.isEmpty) return null;
    return book.chunks.firstWhere(
      (c) => !c.completed,
      orElse: () => book.chunks.last,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(() {
  return BooksNotifier();
});

/// Convenience: books for current user with progress
final userBooksProvider = Provider<List<Book>>((ref) {
  return ref.watch(booksProvider).valueOrNull ?? [];
});
