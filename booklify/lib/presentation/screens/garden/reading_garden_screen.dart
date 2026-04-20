import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/book.dart';
import '../../../widgets/garden/tree_painter.dart';
import '../../providers/garden_provider.dart';
import '../reading/reading_session_screen.dart';

class ReadingGardenScreen extends ConsumerStatefulWidget {
  const ReadingGardenScreen({super.key});

  @override
  ConsumerState<ReadingGardenScreen> createState() =>
      _ReadingGardenScreenState();
}

class _ReadingGardenScreenState extends ConsumerState<ReadingGardenScreen>
    with TickerProviderStateMixin {
  late AnimationController _treeController;
  late AnimationController _weatherController;

  @override
  void initState() {
    super.initState();
    _treeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _weatherController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _treeController.forward();
  }

  @override
  void dispose() {
    _treeController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressProvider);
    final weather = ref.watch(gardenWeatherProvider);
    final book = ref.watch(currentBookProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getWeatherColors(weather),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, progressAsync),
              Expanded(
                child: progressAsync.when(
                  data: (progress) {
                    if (progress == null) {
                      return _buildNoBookState(context);
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildGardenView(context, progress),
                          _buildStatsRow(context, progress),
                          _buildBookPreview(context, book, progress),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, __) =>
                      Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBookState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 80, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 24),
            Text(
              'Your garden is waiting',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add a book from your Library to start growing your reading garden.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AsyncValue<Progress?> progressAsync) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Reading Garden',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nurture your mind, grow your garden',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          progressAsync.when(
            data: (progress) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${progress?.streakDays ?? 0} days',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenView(BuildContext context, Progress progress) {
    final growthStage = progress.totalDays > 0
        ? progress.currentDay / progress.totalDays
        : 0.0;

    return GestureDetector(
      onTap: () => _showGardenDetails(context, progress),
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomPaint(
          painter: TreePainter(
            growthStage: growthStage.clamp(0.0, 1.0),
            completedDays: progress.completedDays.length,
            level: progress.level,
            animation: _treeController,
            weather: _getWeatherFromProgress(progress),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Progress progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.stars,
              label: 'Level',
              value: '${progress.level}',
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.bolt,
              label: 'XP',
              value: '${progress.xp}',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.menu_book,
              label: 'Progress',
              value: '${progress.currentDay}/${progress.totalDays}',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBookPreview(
      BuildContext context, Book? book, Progress progress) {
    BookChunk? currentChunk;
    if (book != null &&
        book.chunks.isNotEmpty &&
        progress.currentDay > 0 &&
        progress.currentDay <= book.chunks.length) {
      currentChunk = book.chunks[progress.currentDay - 1];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Episode",
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (currentChunk != null) ...[
            Text(
              currentChunk.episodeTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentChunk.keyIdea,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else
            const Text(
              'No active episode — pick a book in your Library',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: currentChunk != null && book != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadingSessionScreen(
                          chunk: currentChunk!,
                          book: book,
                        ),
                      ),
                    )
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              disabledBackgroundColor: Colors.green.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getWeatherColors(GardenWeather weather) {
    switch (weather) {
      case GardenWeather.sunny:
        return [const Color(0xFF87CEEB), const Color(0xFFE0F7FA)];
      case GardenWeather.cloudy:
        return [const Color(0xFFB0BEC5), const Color(0xFFCFD8DC)];
      case GardenWeather.stormy:
        return [const Color(0xFF546E7A), const Color(0xFF78909C)];
    }
  }

  GardenWeather _getWeatherFromProgress(Progress progress) {
    if (progress.completedDays.isEmpty) return GardenWeather.cloudy;
    final lastReadDate = DateTime.tryParse(progress.completedDays.last);
    if (lastReadDate == null) return GardenWeather.cloudy;
    final daysSince = DateTime.now().difference(lastReadDate).inDays;
    if (daysSince == 0) return GardenWeather.sunny;
    if (daysSince == 1) return GardenWeather.cloudy;
    return GardenWeather.stormy;
  }

  void _showGardenDetails(BuildContext context, Progress progress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GardenDetailsSheet(progress: progress),
    );
  }
}

// ─── Garden Details Bottom Sheet ─────────────────────────────────────────────

class _GardenDetailsSheet extends StatelessWidget {
  final Progress progress;
  const _GardenDetailsSheet({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garden Stats',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _statRow(context, 'Reading Streak',
                    '${progress.streakDays} days'),
                _statRow(context, 'Days Completed',
                    '${progress.completedDays.length}'),
                _statRow(context, 'Current Level', '${progress.level}'),
                _statRow(context, 'Total XP', '${progress.xp}'),
                _statRow(
                    context,
                    'Progress',
                    '${(progress.progressPercent * 100).toInt()}%'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
