import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../reading/reading_session_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Book',
            onPressed: () => _showAddBookDialog(context, ref),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (books) {
          if (books.isEmpty) {
            return _EmptyLibrary(onAddBook: () => _showAddBookDialog(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(booksProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final notifier = ref.read(booksProvider.notifier);
                return _BookGridCard(
                  book: book,
                  progress: notifier.progressFor(book),
                  onTap: () => _openBook(context, ref, book),
                  onDelete: () => _confirmDelete(context, ref, book),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookDialog(context, ref),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }

  Future<void> _openBook(BuildContext context, WidgetRef ref, Book book) async {
    // Show loading overlay while generating reading plan if needed
    if (book.chunks.isEmpty) {
      await _generateAndNavigate(context, ref, book);
    } else {
      _navigateToReading(context, book);
    }
  }

  Future<void> _generateAndNavigate(
      BuildContext context, WidgetRef ref, Book book) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GeneratingDialog(bookTitle: book.title),
    );

    try {
      final readyBook = await ref.read(booksProvider.notifier).prepareForReading(book.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // close dialog
        _navigateToReading(context, readyBook);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate reading plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToReading(BuildContext context, Book book) {
    final notifier = ProviderScope.containerOf(context).read(booksProvider.notifier);
    final chunk = notifier.currentChunkFor(book);
    if (chunk == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSessionScreen(chunk: chunk, book: book),
      ),
    );
  }

  Future<void> _showAddBookDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Book to Library'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                hintText: 'e.g. The Great Gatsby',
                prefixIcon: Icon(Icons.menu_book),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'e.g. F. Scott Fitzgerald',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.deepPurple[400], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Claude will generate a 7-day reading guide when you open the book.',
                      style: TextStyle(fontSize: 12, color: Colors.deepPurple[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        titleController.text.trim().isNotEmpty &&
        authorController.text.trim().isNotEmpty) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(booksProvider.notifier).addBook(
              userId: user.id,
              title: titleController.text.trim(),
              author: authorController.text.trim(),
            );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Book?'),
        content: Text('Remove "${book.title}" from your library? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(booksProvider.notifier).removeBook(book.id);
    }
  }
}

// ─── Book Grid Card ───────────────────────────────────────────────────────────

class _BookGridCard extends StatelessWidget {
  final Book book;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookGridCard({
    required this.book,
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasChunks = book.chunks.isNotEmpty;
    final completedDays = book.chunks.where((c) => c.completed).length;
    final totalDays = book.chunks.isEmpty ? 7 : book.chunks.length;

    // Pick a color based on title hash
    final colors = [
      Colors.deepPurple[400]!,
      Colors.blue[600]!,
      Colors.teal[600]!,
      Colors.indigo[500]!,
      Colors.purple[500]!,
    ];
    final cardColor = colors[book.title.length % colors.length];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!hasChunks)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 10, color: cardColor),
                              const SizedBox(width: 2),
                              Text('AI',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: cardColor)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasChunks) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Day $completedDays of $totalDays',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to generate guide',
                        style: TextStyle(
                          fontSize: 10,
                          color: cardColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow, color: cardColor, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onAddBook;

  const _EmptyLibrary({required this.onAddBook});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.library_books,
                  size: 64, color: Colors.deepPurple[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Library is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add a book and Claude will create a personalized 7-day reading guide for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddBook,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Generating Dialog ────────────────────────────────────────────────────────

class _GeneratingDialog extends StatelessWidget {
  final String bookTitle;

  const _GeneratingDialog({required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome,
                  size: 40, color: Colors.deepPurple[600]),
            ),
            const SizedBox(height: 20),
            Text(
              'Building Your Reading Guide',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Claude is creating a personalized 7-day guide for "$bookTitle"…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              backgroundColor: Colors.deepPurple[100],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.deepPurple[600]!),
            ),
            const SizedBox(height: 8),
            Text(
              'This takes about 15-20 seconds',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
