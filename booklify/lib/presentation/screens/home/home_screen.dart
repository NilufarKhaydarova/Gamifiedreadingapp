import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/user_stats_provider.dart';
import '../library/library_screen.dart';
import '../learning/learning_map_screen.dart';
import '../gamification/achievements_screen.dart';
import '../reading/reading_session_screen.dart';
import '../../../data/models/book.dart';

// ─── Brand colours ────────────────────────────────────────────────────────────
const _kGrad1 = Color(0xFF6B21A8);
const _kGrad2 = Color(0xFF4F46E5);
const _kGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kGrad1, _kGrad2],
);

// ─── Root Shell ───────────────────────────────────────────────────────────────

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
          LearningMapScreen(),
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
              _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.library_books_rounded,
                  label: 'Library',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Profile',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap),
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
  bool _isGenerating = false;

  // ── Navigation helpers ─────────────────────────────────────────────────────

  Future<void> _openActiveBook() async {
    final active = ref.read(booksProvider.notifier).getActiveBook();
    if (active == null) return;

    if (active.chunks.isEmpty) {
      setState(() => _isGenerating = true);
      try {
        final ready =
            await ref.read(booksProvider.notifier).prepareForReading(active.id);
        setState(() => _isGenerating = false);
        if (mounted) _navigateToReading(ready);
      } catch (e) {
        setState(() => _isGenerating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not generate reading plan: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      _navigateToReading(active);
    }
  }

  void _navigateToReading(Book book) {
    final chunk = ref.read(booksProvider.notifier).currentChunkFor(book);
    if (chunk == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ReadingSessionScreen(chunk: chunk, book: book)),
    );
  }

  void _goToLibrary() {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.setState(() => homeState._currentIndex = 1);
  }

  void _goToMap() {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.setState(() => homeState._currentIndex = 2);
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final books = ref.watch(userBooksProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final stats = statsAsync.valueOrNull;
    final firstName = (user?.displayName ?? 'Reader').split(' ').first;
    final active = ref.watch(booksProvider.notifier).getActiveBook();
    final hasBooks = books.isNotEmpty;

    // Current unread chunk for active book
    BookChunk? todaysChunk;
    if (active != null && active.chunks.isNotEmpty) {
      todaysChunk = ref.read(booksProvider.notifier).currentChunkFor(active);
    }

    // XP today / cap
    final xpToday = stats?.xpEarnedToday ?? 0;
    const xpCap = UserStatsNotifier.kDailyXPCap;
    final xpProgress = xpCap > 0
        ? (xpToday / xpCap).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: _kGrad,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
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
                            '${_greeting()}, 👋',
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
                      // Streak badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Color(0xFFFF9500), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${stats?.streakDays ?? 0} day streak',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // XP progress bar (today / cap)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$xpToday / $xpCap XP today',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      if (xpToday >= xpCap)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBF00).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Daily cap reached!',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFBF00)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Today's Episode ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY'S EPISODE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _kGrad1,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!hasBooks)
                    _OnboardingCard(onGoToLibrary: _goToLibrary)
                  else if (todaysChunk == null)
                    _AllDoneCard(onGoToLibrary: _goToLibrary)
                  else
                    _TodaysEpisodeCard(
                      book: active!,
                      chunk: todaysChunk,
                      isGenerating: _isGenerating,
                      onTap: _openActiveBook,
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Mini Garden ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MiniGardenCard(
                level: stats?.level ?? 1,
                streakDays: stats?.streakDays ?? 0,
                xpToday: xpToday,
                xpCap: xpCap,
                totalXP: stats?.xp ?? 0,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Learning Map Preview ─────────────────────────────────────────
          if (hasBooks && active != null && active.chunks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _LearningMapPreview(
                  book: active,
                  onSeeAll: _goToMap,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── Today's Episode Card ─────────────────────────────────────────────────────

class _TodaysEpisodeCard extends StatelessWidget {
  final Book book;
  final BookChunk chunk;
  final bool isGenerating;
  final VoidCallback onTap;

  const _TodaysEpisodeCard({
    required this.book,
    required this.chunk,
    required this.isGenerating,
    required this.onTap,
  });

  String get _difficultyBadge {
    switch (chunk.difficulty) {
      case Difficulty.light:
        return '🌱 Light';
      case Difficulty.moderate:
        return '📘 Moderate';
      case Difficulty.dense:
        return '🔥 Dense';
    }
  }

  Color get _difficultyColor {
    switch (chunk.difficulty) {
      case Difficulty.light:
        return const Color(0xFF059669);
      case Difficulty.moderate:
        return const Color(0xFF2563EB);
      case Difficulty.dense:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGenerating ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B21A8).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    book.title,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _difficultyBadge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Day ${chunk.dayNumber}: ${chunk.episodeTitle}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chunk.keyIdea,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  '~${chunk.estimatedMinutes} min',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const Spacer(),
                if (isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Continue',
                            style: TextStyle(
                                color: _kGrad1,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: _kGrad1, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onboarding Card (no books) ───────────────────────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final VoidCallback onGoToLibrary;
  const _OnboardingCard({required this.onGoToLibrary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGrad1.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B21A8), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),
          const Text(
            'Upload your first book to begin',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The Smart Chunking Engine will build your personalised learning path.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onGoToLibrary,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: _kGrad,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Go to Library →',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All Done Card (all chunks complete) ──────────────────────────────────────

class _AllDoneCard extends StatelessWidget {
  final VoidCallback onGoToLibrary;
  const _AllDoneCard({required this.onGoToLibrary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All caught up!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E1B4B))),
                const SizedBox(height: 4),
                Text('Add another book to keep the streak going.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onGoToLibrary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: _kGrad,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Add Book',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Garden Card ─────────────────────────────────────────────────────────

class _MiniGardenCard extends StatelessWidget {
  final int level;
  final int streakDays;
  final int xpToday;
  final int xpCap;
  final int totalXP;

  const _MiniGardenCard({
    required this.level,
    required this.streakDays,
    required this.xpToday,
    required this.xpCap,
    required this.totalXP,
  });

  String _treeEmoji() {
    if (level < 3) return '🌱';
    if (level < 6) return '🌿';
    if (level < 10) return '🌳';
    if (level < 15) return '🌲';
    return '🌴';
  }

  @override
  Widget build(BuildContext context) {
    final xpProgress = (xpToday / xpCap).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Tree + level
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_treeEmoji(), style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: _kGrad,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Level $level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFF9500), size: 16),
                    const SizedBox(width: 4),
                    Text('$streakDays day streak',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E1B4B))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s XP',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                    Text('$xpToday / $xpCap',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kGrad1)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    minHeight: 6,
                    backgroundColor: _kGrad1.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kGrad1),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Total XP: $totalXP',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Learning Map Preview ─────────────────────────────────────────────────────

class _LearningMapPreview extends StatelessWidget {
  final Book book;
  final VoidCallback onSeeAll;

  const _LearningMapPreview({required this.book, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final chunks = book.chunks;
    // Show up to 3 nodes: last completed + current + next
    final currentIndex =
        chunks.indexWhere((c) => !c.completed);
    final previewStart =
        (currentIndex <= 0 ? 0 : currentIndex - 1).clamp(0, chunks.length - 1);
    final previewChunks =
        chunks.skip(previewStart).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LEARNING MAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kGrad1,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all →',
                style: TextStyle(
                    fontSize: 12,
                    color: _kGrad1,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: previewChunks.map((chunk) {
              final isCurrent = !chunk.completed &&
                  chunks
                      .where((c) => !c.completed)
                      .firstOrNull
                      ?.id ==
                  chunk.id;
              final isCompleted = chunk.completed;
              return _MapNodePreview(
                chunk: chunk,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: chunk == previewChunks.last,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MapNodePreview extends StatelessWidget {
  final BookChunk chunk;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _MapNodePreview({
    required this.chunk,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor;
    IconData nodeIcon;
    if (isCompleted) {
      nodeColor = const Color(0xFF059669);
      nodeIcon = Icons.check_rounded;
    } else if (isCurrent) {
      nodeColor = _kGrad1;
      nodeIcon = Icons.play_arrow_rounded;
    } else {
      nodeColor = Colors.grey[300]!;
      nodeIcon = Icons.lock_outline_rounded;
    }

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? nodeColor
                    : Colors.grey[200],
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: _kGrad1, width: 2)
                    : null,
              ),
              child: Icon(nodeIcon,
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : Colors.grey[400],
                  size: 16),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${chunk.dayNumber}: ${chunk.episodeTitle}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted || isCurrent
                        ? const Color(0xFF1E1B4B)
                        : Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    chunk.keyIdea,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
