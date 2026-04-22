import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/catalog_book.dart';
import '../../../data/services/catalog_service.dart';
import 'add_book_sheet.dart';

const _kPrimary = Color(0xFF6B21A8);
const _kSecondary = Color(0xFF4F46E5);
const _kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kPrimary, _kSecondary],
);

class CatalogScreen extends ConsumerStatefulWidget {
  final String? recommendedTopic;
  const CatalogScreen({super.key, this.recommendedTopic});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _selectedGenre = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  String? get _topicGenre {
    final t = widget.recommendedTopic?.toLowerCase() ?? '';
    if (t.contains('philosoph')) return 'Philosophy';
    if (t.contains('psycholog')) return 'Psychology';
    if (t.contains('fiction') || t.contains('classic') || t.contains('literature') || t.contains('novel')) return 'Fiction';
    if (t.contains('science') || t.contains('biology') || t.contains('physics')) return 'Science';
    if (t.contains('histor')) return 'History';
    if (t.contains('econom') || t.contains('financ')) return 'Economics';
    return null;
  }

  List<CatalogBook> get _recommendedBooks {
    final genre = _topicGenre;
    if (genre == null || _searchQuery.isNotEmpty) return [];
    return CatalogService.byGenre(genre);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogBook> get _filteredBooks {
    List<CatalogBook> books;
    if (_searchQuery.isNotEmpty) {
      books = CatalogService.search(_searchQuery);
    } else if (_selectedGenre == 'All') {
      books = CatalogService.allBooks;
    } else {
      books = CatalogService.byGenre(_selectedGenre);
    }
    return books;
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Accessible':
        return const Color(0xFF059669);
      case 'Moderate':
        return const Color(0xFF2563EB);
      case 'Challenging':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey;
    }
  }

  void _showBookDetail(CatalogBook book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookDetailSheet(
        book: book,
        onUploadAndRead: () {
          Navigator.pop(context); // close detail sheet
          _showAddBookSheet(book);
        },
      ),
    );
  }

  void _showAddBookSheet(CatalogBook book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBookSheet(
        prefilledTitle: book.title,
        prefilledAuthor: book.author,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = ['All', ...CatalogService.genres];
    final books = _filteredBooks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _kGrad,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover Books',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '100 must-read classics',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search books, authors…',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.search, color: _kPrimary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Genre chips ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final genre = genres[i];
                  final selected = _selectedGenre == genre;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGenre = genre;
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected ? _kGrad : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? _kPrimary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Book count ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${books.length} book${books.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Recommended for topic ─────────────────────────────────────────
          if (_recommendedBooks.isNotEmpty && _selectedGenre == 'All') ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: _kPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'RECOMMENDED FOR ${widget.recommendedTopic?.toUpperCase() ?? 'YOUR TOPIC'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _BookCard(
                    book: _recommendedBooks[i],
                    difficultyColor: _difficultyColor(_recommendedBooks[i].difficulty),
                    onTap: () => _showBookDetail(_recommendedBooks[i]),
                  ),
                  childCount: _recommendedBooks.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: const [
                    Icon(Icons.menu_book_rounded, size: 14, color: _kPrimary),
                    SizedBox(width: 6),
                    Text(
                      'ALL BOOKS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Grid ──────────────────────────────────────────────────────────
          books.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Text('📚',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'No books found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        return _BookCard(
                          book: book,
                          difficultyColor: _difficultyColor(book.difficulty),
                          onTap: () => _showBookDetail(book),
                        );
                      },
                      childCount: books.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final CatalogBook book;
  final Color difficultyColor;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.difficultyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji
            Center(
              child: Text(
                book.emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E1B4B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Author
            Text(
              book.author,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Year
            Text(
              book.year < 0 ? '${book.year.abs()} BCE' : '${book.year}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),

            const Spacer(),

            // Difficulty badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                book.difficulty,
                style: TextStyle(
                  color: difficultyColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Detail Bottom Sheet ─────────────────────────────────────────────────

class _BookDetailSheet extends StatelessWidget {
  final CatalogBook book;
  final VoidCallback onUploadAndRead;

  const _BookDetailSheet({
    required this.book,
    required this.onUploadAndRead,
  });

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Accessible':
        return const Color(0xFF059669);
      case 'Moderate':
        return const Color(0xFF2563EB);
      case 'Challenging':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(book.difficulty);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Big emoji
            Center(
              child: Text(book.emoji,
                  style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 16),

            // Title
            Center(
              child: Text(
                book.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),

            // Author
            Center(
              child: Text(
                book.author,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meta chips row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _MetaChip(
                  label:
                      book.year < 0 ? '${book.year.abs()} BCE' : '${book.year}',
                  icon: Icons.calendar_today_rounded,
                  color: _kSecondary,
                ),
                _MetaChip(
                  label: book.genre,
                  icon: Icons.category_rounded,
                  color: _kPrimary,
                ),
                _MetaChip(
                  label: '${book.pages} pages',
                  icon: Icons.menu_book_rounded,
                  color: Colors.teal,
                ),
                _MetaChip(
                  label: book.difficulty,
                  icon: Icons.signal_cellular_alt_rounded,
                  color: diffColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 12),

            // Description
            Text(
              book.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.65,
              ),
            ),
            const SizedBox(height: 28),

            // Upload & Read button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _kGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onUploadAndRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text(
                    'Upload & Read',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
