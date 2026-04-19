import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../garden/reading_garden_screen.dart';
import '../library/library_screen.dart';
import '../gamification/achievements_screen.dart';
import '../reading/reading_session_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Public so child tabs can switch tabs
  // ignore: avoid_setstate_in_build
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const LibraryScreen(),
    const ReadingGardenScreen(),
    const AchievementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.park),
            label: 'Garden',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }
}

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not generate reading plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _navigateToReading(book);
    }
  }

  void _navigateToReading(book) {
    final notifier = ref.read(booksProvider.notifier);
    final chunk = notifier.currentChunkFor(book);
    if (chunk == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSessionScreen(chunk: chunk, book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final books = ref.watch(userBooksProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.displayName ?? 'Reader',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Level',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${user != null ? (user.id.hashCode % 10) + 1 : 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      title: 'Day Streak',
                      value: '5',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.menu_book,
                      title: 'Books',
                      value: '${books.length}',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.psychology,
                      title: 'Total XP',
                      value: '2,500',
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events,
                      title: 'Achievements',
                      value: '8',
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Continue Reading Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Continue Reading',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (books.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        // Switch to Library tab handled via parent
                      },
                      child: const Text('See All'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (books.isEmpty)
                _EmptyReadingState(
                  onAddBook: () {
                    // Navigate to library tab
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.setState(() => homeState._currentIndex = 1);
                  },
                )
              else
                ...books.take(3).map((book) {
                  final notifier = ref.read(booksProvider.notifier);
                  final progress = notifier.progressFor(book);
                  final completedDays = book.chunks.where((c) => c.completed).length;
                  final totalDays = book.chunks.isEmpty ? 7 : book.chunks.length;
                  final isGenerating = _generatingBookId == book.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookCard(
                      title: book.title,
                      author: book.author,
                      progress: progress,
                      currentDay: completedDays,
                      totalDays: totalDays,
                      hasChunks: book.chunks.isNotEmpty,
                      isGenerating: isGenerating,
                      onTap: isGenerating ? null : () => _openBook(book.id),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Daily Challenge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.today,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Read for 15 minutes today',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '6 / 15 minutes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title;
  final String author;
  final double progress;
  final int currentDay;
  final int totalDays;
  final bool hasChunks;
  final bool isGenerating;
  final VoidCallback? onTap;

  const _BookCard({
    required this.title,
    required this.author,
    required this.progress,
    required this.currentDay,
    required this.totalDays,
    this.hasChunks = true,
    this.isGenerating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.menu_book, color: Colors.deepPurple.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasChunks) ...[
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day $currentDay of $totalDays',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 12, color: Colors.deepPurple[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to generate reading guide',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple[400],
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isGenerating)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                hasChunks ? Icons.play_circle_outline : Icons.auto_awesome,
                size: 32,
                color: Colors.deepPurple,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReadingState extends StatelessWidget {
  final VoidCallback onAddBook;

  const _EmptyReadingState({required this.onAddBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.library_books, size: 48, color: Colors.deepPurple[300]),
          const SizedBox(height: 12),
          const Text(
            'No books yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a book and Claude will create a personalized reading guide.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddBook,
            icon: const Icon(Icons.add),
            label: const Text('Go to Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
