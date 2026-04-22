import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../providers/garden_provider.dart';
import '../reading/reading_session_screen.dart';
import 'add_book_sheet.dart';
import 'catalog_screen.dart';

class BooksScreen extends ConsumerWidget {
  final String? recommendedTopic;

  const BooksScreen({super.key, this.recommendedTopic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, ref),
            booksAsync.when(
              data: (books) => books.isEmpty
                  ? _buildEmptySliver(context, ref)
                  : _buildBooksList(context, ref, books),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
            ),
            _buildDiscoverSection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBook(context),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFFF8F7FF),
      elevation: 0,
      title: const Text(
        'My Books',
        style: TextStyle(
          color: Color(0xFF1E1B4B),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.explore_rounded, color: Color(0xFF6B21A8)),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CatalogScreen(recommendedTopic: recommendedTopic))),
          tooltip: 'Discover Books',
        ),
      ],
    );
  }

  SliverList _buildBooksList(BuildContext context, WidgetRef ref, List<Book> books) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _BookCard(book: books[i]),
        childCount: books.length,
      ),
    );
  }

  SliverFillRemaining _buildEmptySliver(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B21A8).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded,
                    size: 48, color: Color(0xFF6B21A8)),
              ),
              const SizedBox(height: 24),
              const Text(
                'No books yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 10),
              Text(
                'Upload a PDF or TXT file to start your reading journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _showAddBook(context),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B21A8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDiscoverSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Discover Books',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CatalogScreen(recommendedTopic: recommendedTopic)),
              ),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Browse 30 Must-Read Books'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: const Color(0xFF6B21A8),
                side: const BorderSide(color: Color(0xFF6B21A8)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const AddBookSheet(),
      ),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends ConsumerWidget {
  final Book book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = book.chunks.where((c) => c.completed).length;
    final total = book.chunks.length;
    final progress = total > 0 ? completed / total : 0.0;

    // Today's chunk = first incomplete
    final todayChunk = book.chunks.isEmpty
        ? null
        : book.chunks.firstWhere((c) => !c.completed,
            orElse: () => book.chunks.last);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with book info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover placeholder
                Container(
                  width: 56,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E1B4B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      // Progress text
                      Text(
                        total > 0
                            ? 'Day $completed of $total · ${(progress * 100).round()}% done'
                            : 'No plan yet',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B21A8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          if (total > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B21A8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Today's section info
          if (todayChunk != null && !book.chunks.every((c) => c.completed)) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded,
                      color: Color(0xFF6B21A8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${todayChunk.dayNumber}: ${todayChunk.episodeTitle}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF4C1D95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '~${todayChunk.estimatedMinutes} min read',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (todayChunk != null &&
                    !book.chunks.every((c) => c.completed))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openReading(context, todayChunk),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Read Today'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B21A8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Completed!',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showAllDays(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B21A8),
                    side: const BorderSide(color: Color(0xFF6B21A8)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: const Text('All Days'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReading(BuildContext context, BookChunk chunk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSessionScreen(chunk: chunk, book: book),
      ),
    );
  }

  void _showAllDays(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllDaysSheet(book: book),
    );
  }
}

// ─── All Days Sheet ───────────────────────────────────────────────────────────

class _AllDaysSheet extends StatelessWidget {
  final Book book;

  const _AllDaysSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E1B4B)),
                    ),
                  ),
                  Text(
                    '${book.chunks.length} days',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: book.chunks.length,
                itemBuilder: (_, i) {
                  final chunk = book.chunks[i];
                  final isNext = !chunk.completed &&
                      (i == 0 || book.chunks[i - 1].completed);
                  return _DayTile(
                    chunk: chunk,
                    book: book,
                    isNext: isNext,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final BookChunk chunk;
  final Book book;
  final bool isNext;

  const _DayTile({
    required this.chunk,
    required this.book,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !chunk.completed && !isNext;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: chunk.completed
            ? const Color(0xFFF0FDF4)
            : isNext
                ? const Color(0xFFF5F3FF)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isNext
            ? Border.all(color: const Color(0xFF6B21A8), width: 1.5)
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: chunk.completed
                ? const Color(0xFF059669)
                : isNext
                    ? const Color(0xFF6B21A8)
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            chunk.completed
                ? Icons.check_rounded
                : isNext
                    ? Icons.play_arrow_rounded
                    : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Day ${chunk.dayNumber}: ${chunk.episodeTitle}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isLocked ? Colors.grey[400] : const Color(0xFF1E1B4B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '~${chunk.estimatedMinutes} min',
          style: TextStyle(
              fontSize: 12,
              color: isLocked ? Colors.grey[400] : Colors.grey[600]),
        ),
        trailing: (chunk.completed || isNext)
            ? TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReadingSessionScreen(chunk: chunk, book: book),
                    ),
                  );
                },
                child: Text(
                  chunk.completed ? 'Review' : 'Read',
                  style: TextStyle(
                    color: chunk.completed
                        ? const Color(0xFF059669)
                        : const Color(0xFF6B21A8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
