import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../reading/reading_session_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const _kPurple = Color(0xFF6B21A8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: booksAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (books) {
          if (books.isEmpty) {
            return _EmptyLibrary(
              onAdd: () => _showAddSheet(context, ref),
            );
          }
          return CustomScrollView(
            slivers: [
              _buildHeader(context, ref),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final book = books[i];
                      final notifier = ref.read(booksProvider.notifier);
                      return _BookCard(
                        book: book,
                        progress: notifier.progressFor(book),
                        onTap: () =>
                            _openBook(context, ref, book),
                        onDelete: () =>
                            _confirmDelete(context, ref, book),
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: booksAsync.hasValue && booksAsync.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref),
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
    );
  }

  // ── Header sliver ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Library',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Consumer(builder: (_, ref, __) {
              final count =
                  ref.watch(booksProvider).valueOrNull?.length ?? 0;
              return Text('$count book${count == 1 ? '' : 's'}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13));
            }),
          ],
        ),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _openBook(
      BuildContext context, WidgetRef ref, Book book) async {
    if (book.chunks.isEmpty) {
      await _generateAndOpen(context, ref, book);
    } else {
      _navigateToReading(context, ref, book);
    }
  }

  Future<void> _generateAndOpen(
      BuildContext context, WidgetRef ref, Book book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GeneratingDialog(bookTitle: book.title),
    );
    try {
      final ready =
          await ref.read(booksProvider.notifier).prepareForReading(book.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        _navigateToReading(context, ref, ready);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate guide: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _navigateToReading(
      BuildContext context, WidgetRef ref, Book book) {
    final chunk =
        ProviderScope.containerOf(context)
            .read(booksProvider.notifier)
            .currentChunkFor(book);
    if (chunk == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ReadingSessionScreen(chunk: chunk, book: book)),
    );
  }

  // ── Add book sheet ─────────────────────────────────────────────────────────

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBookSheet(
        onAddByTitle: (title, author) async {
          final user = ref.read(authProvider).user;
          if (user != null) {
            await ref.read(booksProvider.notifier).addBook(
                  userId: user.id,
                  title: title,
                  author: author,
                );
          }
        },
        onAddWithText: (title, author, content) async {
          final user = ref.read(authProvider).user;
          if (user != null) {
            await ref.read(booksProvider.notifier).addBook(
                  userId: user.id,
                  title: title,
                  author: author,
                  content: content,
                );
          }
        },
      ),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Book?'),
        content: Text('Remove "${book.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(booksProvider.notifier).removeBook(book.id);
    }
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  static const _colors = [
    Color(0xFF6B21A8),
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFF0369A1),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[book.title.length % _colors.length];
    final completed = book.chunks.where((c) => c.completed).length;
    final total = book.chunks.isEmpty ? 7 : book.chunks.length;
    final hasContent = book.content.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          book.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Badges
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (book.chunks.isEmpty)
                            _badge('AI', color),
                          if (hasContent)
                            _badge('TXT', Colors.teal),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
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
                          fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.chunks.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text(
                        'Day $completed of $total',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                      ),
                    ] else
                      Text(
                        'Tap to generate guide',
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontStyle: FontStyle.italic),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.play_circle_filled_rounded,
                          color: color, size: 24),
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

  Widget _badge(String label, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: color)),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLibrary({required this.onAdd});

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.library_books_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Your Library is Empty',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B))),
            const SizedBox(height: 12),
            Text(
              'Add a book by title and let Claude create a 7-day reading guide — or paste your own text.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Book Bottom Sheet ────────────────────────────────────────────────────

class _AddBookSheet extends StatefulWidget {
  final Future<void> Function(String title, String author) onAddByTitle;
  final Future<void> Function(String title, String author, String content)
      onAddWithText;

  const _AddBookSheet({
    required this.onAddByTitle,
    required this.onAddWithText,
  });

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _isLoading = false;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ── File picker ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      final content = await File(file.path!).readAsString();
      setState(() {
        _textCtrl.text = content;
        _fileName = file.name;
        // Auto-fill title from filename
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text = file.name
              .replaceAll('.txt', '')
              .replaceAll('_', ' ')
              .replaceAll('-', ' ');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    if (title.isEmpty || author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title and author are required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final text = _textCtrl.text.trim();
      if (text.isNotEmpty) {
        await widget.onAddWithText(title, author, text);
      } else {
        await widget.onAddByTitle(title, author);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Add a Book',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B))),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '✨ By Title'),
                  Tab(text: '📄 Add Text'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _byTitleTab(controller),
                  _withTextTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _byTitleTab(ScrollController scroll) {
    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(_titleCtrl, 'Book Title *', 'e.g. The Great Gatsby',
              Icons.menu_book_rounded),
          const SizedBox(height: 14),
          _field(_authorCtrl, 'Author *', 'e.g. F. Scott Fitzgerald',
              Icons.person_outline_rounded),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Claude will generate a personalised 7-day reading guide when you open the book.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _withTextTab(ScrollController scroll) {
    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(_titleCtrl, 'Book Title *', 'e.g. Pride and Prejudice',
              Icons.menu_book_rounded),
          const SizedBox(height: 14),
          _field(_authorCtrl, 'Author *', 'e.g. Jane Austen',
              Icons.person_outline_rounded),
          const SizedBox(height: 20),
          // Import file button
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_fileName ?? 'Import .txt file'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B21A8),
              side: const BorderSide(color: Color(0xFF6B21A8)),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Or paste text below:',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textCtrl,
            maxLines: 10,
            style: const TextStyle(fontSize: 13, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Paste book content here…',
              hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8F7FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF6B21A8), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The text will be split into 7 reading sessions. No AI call needed.',
            style:
                TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(fontSize: 15),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6B21A8), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6B21A8), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B21A8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Text('Add to Library',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Building Your Reading Guide',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Claude is crafting a personalised 7-day guide for "$bookTitle"…',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              backgroundColor: Colors.purple[100],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6B21A8)),
            ),
            const SizedBox(height: 8),
            Text('Takes ~15 seconds',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
