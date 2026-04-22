import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/book.dart';
import '../../../data/services/chunker_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/curriculum_provider.dart';
import '../../providers/garden_provider.dart';

class AddBookSheet extends ConsumerStatefulWidget {
  final WidgetRef? ref;
  final String? prefilledTitle;
  final String? prefilledAuthor;

  const AddBookSheet({
    super.key,
    this.ref,
    this.prefilledTitle,
    this.prefilledAuthor,
  });

  @override
  ConsumerState<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<AddBookSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _daysController = TextEditingController(text: '30');
  final _contentController = TextEditingController();

  String? _fileName;
  String? _fileContent;
  bool _isLoading = false;
  bool _useFileUpload = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledTitle != null) {
      _titleController.text = widget.prefilledTitle!;
    }
    if (widget.prefilledAuthor != null) {
      _authorController.text = widget.prefilledAuthor!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _daysController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String? content;

    final isPdf = file.name.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes != null) {
        content = _extractTextFromPdf(bytes);
      }
    } else {
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
    }

    if (content != null && content.trim().isNotEmpty && mounted) {
      setState(() {
        _fileName = file.name;
        _fileContent = content;
        if (_titleController.text.isEmpty) {
          _titleController.text = file.name
              .replaceAll('.pdf', '')
              .replaceAll('.txt', '')
              .replaceAll('_', ' ');
        }
      });
    } else if (mounted) {
      _showError('Could not extract text from this file.');
    }
  }

  String _extractTextFromPdf(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    for (int i = 0; i < document.pages.count; i++) {
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (text.trim().isNotEmpty) {
        buffer.writeln(text);
      }
    }
    document.dispose();
    return buffer.toString();
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
          ? 'Please select a PDF or TXT file.'
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
      ref.read(currentBookProvider.notifier).setBook(book);
      ref.invalidate(progressProvider);

      // Generate curriculum from this book so reading + learning are unified
      // Fire-and-forget — don't block the UI on this
      ref.read(curriculumProvider.notifier).generateFromBook(book).ignore();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '"$title" added! ${chunks.length} days · your Learn tab is synced 🎓'),
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
                  _modeChip('Upload File', true),
                  const SizedBox(width: 8),
                  _modeChip('Paste Text', false),
                ],
              ),
              const SizedBox(height: 16),

              if (_useFileUpload) ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_fileName ?? 'Choose PDF or TXT file'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppColors.primary),
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
                      style: const TextStyle(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey[100],
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
