import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../garden/reading_garden_screen.dart';
import '../library/library_screen.dart';
import '../gamification/achievements_screen.dart';
import '../reading/reading_session_screen.dart';

// ─── Brand gradient colours ───────────────────────────────────────────────────
const _kGrad1 = Color(0xFF6B21A8);
const _kGrad2 = Color(0xFF4F46E5);
const _kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kGrad1, _kGrad2],
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          LibraryScreen(),
          ReadingGardenScreen(),
          AchievementsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.library_books_rounded, label: 'Library', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.park_rounded, label: 'Garden', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.emoji_events_rounded, label: 'Rewards', index: 3, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? _kGrad : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey[400], size: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab();

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  String? _generatingBookId;

  Future<void> _openBook(String bookId) async {
    final notifier = ref.read(booksProvider.notifier);
    final books = ref.read(userBooksProvider);
    final book = books.firstWhere((b) => b.id == bookId);

    if (book.chunks.isEmpty) {
      setState(() => _generatingBookId = bookId);
      try {
        final readyBook = await notifier.prepareForReading(bookId);
        setState(() => _generatingBookId = null);
        if (mounted) _navigateToReading(readyBook);
      } catch (e) {
        setState(() => _generatingBookId = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not generate reading plan: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      _navigateToReading(book);
    }
  }

  void _navigateToReading(book) {
    final chunk = ref.read(booksProvider.notifier).currentChunkFor(book);
    if (chunk == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ReadingSessionScreen(chunk: chunk, book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final books = ref.watch(userBooksProvider);
    final firstName = (user?.displayName ?? 'Reader').split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _kGrad,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()}, 👋',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => ref.read(authProvider.notifier).signOut(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      _HeroStat(
                          icon: Icons.local_fire_department_rounded,
                          value: '5',
                          label: 'Day Streak',
                          iconColor: const Color(0xFFFF9500)),
                      const SizedBox(width: 12),
                      _HeroStat(
                          icon: Icons.menu_book_rounded,
                          value: '${books.length}',
                          label: 'Books',
                          iconColor: const Color(0xFF34D399)),
                      const SizedBox(width: 12),
                      _HeroStat(
                          icon: Icons.stars_rounded,
                          value: '2.5K',
                          label: 'Total XP',
                          iconColor: const Color(0xFFFBBF24)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Daily challenge card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DailyChallengeCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Continue reading section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Continue Reading',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  if (books.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        final homeState =
                            context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.setState(() => homeState._currentIndex = 1);
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(color: _kGrad1, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          if (books.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyReadingCard(
                  onTap: () {
                    final homeState =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.setState(() => homeState._currentIndex = 1);
                  },
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= books.take(3).length) return null;
                  final book = books.toList()[index];
                  final notifier = ref.read(booksProvider.notifier);
                  final progress = notifier.progressFor(book);
                  final completedDays =
                      book.chunks.where((c) => c.completed).length;
                  final totalDays =
                      book.chunks.isEmpty ? 7 : book.chunks.length;
                  final isGenerating = _generatingBookId == book.id;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _BookCard(
                      title: book.title,
                      author: book.author,
                      progress: progress,
                      completedDays: completedDays,
                      totalDays: totalDays,
                      hasChunks: book.chunks.isNotEmpty,
                      isGenerating: isGenerating,
                      onTap: isGenerating ? null : () => _openBook(book.id),
                    ),
                  );
                },
                childCount: books.take(3).length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

// ─── Hero stat chip ───────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _HeroStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily challenge card ─────────────────────────────────────────────────────

class _DailyChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.today_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Daily Challenge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+50 XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Read for 15 minutes today',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.4,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('6 / 15 minutes',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Text('40%',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Book card ────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final String title;
  final String author;
  final double progress;
  final int completedDays;
  final int totalDays;
  final bool hasChunks;
  final bool isGenerating;
  final VoidCallback? onTap;

  const _BookCard({
    required this.title,
    required this.author,
    required this.progress,
    required this.completedDays,
    required this.totalDays,
    this.hasChunks = true,
    this.isGenerating = false,
    this.onTap,
  });

  // Deterministic color per book title
  Color _accentColor() {
    const colors = [
      Color(0xFF6B21A8),
      Color(0xFF4F46E5),
      Color(0xFF0284C7),
      Color(0xFF059669),
      Color(0xFFD97706),
    ];
    return colors[title.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Book cover accent
            Container(
              width: 54,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  title.isNotEmpty ? title[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E1B4B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (hasChunks) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Day $completedDays of $totalDays · ${(progress * 100).round()}%',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ] else
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to generate reading guide',
                          style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action icon
            if (isGenerating)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: accent),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasChunks
                      ? Icons.play_arrow_rounded
                      : Icons.auto_awesome,
                  color: accent,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty reading state ──────────────────────────────────────────────────────

class _EmptyReadingCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyReadingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kGrad1.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kGrad1.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: _kGrad1, size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'Add Your First Book',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Claude will build a personalized reading guide for any book you choose.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: _kGrad,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Go to Library →',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
