import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/book.dart';
import '../../../data/services/chunker_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garden_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final currentBook = ref.watch(currentBookProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isSelected = currentBook?.id == book.id;
              return _BookCard(
                book: book,
                isSelected: isSelected,
                onSelect: () {
                  ref.read(currentBookProvider.notifier).state = book;
                  ref.invalidate(progressProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${book.title}" is now active'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onDelete: () => _confirmDelete(context, ref, book),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error loading library: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Add a .txt book file to get started with your reading journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddBookDialog(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Add Your First Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
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

  Future<void> _showAddBookDialog(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBookSheet(ref: ref),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Delete "${book.title}"? This will also remove all reading progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
      final current = ref.read(currentBookProvider);
      if (current?.id == book.id) {
        ref.read(currentBookProvider.notifier).state = null;
      }
    }
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.menu_book,
            color: isSelected ? AppColors.primary : Colors.grey[400],
            size: 28,
          ),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.author,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${book.chunks.length} day plan',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              )
            else
              TextButton(
                onPressed: onSelect,
                child: const Text('Read'),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Book Bottom Sheet ────────────────────────────────────────────────────

class _AddBookSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddBookSheet({required this.ref});

  @override
  ConsumerState<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<_AddBookSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _daysController = TextEditingController(text: '30');
  final _contentController = TextEditingController();

  String? _fileName;
  String? _fileContent;
  bool _isLoading = false;
  bool _useFileUpload = true;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _daysController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String? content;

    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    }

    if (content != null && mounted) {
      setState(() {
        _fileName = file.name;
        _fileContent = content;
        if (_titleController.text.isEmpty) {
          _titleController.text =
              file.name.replaceAll('.txt', '').replaceAll('_', ' ');
        }
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final daysText = _daysController.text.trim();
    final content =
        _useFileUpload ? _fileContent : _contentController.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a book title.');
      return;
    }

    if (content == null || content.isEmpty) {
      _showError(_useFileUpload
          ? 'Please select a .txt file.'
          : 'Please paste or type some content.');
      return;
    }

    final days = int.tryParse(daysText) ?? 30;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider);
      if (user == null) throw Exception('Not logged in');

      // Build chunks (without AI — uses smart paragraph splitting)
      final chunker = SmartChunkerService();
      final chunks = await chunker.createReadingPlan(
        content: content,
        totalDays: days,
      );

      final book = Book(
        id: const Uuid().v4(),
        title: title,
        author: author.isEmpty ? 'Unknown' : author,
        totalPages: 0,
        content: content,
        uploadDate: DateTime.now(),
        chunks: chunks,
      );

      await ref.read(booksProvider.notifier).addBook(book);

      // Auto-select the new book
      ref.read(currentBookProvider.notifier).state = book;
      ref.invalidate(progressProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '"$title" added with ${chunks.length} daily episodes!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to add book: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add a Book',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Book Title *'),
              ),
              const SizedBox(height: 12),

              // Author
              TextField(
                controller: _authorController,
                decoration: _inputDecoration('Author (optional)'),
              ),
              const SizedBox(height: 12),

              // Days
              TextField(
                controller: _daysController,
                decoration: _inputDecoration('Reading Plan (days)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Toggle: file upload vs paste
              Row(
                children: [
                  _modeChip('Upload .txt', true),
                  const SizedBox(width: 8),
                  _modeChip('Paste Text', false),
                ],
              ),
              const SizedBox(height: 16),

              if (_useFileUpload) ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_fileName ?? 'Choose .txt file'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_fileContent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_fileContent!.length} characters loaded',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13),
                    ),
                  ),
              ] else ...[
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: _inputDecoration('Paste your book text here…'),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Book',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool value) {
    final selected = _useFileUpload == value;
    return GestureDetector(
      onTap: () => setState(() => _useFileUpload = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
